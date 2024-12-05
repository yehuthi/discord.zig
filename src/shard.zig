const ws = @import("ws");
const builtin = @import("builtin");

const std = @import("std");
const net = std.net;
const crypto = std.crypto;
const tls = std.crypto.tls;
const json = std.json;
const mem = std.mem;
const http = std.http;

// todo use this to read compressed messages
const zlib = @import("zlib");
const zjson = @import("json");

const Self = @This();

const GatewayPayload = @import("./structures/types.zig").GatewayPayload;
const Opcode = @import("./structures/types.zig").GatewayOpcodes;
const Intents = @import("./structures/types.zig").Intents;

const IdentifyProperties = @import("internal.zig").IdentifyProperties;
const GatewayInfo = @import("internal.zig").GatewayInfo;
const GatewayBotInfo = @import("internal.zig").GatewayBotInfo;
const GatewaySessionStartLimit = @import("internal.zig").GatewaySessionStartLimit;
const ShardDetails = @import("internal.zig").ShardDetails;

const Log = @import("internal.zig").Log;
const GatewayDispatchEvent = @import("internal.zig").GatewayDispatchEvent;
const Bucket = @import("internal.zig").Bucket;
const default_identify_properties = @import("internal.zig").default_identify_properties;

const Types = @import("./structures/types.zig");
const Snowflake = @import("./structures/snowflake.zig").Snowflake;

pub const ShardSocketCloseCodes = enum(u16) {
    Shutdown = 3000,
    ZombiedConnection = 3010,
};

const Heart = struct {
    /// interval to send heartbeats, further multiply it with the jitter
    heartbeatInterval: u64,
    /// useful for calculating ping and resuming
    lastBeat: i64,
};

const RatelimitOptions = struct {
    max_requests_per_ratelimit_tick: ?usize = 120,
    ratelimit_reset_interval: u64 = 60000,
};

pub const ShardOptions = struct {
    info: GatewayBotInfo,
    ratelimit_options: RatelimitOptions = .{},
};

id: usize,

client: ws.Client,
details: ShardDetails,

//heart: Heart =
allocator: mem.Allocator,
resume_gateway_url: ?[]const u8 = null,
bucket: Bucket,
options: ShardOptions,

session_id: ?[]const u8,
sequence: std.atomic.Value(isize) = .init(0),
heart: Heart = .{ .heartbeatInterval = 45000, .lastBeat = 0 },

///
handler: GatewayDispatchEvent(*Self),
packets: std.ArrayList(u8),
inflator: zlib.Decompressor,

///useful for closing the conn
ws_mutex: std.Thread.Mutex = .{},
rw_mutex: std.Thread.RwLock = .{},
log: Log = .no,

pub const JsonResolutionError = std.fmt.ParseIntError || std.fmt.ParseFloatError || json.ParseFromValueError || json.ParseError(json.Scanner);

pub fn resumable(self: *Self) bool {
    return self.resume_gateway_url != null and
        self.session_id != null and
        self.sequence.load(.monotonic) > 0;
}

pub fn resume_(self: *Self) SendError!void {
    const data = .{ .op = @intFromEnum(Opcode.Resume), .d = .{
        .token = self.details.token,
        .session_id = self.session_id,
        .seq = self.sequence.load(.monotonic),
    } };

    try self.send(false, data);
}

inline fn gatewayUrl(self: ?*Self) []const u8 {
    return if (self) |s| (s.resume_gateway_url orelse s.options.info.url)["wss://".len..] else "gateway.discord.gg";
}

/// identifies in order to connect to Discord and get the online status, this shall be done on hello perhaps
pub fn identify(self: *Self, properties: ?IdentifyProperties) SendError!void {
    if (self.details.intents.toRaw() != 0) {
        const data = .{
            .op = @intFromEnum(Opcode.Identify),
            .d = .{
                .intents = self.details.intents.toRaw(),
                .properties = properties orelse default_identify_properties,
                .token = self.details.token,
            },
        };
        try self.send(false, data);
    } else {
        const data = .{
            .op = @intFromEnum(Opcode.Identify),
            .d = .{
                .capabilities = 30717,
                .properties = properties orelse default_identify_properties,
                .token = self.details.token,
            },
        };
        try self.send(false, data);
    }
}

