const std = @import("std");
const json = std.json;
const mem = std.mem;
const http = std.http;
const ws = @import("ws");
const builtin = @import("builtin");
const HttpClient = @import("tls12").HttpClient;
const net = std.net;
const crypto = std.crypto;
const tls = std.crypto.tls;
// todo use this to read compressed messages
const zlib = @import("zlib");

const Self = @This();

const Opcode = enum(u4) {
    Dispatch = 0,
    Heartbeat = 1,
    Identify = 2,
    PresenceUpdate = 3,
    VoiceStateUpdate = 4,
    Resume = 6,
    Reconnect = 7,
    RequestGuildMember = 8,
    InvalidSession = 9,
    Hello = 10,
    HeartbeatACK = 11,
};

const ShardSocketCloseCodes = enum(u16) {
    Shutdown = 3000,
    ZombiedConnection = 3010,
};

const BASE_URL = "https://discord.com/api/v10";

pub const Intents = packed struct {
    guilds: bool = false,
    guild_members: bool = false,
    guild_bans: bool = false,
    guild_emojis: bool = false,
    guild_integrations: bool = false,
    guild_webhooks: bool = false,
    guild_invites: bool = false,
    guild_voice_states: bool = false,

    guild_presences: bool = false,
    guild_messages: bool = false,
    guild_message_reactions: bool = false,
    guild_message_typing: bool = false,
    direct_messages: bool = false,
    direct_message_reactions: bool = false,
    direct_message_typing: bool = false,
    message_content: bool = false,

    guild_scheduled_events: bool = false,
    _pad: u3 = 0,
    auto_moderation_configuration: bool = false,
    auto_moderation_execution: bool = false,
    _pad2: u2 = 0,

    _pad3: u8 = 0,

    pub fn toRaw(self: Intents) u32 {
        return @as(u32, @bitCast(self));
    }

    pub fn fromRaw(raw: u32) Intents {
        return @as(Intents, @bitCast(raw));
    }

    pub fn jsonStringify(self: Intents, options: std.json.StringifyOptions, writer: anytype) !void {
        _ = options;
        try writer.print("{}", .{self.toRaw()});
    }
};

const FetchReq = struct {
    allocator: mem.Allocator,
    token: []const u8,
    client: HttpClient,
    body: std.ArrayList(u8),

    pub fn init(allocator: mem.Allocator, token: []const u8) FetchReq {
        const client = HttpClient{ .allocator = allocator };
        return FetchReq{
            .allocator = allocator,
            .client = client,
            .body = std.ArrayList(u8).init(allocator),
            .token = token,
        };
    }

    pub fn deinit(self: *FetchReq) void {
        self.client.deinit();
        self.body.deinit();
    }

    pub fn makeRequest(self: *FetchReq, method: http.Method, path: []const u8, body: ?[]const u8) !HttpClient.FetchResult {
        var fetch_options = HttpClient.FetchOptions{
            .location = HttpClient.FetchOptions.Location{
                .url = path,
            },
            .extra_headers = &[_]http.Header{
                http.Header{ .name = "Accept", .value = "application/json" },
                http.Header{ .name = "Content-Type", .value = "application/json" },
                http.Header{ .name = "Authorization", .value = self.token },
            },
            .method = method,
            .response_storage = .{ .dynamic = &self.body },
        };

        if (body != null) {
            fetch_options.payload = body;
        }

        const res = try self.client.fetch(fetch_options);
        return res;
    }
};

///
/// https://discord.com/developers/docs/topics/gateway#get-gateway
///
const GatewayInfo = struct {
    /// The WSS URL that can be used for connecting to the gateway
    url: []const u8,
};

///
/// https://discord.com/developers/docs/events/gateway#session-start-limit-object
///
const GatewaySessionStartLimit = struct {
    /// Total number of session starts the current user is allowed
    total: u32,
    /// Remaining number of session starts the current user is allowed
    remaining: u32,
    /// Number of milliseconds after which the limit resets
    reset_after: u32,
    /// Number of identify requests allowed per 5 seconds
    max_concurrency: u32,
};

///
/// https://discord.com/developers/docs/topics/gateway#get-gateway-bot
///
const GatewayBotInfo = struct {
    url: []const u8,
    ///
    /// The recommended number of shards to use when connecting
    ///
    /// See https://discord.com/developers/docs/topics/gateway#sharding
    ///
    shards: u32,
    ///
    /// Information on the current session start limit
    ///
    /// See https://discord.com/developers/docs/topics/gateway#session-start-limit-object
    ///
    session_start_limit: ?GatewaySessionStartLimit,
};

