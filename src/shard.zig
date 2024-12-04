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
const zmpl = @import("zmpl");
const json_parse = @import("json");
const Parser = @import("parser.zig");

const Self = @This();

const Discord = @import("types.zig");
const GatewayPayload = Discord.GatewayPayload;
const Opcode = Discord.GatewayOpcodes;
const Intents = Discord.Intents;

const Shared = @import("shared.zig");
const IdentifyProperties = Shared.IdentifyProperties;
const GatewayInfo = Shared.GatewayInfo;
const GatewayBotInfo = Shared.GatewayBotInfo;
const GatewaySessionStartLimit = Shared.GatewaySessionStartLimit;
const ShardDetails = Shared.ShardDetails;

const Internal = @import("internal.zig");
const Log = Internal.Log;
const GatewayDispatchEvent = Internal.GatewayDispatchEvent;
const Bucket = Internal.Bucket;
const default_identify_properties = Internal.default_identify_properties;

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

fn parseJson(self: *Self, raw: []const u8) JsonResolutionError!zmpl.Data {
    var data = zmpl.Data.init(self.allocator);
    try data.fromJson(raw);
    return data;
}

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
    self.logif("intents: {d}", .{self.details.intents.toRaw()});

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
    self.logif("killing the whole bot", .{});
}

const ReadMessageError = mem.Allocator.Error || zlib.Error || json.ParseError(json.Scanner) || json.ParseFromValueError;

/// listens for messages
fn readMessage(self: *Self, _: anytype) !void {
    try self.client.readTimeout(0);

    while (try self.client.read()) |msg| {
        defer self.client.done(msg);

        // self.logif("received: {?s}\n", .{msg.data});
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
                    self.logif("logging event {s}", .{name});
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
                    // TODO: fix bug
                    .heartbeatInterval = helloPayload.heartbeat_interval,
                    .lastBeat = 0,
                };

                if (self.resumable()) {
                    try self.resume_();
                    return;
                } else {
                    try self.identify(self.details.properties);
                }

                var prng = std.Random.DefaultPrng.init(0);
                const jitter = std.Random.float(prng.random(), f64);
                self.heart.lastBeat = std.time.milliTimestamp();
                const heartbeat_writer = try std.Thread.spawn(.{}, Self.heartbeat, .{ self, jitter });
                heartbeat_writer.detach();
            },
            Opcode.HeartbeatACK => {
                // perhaps this needs a mutex?
                self.logif("got heartbeat ack", .{});
                self.rw_mutex.lock();
                defer self.rw_mutex.unlock();
                self.heart.lastBeat = std.time.milliTimestamp();
            },
            Opcode.Heartbeat => {
                self.logif("sending requested heartbeat", .{});
                self.ws_mutex.lock();
                defer self.ws_mutex.unlock();
                try self.send(false, .{ .op = @intFromEnum(Opcode.Heartbeat), .d = self.sequence.load(.monotonic) });
            },
            Opcode.Reconnect => {
                self.logif("reconnecting", .{});
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
            else => {
                self.logif("Unhandled {d} -- {s}", .{ payload.op, "none" });
            },
        }
    }
}

pub const SendHeartbeatError = CloseError || SendError;