pub fn init(allocator: mem.Allocator, shard_id: usize, settings: struct {
    token: []const u8,
    intents: Intents,
    options: ShardOptions,
    run: GatewayDispatchEvent(*Self),
    log: Log,
}) zlib.Error!Self {
    return Self{
        .options = ShardOptions{
            .info = GatewayBotInfo{
                .url = settings.options.info.url,
                .shards = settings.options.info.shards,
                .session_start_limit = settings.options.info.session_start_limit,
            },
            .ratelimit_options = settings.options.ratelimit_options,
        },
        .id = shard_id,
        .allocator = allocator,
        .details = ShardDetails{
            .token = settings.token,
            .intents = settings.intents,
        },
        .client = undefined,
        // maybe there is a better way to do this
        .session_id = undefined,
        .handler = settings.run,
        .log = settings.log,
        .packets = std.ArrayList(u8).init(allocator),
        .inflator = try zlib.Decompressor.init(allocator, .{ .header = .zlib_or_gzip }),
        .bucket = Bucket.init(
            allocator,
            Self.calculateSafeRequests(settings.options.ratelimit_options),
            settings.options.ratelimit_options.ratelimit_reset_interval,
            Self.calculateSafeRequests(settings.options.ratelimit_options),
        ),
    };
}

inline fn calculateSafeRequests(options: RatelimitOptions) usize {
    const safe_requests =
        @as(f64, @floatFromInt(options.max_requests_per_ratelimit_tick orelse 120)) -
        @ceil(@as(f64, @floatFromInt(options.ratelimit_reset_interval)) / 30000.0) * 2;

    if (safe_requests < 0) {
        return 0;
    }

    return @intFromFloat(safe_requests);
}

inline fn _connect_ws(allocator: mem.Allocator, url: []const u8) !ws.Client {
    var conn = try ws.Client.init(allocator, .{
        .tls = true, // important: zig.http doesn't support this, type shit
        .port = 443,
        .host = url,
    });

    // maybe change this to a buffer
    var buf: [0x100]u8 = undefined;
    const host = try std.fmt.bufPrint(&buf, "host: {s}", .{url});

    conn.handshake("/?v=10&encoding=json&compress=zlib-stream", .{
        .timeout_ms = 1000,
        .headers = host,
    }) catch unreachable;

    return conn;
}

pub fn deinit(self: *Self) void {
    self.client.deinit();
}

const ReadMessageError = mem.Allocator.Error || zlib.Error || json.ParseError(json.Scanner) || json.ParseFromValueError;

/// listens for messages
fn readMessage(self: *Self, _: anytype) !void {
    try self.client.readTimeout(0);

    while (try self.client.read()) |msg| { // check your intents, dumbass
        defer self.client.done(msg);

        try self.packets.appendSlice(msg.data);

        // end of zlib
        if (!std.mem.endsWith(u8, msg.data, &[4]u8{ 0x00, 0x00, 0xFF, 0xFF }))
            continue;

        const buf = try self.packets.toOwnedSlice();
        const decompressed = try self.inflator.decompressAllAlloc(buf);
        defer self.allocator.free(decompressed);

        const raw = try json.parseFromSlice(struct {
            op: isize,
            d: json.Value,
            s: ?i64,
            t: ?[]const u8,
        }, self.allocator, decompressed, .{});
        defer raw.deinit();

        const payload = raw.value;

        switch (@as(Opcode, @enumFromInt(payload.op))) {
            Opcode.Dispatch => {
                // maybe use threads and call it instead from there
                if (payload.t) |name| {
                    self.sequence.store(payload.s orelse 0, .monotonic);
                    try self.handleEvent(name, decompressed);
                }
            },
            Opcode.Hello => {
                const HelloPayload = struct { heartbeat_interval: u64, _trace: [][]const u8 };
                const parsed = try json.parseFromValue(HelloPayload, self.allocator, payload.d, .{});
                defer parsed.deinit();

                const helloPayload = parsed.value;

                // PARSE NEW URL IN READY

                self.heart = Heart{
                    .heartbeatInterval = helloPayload.heartbeat_interval,
                    .lastBeat = 0,
                };

                if (self.resumable()) {
                    try self.resume_();
                    return;
                }

                try self.identify(self.details.properties);

                var prng = std.Random.DefaultPrng.init(0);
                const jitter = std.Random.float(prng.random(), f64);
                self.heart.lastBeat = std.time.milliTimestamp();
                const heartbeat_writer = try std.Thread.spawn(.{}, Self.heartbeat, .{ self, jitter });
                heartbeat_writer.detach();
            },
            Opcode.HeartbeatACK => {
                // perhaps this needs a mutex?
                self.rw_mutex.lock();
                defer self.rw_mutex.unlock();
                self.heart.lastBeat = std.time.milliTimestamp();
            },
            Opcode.Heartbeat => {
                self.ws_mutex.lock();
                defer self.ws_mutex.unlock();
                try self.send(false, .{ .op = @intFromEnum(Opcode.Heartbeat), .d = self.sequence.load(.monotonic) });
            },
            Opcode.Reconnect => {
                try self.reconnect();
            },
            Opcode.Resume => {
                const WithSequence = struct {
                    token: []const u8,
                    session_id: []const u8,
                    seq: ?isize,
                };
                const parsed = try json.parseFromValue(WithSequence, self.allocator, payload.d, .{});
                defer parsed.deinit();

                const resume_payload = parsed.value;

                self.sequence.store(resume_payload.seq orelse 0, .monotonic);
                self.session_id = resume_payload.session_id;
            },
            Opcode.InvalidSession => {},
            else => {},
        }
    }
}