const IdentifyProperties = struct {
    ///
    /// Operating system the shard runs on.
    ///
    os: []const u8,
    ///
    /// The "browser" where this shard is running on.
    ///
    browser: []const u8,
    ///
    /// The device on which the shard is running.
    ///
    device: []const u8,
};

const _default_properties = IdentifyProperties{
    .os = @tagName(builtin.os.tag),
    .browser = "discord.zig",
    .device = "discord.zig",
};

const Heart = struct {
    heartbeatInterval: u64,
    ack: bool,
    /// useful for calculating ping
    lastBeat: u64,
};

client: ws.Client,
token: []const u8,
intents: Intents,
//heart: Heart =
allocator: mem.Allocator,
resume_gateway_url: ?[]const u8 = null,
info: GatewayBotInfo,

session_id: ?[]const u8,
sequence: u64,
heart: Heart = .{ .heartbeatInterval = 45000, .ack = false, .lastBeat = 0 },

///useful for closing the conn
mutex: std.Thread.Mutex = .{},

inline fn jitter() i1 {
    return 0;
}

pub inline fn resumable(self: *Self) bool {
    return self.resume_gateway_url != null and
        self.session_id != null and
        self.getSequence() > 0;
}

pub fn resume_(self: *Self) !void {
    const data = .{ .op = @intFromEnum(Opcode.Resume), .d = .{
        .token = self.token,
        .session_id = self.session_id,
        .seq = self.getSequence(),
    } };

    try self.send(data);
}

inline fn gateway_url(self: ?*Self) []const u8 {
    // wtf is this?
    if (self) |s| {
        return s.resume_gateway_url orelse s.info.url;
    }

    return "wss://gateway.discord.gg";
}

// identifies in order to connect to Discord and get the online status, this shall be done on hello perhaps
fn identify(self: *Self) !void {
    const data = .{
        .op = @intFromEnum(Opcode.Identify),
        .d = .{
            //.compress = false,
            .intents = self.intents.toRaw(),
            .properties = Self._default_properties,
            .token = self.token,
        },
    };

    // try posting our shitty data
    try self.send(data);
}

// asks /gateway/bot initializes both the ws client and the http client
pub fn init(allocator: mem.Allocator, args: struct { token: []const u8, intents: Intents }) !Self {
    var req = FetchReq.init(allocator, args.token);
    defer req.deinit();

    const res = try req.makeRequest(.GET, BASE_URL ++ "/gateway/bot", null);
    const body = try req.body.toOwnedSlice();
    defer allocator.free(body);

    // check status idk
    if (res.status != http.Status.ok) {
        @panic("we are cooked\n");
    }

    const parsed = try json.parseFromSlice(GatewayBotInfo, allocator, body, .{});
    const url = parsed.value.url["wss://".len..];
    defer parsed.deinit();

    return .{
        .allocator = allocator,
        .token = args.token,
        .intents = args.intents,
        // maybe there is a better way to do this
        .client = try Self._connect_ws(allocator, url),
        .session_id = undefined,
        .sequence = 0,
        .info = parsed.value,
    };
}

inline fn _connect_ws(allocator: mem.Allocator, url: []const u8) !ws.Client {
    var conn = try ws.Client.init(allocator, .{
        .tls = true, // important: zig.http doesn't support this, type shit
        .port = 443,
        .host = url,
    });

    conn.handshake("/?v=10&encoding=json", .{
        .timeout_ms = 1000,
        .headers = "host: gateway.discord.gg",
    }) catch unreachable;

    return conn;
}

pub fn deinit(self: *Self) void {
    self.client.deinit();
    std.debug.print("killing the whole bot\n", .{});
}