pub fn heartbeat(self: *Self, initial_jitter: f64) SendHeartbeatError!void {
    var jitter = initial_jitter;

    while (true) {
        // basecase
        if (jitter == 1.0) {
            // self.logif("zzz for {d}", .{self.heart.heartbeatInterval});
            std.Thread.sleep(std.time.ns_per_ms * self.heart.heartbeatInterval);
        } else {
            const timeout = @as(f64, @floatFromInt(self.heart.heartbeatInterval)) * jitter;
            self.logif("zzz for {d} and jitter {d}", .{ @as(u64, @intFromFloat(timeout)), jitter });
            std.Thread.sleep(std.time.ns_per_ms * @as(u64, @intFromFloat(timeout)));
            self.logif("end timeout", .{});
        }

        self.logif(">> ♥ and ack received: {d}", .{self.heart.lastBeat});

        self.rw_mutex.lock();
        const last = self.heart.lastBeat;
        self.rw_mutex.unlock();

        const seq = self.sequence.load(.monotonic);
        self.logif("sending unrequested heartbeat", .{});
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
    self.logif("cooked closing ws conn...\n", .{});
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

    self.logif("{s}\n", .{string.items});

    try self.client.write(try string.toOwnedSlice());
}

pub fn handleEvent(self: *Self, name: []const u8, payload: []const u8) !void {
    var attempt = try self.parseJson(payload);
    defer attempt.deinit();

    const obj = attempt.getT(.object, "d").?;
    if (std.ascii.eqlIgnoreCase(name, "ready")) {
        self.resume_gateway_url = obj.getT(.string, "resume_gateway_url");

        self.logif("new gateway url: {s}", .{self.gatewayUrl()});

        const application = obj.getT(.object, "application");
        const user = try Parser.parseUser(self.allocator, obj.getT(.object, "user").?);

        var ready = Discord.Ready{
            .v = @as(isize, @intCast(obj.getT(.integer, "v").?)),
            .user = user,
            .shard = null,
            .session_id = obj.getT(.string, "session_id").?,
            .guilds = &[0]Discord.UnavailableGuild{},
            .resume_gateway_url = obj.getT(.string, "resume_gateway_url").?,
            .application = if (application) |app| .{
                // todo
                .name = null,
                .description = null,
                .rpc_origins = null,
                .terms_of_service_url = null,
                .privacy_policy_url = null,
                .verify_key = null,
                .primary_sku_id = null,
                .slug = null,
                .icon = null,
                .bot_public = null,
                .bot_require_code_grant = null,
                .owner = null,
                .team = null,
                .guild_id = null,
                .guild = null,
                .cover_image = null,
                .tags = null,
                .install_params = null,
                .integration_types_config = null,
                .custom_install_url = null,
                .role_connections_verification_url = null,
                .approximate_guild_count = null,
                .approximate_user_install_count = null,
                .bot = null,
                .redirect_uris = null,
                .interactions_endpoint_url = null,
                .flags = @as(Discord.ApplicationFlags, @bitCast(@as(u32, @intCast(app.getT(.integer, "flags").?)))),
                .id = try Shared.Snowflake.fromRaw(app.getT(.string, "id").?),
            } else null,
        };

        const shard = obj.getT(.array, "shard");

        if (shard) |s| {
            for (&ready.shard.?, s.items()) |*rs, ss| rs.* = switch (ss.*) {
                .integer => |v| @as(isize, @intCast(v.value)),
                else => unreachable,
            };
        }
        if (self.handler.ready) |event| try event(self, ready);
        return;
    }

    if (std.ascii.eqlIgnoreCase(name, "message_delete")) {
        const data = Discord.MessageDelete{
            .id = try Shared.Snowflake.fromRaw(obj.getT(.string, "id").?),
            .channel_id = try Shared.Snowflake.fromRaw(obj.getT(.string, "channel_id").?),
            .guild_id = try Shared.Snowflake.fromMaybe(obj.getT(.string, "guild_id")),
        };

        if (self.handler.message_delete) |event| try event(self, data);
        return;
    }

    if (std.ascii.eqlIgnoreCase(name, "message_delete_bulk")) {
        var ids = std.ArrayList([]const u8).init(self.allocator);
        defer ids.deinit();

        while (obj.getT(.array, "ids").?.iterator().next()) |id| {
            ids.append(id.string.value) catch unreachable;
        }

        const data = Discord.MessageDeleteBulk{
            .ids = try Shared.Snowflake.fromMany(try ids.toOwnedSlice()),
            .channel_id = try Shared.Snowflake.fromRaw(obj.getT(.string, "channel_id").?),
            .guild_id = try Shared.Snowflake.fromMaybe(obj.getT(.string, "guild_id")),
        };

        if (self.handler.message_delete_bulk) |event| try event(self, data);
        return;
    }

    if (std.ascii.eqlIgnoreCase(name, "message_update")) {
        const message = try Parser.parseMessage(self.allocator, obj);
        //defer if (message.referenced_message) |mptr| self.allocator.destroy(mptr);

        if (self.handler.message_update) |event| try event(self, message);
        return;
    }

    if (std.ascii.eqlIgnoreCase(name, "message_create")) {
        self.logif("it worked {s}", .{name});
        const message = try Parser.parseMessage(self.allocator, obj);
        //defer if (message.referenced_message) |mptr| self.allocator.destroy(mptr);
        self.logif("it worked {s} {?s}", .{ name, message.content });

        if (self.handler.message_create) |event| try event(self, message);
        return;
    }

    if (self.handler.any) |anyEvent| try anyEvent(self, payload);
}

/// highly experimental, do not use
pub fn loginWithEmail(allocator: mem.Allocator, settings: struct { login: []const u8, password: []const u8, run: GatewayDispatchEvent(*Self), log: Log }) !Self {
    const AUTH_LOGIN = "https://discord.com/api/v9/auth/login";
    const WS_CONNECT = "gateway.discord.gg";

    var body = std.ArrayList(u8).init(allocator);
    defer body.deinit();

    const AuthLoginResponse = struct { user_id: []const u8, token: []const u8, user_settings: struct { locale: []const u8, theme: []const u8 } };

    var fetch_options = http.Client.FetchOptions{
        .location = http.Client.FetchOptions.Location{
            .url = AUTH_LOGIN,
        },
        .extra_headers = &[_]http.Header{
            http.Header{ .name = "Accept", .value = "application/json" },
            http.Header{ .name = "Content-Type", .value = "application/json" },
        },
        .method = .POST,
        .response_storage = .{ .dynamic = &body },
    };

    fetch_options.payload = try json.stringifyAlloc(allocator, .{
        .login = settings.login,
        .password = settings.password,
    }, .{});

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    _ = try client.fetch(fetch_options);

    const response = try std.json.parseFromSliceLeaky(AuthLoginResponse, allocator, try body.toOwnedSlice(), .{});

    return .{
        .allocator = allocator,
        .details = ShardDetails{
            .token = response.token,
            .intents = @bitCast(@as(u28, @intCast(0))),
        },
        // maybe there is a better way to do this
        .client = try Self._connect_ws(allocator, WS_CONNECT),
        .session_id = undefined,
        .options = ShardOptions{ .info = GatewayBotInfo{ .url = "wss://" ++ WS_CONNECT, .shards = 0, .session_start_limit = null }, .ratelimit_options = .{} },
        .handler = settings.run,
        .log = settings.log,
        .packets = std.ArrayList(u8).init(allocator),
        .inflator = try zlib.Decompressor.init(allocator, .{ .header = .zlib_or_gzip }),
        .properties = IdentifyProperties{
            .os = "Linux",
            .browser = "Firefox",
            .device = "",
            .system_locale = "en-US",
            .browser_user_agent = "Mozilla/5.0 (X11; Linux x86_64; rv:132.0) Gecko/20100101 Firefox/132.0",
            .browser_version = "132.0",
            .os_version = "",
            .referrer = "",
            .referring_domain = "",
            .referrer_current = "",
            .referring_domain_current = "",
            .release_channel = "stable",
            .client_build_number = 342245, // TODO we should make an script to fetch this...
            .client_event_source = null,
        },
    };
}

inline fn logif(self: *Self, comptime format: []const u8, args: anytype) void {
    switch (self.log) {
        .yes => Internal.debug.info(format, args),
        .no => {},
    }
}