pub const SendHeartbeatError = CloseError || SendError;

pub fn heartbeat(self: *Self, initial_jitter: f64) SendHeartbeatError!void {
    var jitter = initial_jitter;

    while (true) {
        // basecase
        if (jitter == 1.0) {
            std.Thread.sleep(std.time.ns_per_ms * self.heart.heartbeatInterval);
        } else {
            const timeout = @as(f64, @floatFromInt(self.heart.heartbeatInterval)) * jitter;
            std.Thread.sleep(std.time.ns_per_ms * @as(u64, @intFromFloat(timeout)));
        }

        self.rw_mutex.lock();
        const last = self.heart.lastBeat;
        self.rw_mutex.unlock();

        const seq = self.sequence.load(.monotonic);
        self.ws_mutex.lock();
        try self.send(false, .{ .op = @intFromEnum(Opcode.Heartbeat), .d = seq });
        self.ws_mutex.unlock();

        if ((std.time.milliTimestamp() - last) > (5000 * self.heart.heartbeatInterval)) {
            try self.close(ShardSocketCloseCodes.ZombiedConnection, "Zombied connection");
            @panic("zombied conn\n");
        }

        jitter = 1.0;
    }
}

pub const ReconnectError = ConnectError || CloseError;

pub fn reconnect(self: *Self) ReconnectError!void {
    try self.disconnect();
    try self.connect();
}

pub const ConnectError =
    net.TcpConnectToAddressError || crypto.tls.Client.InitError(net.Stream) ||
    net.Stream.ReadError || net.IPParseError ||
    crypto.Certificate.Bundle.RescanError || net.TcpConnectToHostError ||
    std.fmt.BufPrintError || mem.Allocator.Error;

pub fn connect(self: *Self) ConnectError!void {
    //std.time.sleep(std.time.ms_per_s * 5);
    self.client = try Self._connect_ws(self.allocator, self.gatewayUrl());
    //const event_listener = try std.Thread.spawn(.{}, Self.readMessage, .{ &self, null });
    //event_listener.join();

    self.readMessage(null) catch unreachable;
}

pub fn disconnect(self: *Self) CloseError!void {
    try self.close(ShardSocketCloseCodes.Shutdown, "Shard down request");
}

pub const CloseError = mem.Allocator.Error || error{ReasonTooLong};

pub fn close(self: *Self, code: ShardSocketCloseCodes, reason: []const u8) CloseError!void {
    // Implement reconnection logic here
    try self.client.close(.{
        .code = @intFromEnum(code), //u16
        .reason = reason, //[]const u8
    });
}

pub const SendError = net.Stream.WriteError || std.ArrayList(u8).Writer.Error;

pub fn send(self: *Self, _: bool, data: anytype) SendError!void {
    var buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(data, .{}, string.writer());

    try self.client.write(try string.toOwnedSlice());
}