// listens for messages
pub fn readMessage(self: *Self) !void {
    try self.client.readTimeout(0);

    while (true) {
        const msg = (try self.client.read()) orelse {
            std.debug.print(".", .{});
            continue;
        };

        defer self.client.done(msg);

        const DiscordData = struct {
            s: ?u64, //well figure it out
            op: Opcode,
            d: json.Value, // needs parsing
            t: ?[]const u8,
        };

        const raw = try json.parseFromSlice(DiscordData, self.allocator, msg.data, .{});

        const payload = raw.value;

        std.debug.print("received: {?s}\n", .{payload.t});

        if (payload.op == Opcode.Dispatch) {
            // maybe use mutex
            self.setSequence(payload.s orelse 0);
        }

        switch (payload.op) {
            Opcode.Dispatch => {},
            Opcode.Hello => {
                const HelloPayload = struct { heartbeat_interval: u64, _trace: [][]const u8 };
                const parsed = try json.parseFromValue(HelloPayload, self.allocator, payload.d, .{});
                const helloPayload = parsed.value;

                // PARSE NEW URL IN READY

                self.heart = Heart{
                    // TODO: fix bug
                    .heartbeatInterval = helloPayload.heartbeat_interval,
                    .ack = false,
                    .lastBeat = 0,
                };

                std.debug.print("starting heart beater. seconds:{d}...\n", .{self.heart.heartbeatInterval});

                try self.heartbeat();

                const thread = try std.Thread.spawn(.{}, Self.heartbeat_wait, .{self});
                thread.detach();

                if (self.resumable()) {
                    try self.resume_();
                    return;
                } else {
                    try self.identify();
                }
            },
            Opcode.HeartbeatACK => {
                // perhaps this needs a mutex?
                std.debug.print("got heartbeat ack\n", .{});

                self.mutex.lock();
                defer self.mutex.unlock();

                self.heart.ack = true;
            },
            Opcode.Heartbeat => {
                std.debug.print("sending requested heartbeat\n", .{});
                try self.heartbeat();
            },
            Opcode.Reconnect => {
                std.debug.print("reconnecting\n", .{});
                try self.reconnect();
            },
            Opcode.Resume => {
                const WithSequence = struct {
                    token: []const u8,
                    session_id: []const u8,
                    seq: ?u64,
                };
                const parsed = try json.parseFromValue(WithSequence, self.allocator, payload.d, .{});
                const payload_new = parsed.value;

                self.setSequence(payload_new.seq orelse 0);
                self.session_id = payload_new.session_id;
            },
            Opcode.InvalidSession => {},
            else => {
                std.debug.print("Unhandled {} -- {s}", .{ payload.op, "none" });
            },
        }
    }
}

pub fn heartbeat(self: *Self) !void {
    const data = .{ .op = @intFromEnum(Opcode.Heartbeat), .d = if (self.getSequence() > 0) self.getSequence() else null };

    try self.send(data);
}

pub fn heartbeat_wait(self: *Self) !void {
    while (true) {
        std.debug.print("zzz for {d}\n", .{self.heart.heartbeatInterval});
        std.Thread.sleep(@as(u64, @intCast(std.time.ns_per_ms * self.heart.heartbeatInterval)));

        std.debug.print(">> ♥ and ack received: {}\n", .{self.heart.ack});

        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.heart.ack == true) {
            std.debug.print("sending unrequested heartbeat\n", .{});
            self.heartbeat() catch unreachable;
            try self.client.readTimeout(1000);
        } else {
            self.close(ShardSocketCloseCodes.ZombiedConnection, "Zombied connection") catch unreachable;
            @panic("zombied conn\n");
        }
    }
}

pub inline fn reconnect(self: *Self) !void {
    try self.disconnect();
    _ = try self.connect();
}

pub fn connect(self: *Self) !Self {
    self.mutex.lock();
    defer self.mutex.unlock();

    //std.time.sleep(std.time.ms_per_s * 5);
    self.client = try Self._connect_ws(self.allocator, self.gateway_url());

    return self.*;
}

pub fn disconnect(self: *Self) !void {
    try self.close(ShardSocketCloseCodes.Shutdown, "Shard down request");
}

pub fn close(self: *Self, code: ShardSocketCloseCodes, reason: []const u8) !void {
    self.mutex.lock();
    defer self.mutex.unlock();

    std.debug.print("cooked closing ws conn...\n", .{});
    // Implement reconnection logic here
    try self.client.close(.{
        .code = @intFromEnum(code), //u16
        .reason = reason, //[]const u8
    });
}

pub fn send(self: *Self, data: anytype) !void {
    var buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(data, .{}, string.writer());

    std.debug.print("{s}\n", .{string.items});

    try self.client.write(string.items);
}

pub inline fn getSequence(self: *Self) u64 {
    return self.sequence;
}

pub inline fn setSequence(self: *Self, new: u64) void {
    self.mutex.lock();
    defer self.mutex.unlock();

    self.sequence = new;
}