pub fn handleEvent(self: *Self, name: []const u8, payload: []const u8) !void {
    // std.debug.print("event: {s}\n", .{name});

    if (mem.eql(u8, name, "READY")) {
        const ready = try zjson.parse(GatewayPayload(Types.Ready), self.allocator, payload);

        if (self.handler.ready) |event| try event(self, ready.value.d.?);
    }

    if (mem.eql(u8, name, "CHANNEL_CREATE")) {
        const chan = try zjson.parse(GatewayPayload(Types.Channel), self.allocator, payload);

        if (self.handler.channel_create) |event| try event(self, chan.value.d.?);
    }

    if (mem.eql(u8, name, "CHANNEL_UPDATE")) {
        const chan = try zjson.parse(GatewayPayload(Types.Channel), self.allocator, payload);

        if (self.handler.channel_update) |event| try event(self, chan.value.d.?);
    }

    if (mem.eql(u8, name, "CHANNEL_DELETE")) {
        const chan = try zjson.parse(GatewayPayload(Types.Channel), self.allocator, payload);

        if (self.handler.channel_delete) |event| try event(self, chan.value.d.?);
    }

    if (mem.eql(u8, name, "INVITE_CREATE")) {
        const data = try zjson.parse(GatewayPayload(Types.InviteCreate), self.allocator, payload);

        if (self.handler.invite_create) |event| try event(self, data.value.d.?);
    }

    if (mem.eql(u8, name, "INVITE_DELETE")) {
        const data = try zjson.parse(GatewayPayload(Types.InviteDelete), self.allocator, payload);

        if (self.handler.invite_delete) |event| try event(self, data.value.d.?);
    }

    if (mem.eql(u8, name, "MESSAGE_CREATE")) {
        const message = try zjson.parse(GatewayPayload(Types.Message), self.allocator, payload);

        if (self.handler.message_create) |event| try event(self, message.value.d.?);
    }

    if (mem.eql(u8, name, "MESSAGE_DELETE")) {
        const data = try zjson.parse(GatewayPayload(Types.MessageDelete), self.allocator, payload);

        if (self.handler.message_delete) |event| try event(self, data.value.d.?);
    }

    if (mem.eql(u8, name, "MESSAGE_UPDATE")) {
        const message = try zjson.parse(GatewayPayload(Types.Message), self.allocator, payload);

        if (self.handler.message_update) |event| try event(self, message.value.d.?);
    }

    if (mem.eql(u8, name, "MESSAGE_DELETE_BULK")) {
        const data = try zjson.parse(GatewayPayload(Types.MessageDeleteBulk), self.allocator, payload);

        if (self.handler.message_delete_bulk) |event| try event(self, data.value.d.?);
    }

    if (mem.eql(u8, name, "MESSAGE_REACTION_ADD")) {
        const data = try zjson.parse(GatewayPayload(Types.MessageReactionAdd), self.allocator, payload);

        if (self.handler.message_reaction_add) |event| try event(self, data.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_CREATE")) {
        const isAvailable =
            try zjson.parse(GatewayPayload(struct { unavailable: ?bool }), self.allocator, payload);

        if (isAvailable.value.d.?.unavailable == true) {
            const guild = try zjson.parse(GatewayPayload(Types.Guild), self.allocator, payload);

            if (self.handler.guild_create) |event| try event(self, guild.value.d.?);
            return;
        }

        const guild = try zjson.parse(GatewayPayload(Types.UnavailableGuild), self.allocator, payload);

        if (self.handler.guild_create_unavailable) |event| try event(self, guild.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_UPDATE")) {
        const guild = try zjson.parse(GatewayPayload(Types.Guild), self.allocator, payload);

        if (self.handler.guild_update) |event| try event(self, guild.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_DELETE")) {
        const guild = try zjson.parse(GatewayPayload(Types.UnavailableGuild), self.allocator, payload);

        if (self.handler.guild_delete) |event| try event(self, guild.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_MEMBER_ADD")) {
        const guild_id = try zjson.parse(GatewayPayload(Types.GuildMemberAdd), self.allocator, payload);

        if (self.handler.guild_member_add) |event| try event(self, guild_id.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_MEMBER_UPDATE")) {
        const fields = try zjson.parse(GatewayPayload(Types.GuildMemberUpdate), self.allocator, payload);

        if (self.handler.guild_member_update) |event| try event(self, fields.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_MEMBER_REMOVE")) {
        const user = try zjson.parse(GatewayPayload(Types.GuildMemberRemove), self.allocator, payload);

        if (self.handler.guild_member_remove) |event| try event(self, user.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_ROLE_CREATE")) {
        const role = try zjson.parse(GatewayPayload(Types.GuildRoleCreate), self.allocator, payload);

        if (self.handler.guild_role_create) |event| try event(self, role.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_ROLE_UPDATE")) {
        const role = try zjson.parse(GatewayPayload(Types.GuildRoleUpdate), self.allocator, payload);

        if (self.handler.guild_role_update) |event| try event(self, role.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_ROLE_DELETE")) {
        const role_id = try zjson.parse(GatewayPayload(Types.GuildRoleDelete), self.allocator, payload);

        if (self.handler.guild_role_delete) |event| try event(self, role_id.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_DELETE")) {
        const guild = try zjson.parse(GatewayPayload(Types.UnavailableGuild), self.allocator, payload);

        if (self.handler.guild_delete) |event| try event(self, guild.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_BAN_ADD")) {
        const gba = try zjson.parse(GatewayPayload(Types.GuildBanAddRemove), self.allocator, payload);

        if (self.handler.guild_ban_add) |event| try event(self, gba.value.d.?);
    }

    if (mem.eql(u8, name, "GUILD_BAN_REMOVE")) {
        const gbr = try zjson.parse(GatewayPayload(Types.GuildBanAddRemove), self.allocator, payload);

        if (self.handler.guild_ban_remove) |event| try event(self, gbr.value.d.?);
    }

    if (mem.eql(u8, name, "TYPING_START")) {
        const data = try zjson.parse(GatewayPayload(Types.TypingStart), self.allocator, payload);

        if (self.handler.typing_start) |event| try event(self, data.value.d.?);
    }

    if (mem.eql(u8, name, "USER_UPDATE")) {
        const user = try zjson.parse(GatewayPayload(Types.User), self.allocator, payload);

        if (self.handler.user_update) |event| try event(self, user.value.d.?);
    }

    if (self.handler.any) |anyEvent|
        try anyEvent(self, payload);
}
