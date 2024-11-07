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
const zmpl = @import("zmpl");

const Discord = @import("types.zig");
const Parser = @import("parser.zig");

const debug = std.log.scoped(.@"discord.zig");
const Self = @This();

const GatewayPayload = Discord.GatewayPayload;
const Opcode = Discord.GatewayOpcodes;
const Intents = Discord.Intents;
const Shared = @import("shared.zig");
const IdentifyProperties = Shared.IdentifyProperties;
const GatewayInfo = Shared.GatewayInfo;
const GatewayBotInfo = Shared.GatewayBotInfo;
const GatewaySessionStartLimit = Shared.GatewaySessionStartLimit;

const ShardSocketCloseCodes = enum(u16) {
    Shutdown = 3000,
    ZombiedConnection = 3010,
};

const BASE_URL = "https://discord.com/api/v10";

pub const GatewayDispatchEvent = struct {
    // TODO: implement // application_command_permissions_update: null = null,
    // TODO: implement // auto_moderation_rule_create: null = null,
    // TODO: implement // auto_moderation_rule_update: null = null,
    // TODO: implement // auto_moderation_rule_delete: null = null,
    // TODO: implement // auto_moderation_action_execution: null = null,
    // TODO: implement // channel_create: null = null,
    // TODO: implement // channel_update: null = null,
    // TODO: implement // channel_delete: null = null,
    // TODO: implement // channel_pins_update: null = null,
    // TODO: implement // thread_create: null = null,
    // TODO: implement // thread_update: null = null,
    // TODO: implement // thread_delete: null = null,
    // TODO: implement // thread_list_sync: null = null,
    // TODO: implement // thread_member_update: null = null,
    // TODO: implement // thread_members_update: null = null,
    // TODO: implement // guild_audit_log_entry_create: null = null,
    // TODO: implement // guild_create: null = null,
    // TODO: implement // guild_update: null = null,
    // TODO: implement // guild_delete: null = null,
    // TODO: implement // guild_ban_add: null = null,
    // TODO: implement // guild_ban_remove: null = null,
    // TODO: implement // guild_emojis_update: null = null,
    // TODO: implement // guild_stickers_update: null = null,
    // TODO: implement // guild_integrations_update: null = null,
    // TODO: implement // guild_member_add: null = null,
    // TODO: implement // guild_member_remove: null = null,
    // TODO: implement // guild_member_update: null = null,
    // TODO: implement // guild_members_chunk: null = null,
    // TODO: implement // guild_role_create: null = null,
    // TODO: implement // guild_role_update: null = null,
    // TODO: implement // guild_role_delete: null = null,
    // TODO: implement // guild_scheduled_event_create: null = null,
    // TODO: implement // guild_scheduled_event_update: null = null,
    // TODO: implement // guild_scheduled_event_delete: null = null,
    // TODO: implement // guild_scheduled_event_user_add: null = null,
    // TODO: implement // guild_scheduled_event_user_remove: null = null,
    // TODO: implement // integration_create: null = null,
    // TODO: implement // integration_update: null = null,
    // TODO: implement // integration_delete: null = null,
    // TODO: implement // interaction_create: null = null,
    // TODO: implement // invite_create: null = null,
    // TODO: implement // invite_delete: null = null,
    message_create: ?*const fn (message: Discord.Message) void = undefined,
    message_update: ?*const fn (message: Discord.Message) void = undefined,
    message_delete: ?*const fn (log: Discord.MessageDelete) void = undefined,
    message_delete_bulk: ?*const fn (log: Discord.MessageDeleteBulk) void = undefined,
    // TODO: implement // message_delete_bulk: null = null,
    // TODO: implement // message_reaction_add: null = null,
    // TODO: implement // message_reaction_remove: null = null,
    // TODO: implement // message_reaction_remove_all: null = null,
    // TODO: implement // message_reaction_remove_emoji: null = null,
    // TODO: implement // presence_update: null = null,
    // TODO: implement // stage_instance_create: null = null,
    // TODO: implement // stage_instance_update: null = null,
    // TODO: implement // stage_instance_delete: null = null,
    // TODO: implement // typing_start: null = null,
    // TODO: implement // user_update: null = null,
    // TODO: implement // voice_channel_effect_send: null = null,
    // TODO: implement // voice_state_update: null = null,
    // TODO: implement // voice_server_update: null = null,
    // TODO: implement // webhooks_update: null = null,
    // TODO: implement // entitlement_create: null = null,
    // TODO: implement // entitlement_update: null = null,
    // TODO: implement // entitlement_delete: null = null,
    // TODO: implement // message_poll_vote_add: null = null,
    // TODO: implement // message_poll_vote_remove: null = null,

    ready: ?*const fn (data: Discord.Ready) void = undefined,
    // TODO: implement // resumed: null = null,
    any: ?*const fn (data: []const u8) void = undefined,
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

properties: IdentifyProperties = _default_properties,
session_id: ?[]const u8,
sequence: isize,
heart: Heart = .{ .heartbeatInterval = 45000, .ack = false, .lastBeat = 0 },

///
handler: GatewayDispatchEvent,
packets: std.ArrayList(u8),
inflator: zlib.Decompressor,

///useful for closing the conn
mutex: std.Thread.Mutex = .{},
log: Log = .no,

/// caller must free the data
fn parseJson(self: *Self, raw: []const u8) !zmpl.Data {
    var data = zmpl.Data.init(self.allocator);
    try data.fromJson(raw);
    return data;
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

inline fn gatewayUrl(self: ?*Self) []const u8 {
    return if (self) |s| (s.resume_gateway_url orelse s.info.url)["wss://".len..] else "gateway.discord.gg";
}

// identifies in order to connect to Discord and get the online status, this shall be done on hello perhaps
fn identify(self: *Self, properties: ?IdentifyProperties) !void {
    self.logif("intents: {d}", .{self.intents.toRaw()});

    if (self.intents.toRaw() != 0) {
        const data = .{
            .op = @intFromEnum(Opcode.Identify),
            .d = .{
                .intents = self.intents.toRaw(),
                .properties = properties orelse Self._default_properties,
                .token = self.token,
            },
        };
        try self.send(data);
    } else {
        const data = .{
            .op = @intFromEnum(Opcode.Identify),
            .d = .{
                .capabilities = 30717,
                .properties = properties orelse Self._default_properties,
                .token = self.token,
            },
        };
        try self.send(data);
    }
}

const Log = union(enum) { yes, no };

// asks /gateway/bot initializes both the ws client and the http client
pub fn login(allocator: mem.Allocator, args: struct {
    token: []const u8,
    intents: Intents,
    run: GatewayDispatchEvent,
    log: Log,
}) !Self {
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
    defer parsed.deinit();
    const url = parsed.value.url["wss://".len..];

    return .{
        .allocator = allocator,
        .token = args.token,
        .intents = args.intents,
        // maybe there is a better way to do this
        .client = try Self._connect_ws(allocator, url),
        .session_id = undefined,
        .sequence = 0,
        .info = parsed.value,
        .handler = args.run,
        .log = args.log,
        .packets = std.ArrayList(u8).init(allocator),
        .inflator = try zlib.Decompressor.init(allocator, .{ .header = .zlib_or_gzip }),
    };
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

// listens for messages
pub fn readMessage(self: *Self, _: anytype) !void {
    try self.client.readTimeout(0);

    while (true) {
        const msg = (try self.client.read()) orelse
            continue;

        defer self.client.done(msg);

        // self.logif("received: {?s}\n", .{msg.data});
        try self.packets.appendSlice(msg.data);

        // end of zlib
        if (!std.mem.endsWith(u8, msg.data, &[4]u8{ 0x00, 0x00, 0xFF, 0xFF }))
            continue;

        // self.logif("{b}\n", .{self.packets.items});
        const buf = try self.packets.toOwnedSlice();
        const decompressed = try self.inflator.decompressAllAlloc(buf);

        const raw = try json.parseFromSlice(struct {
            /// opcode for the payload
            op: isize,
            /// Event data
            d: json.Value,
            /// Sequence isize, used for resuming sessions and heartbeats
            s: ?i64,
            /// The event name for this payload
            t: ?[]const u8,
        }, self.allocator, decompressed, .{});

        const payload = raw.value;

        switch (@as(Opcode, @enumFromInt(payload.op))) {
            Opcode.Dispatch => {
                self.setSequence(payload.s orelse 0);
                // maybe use threads and call it instead from there
                if (payload.t) |name| try self.handleEvent(name, decompressed);
            },
            Opcode.Hello => {
                {
                    const HelloPayload = struct { heartbeat_interval: u64, _trace: [][]const u8 };
                    const parsed = try json.parseFromValue(HelloPayload, self.allocator, payload.d, .{});
                    defer parsed.deinit();

                    const helloPayload = parsed.value;

                    // PARSE NEW URL IN READY

                    self.heart = Heart{
                        // TODO: fix bug
                        .heartbeatInterval = helloPayload.heartbeat_interval,
                        .ack = false,
                        .lastBeat = 0,
                    };

                    self.logif("starting heart beater. seconds:{d}...", .{self.heart.heartbeatInterval});

                    try self.heartbeat();

                    var prng = std.Random.DefaultPrng.init(0);
                    const jitter = std.Random.float(prng.random(), f64);

                    const thread = try std.Thread.spawn(.{}, Self.heartbeat_wait, .{ self, jitter });
                    thread.detach();

                    if (self.resumable()) {
                        try self.resume_();
                        return;
                    } else {
                        try self.identify(self.properties);
                    }
                }
            },
            Opcode.HeartbeatACK => {
                // perhaps this needs a mutex?
                self.logif("got heartbeat ack", .{});

                self.mutex.lock();
                defer self.mutex.unlock();

                self.heart.ack = true;
            },
            Opcode.Heartbeat => {
                self.logif("sending requested heartbeat", .{});
                try self.heartbeat();
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
                {
                    const parsed = try json.parseFromValue(WithSequence, self.allocator, payload.d, .{});
                    defer parsed.deinit();

                    const resume_payload = parsed.value;

                    self.setSequence(resume_payload.seq orelse 0);
                    self.session_id = resume_payload.session_id;
                }
            },
            Opcode.InvalidSession => {},
            else => {
                self.logif("Unhandled {d} -- {s}", .{ payload.op, "none" });
            },
        }
    }
}

pub fn heartbeat(self: *Self) !void {
    const data = .{ .op = @intFromEnum(Opcode.Heartbeat), .d = if (self.getSequence() > 0) self.getSequence() else null };

    try self.send(data);
}

pub fn heartbeat_wait(self: *Self, jitter: f64) !void {
    if (jitter == 1.0) {
        // self.logif("zzz for {d}", .{self.heart.heartbeatInterval});
        std.Thread.sleep(std.time.ns_per_ms * self.heart.heartbeatInterval);
    } else {
        const timeout = @as(f64, @floatFromInt(self.heart.heartbeatInterval)) * jitter;
        self.logif("zzz for {d} and jitter {d}", .{ @as(u64, @intFromFloat(timeout)), jitter });
        std.Thread.sleep(std.time.ns_per_ms * @as(u64, @intFromFloat(timeout)));
    }

    self.logif(">> ♥ and ack received: {}", .{self.heart.ack});

    if (self.heart.ack) {
        self.logif("sending unrequested heartbeat", .{});
        try self.heartbeat();
        try self.client.readTimeout(1000);
    } else {
        self.close(ShardSocketCloseCodes.ZombiedConnection, "Zombied connection") catch unreachable;
        @panic("zombied conn\n");
    }

    return heartbeat_wait(self, 1.0);
}

pub inline fn reconnect(self: *Self) !void {
    try self.disconnect();
    try self.connect();
}

pub fn connect(self: *Self) !void {
    self.mutex.lock();
    defer self.mutex.unlock();

    //std.time.sleep(std.time.ms_per_s * 5);
    self.client = try Self._connect_ws(self.allocator, self.gatewayUrl());
}

pub fn disconnect(self: *Self) !void {
    try self.close(ShardSocketCloseCodes.Shutdown, "Shard down request");
}

pub fn close(self: *Self, code: ShardSocketCloseCodes, reason: []const u8) !void {
    self.mutex.lock();
    defer self.mutex.unlock();

    self.logif("cooked closing ws conn...\n", .{});
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

    //self.logif("{s}\n", .{string.items});

    try self.client.write(try string.toOwnedSlice());
}

pub inline fn getSequence(self: *Self) isize {
    return self.sequence;
}

pub inline fn setSequence(self: *Self, new: isize) void {
    self.mutex.lock();
    defer self.mutex.unlock();

    self.sequence = new;
}

pub fn handleEvent(self: *Self, name: []const u8, payload: []const u8) !void {
    if (std.ascii.eqlIgnoreCase(name, "ready")) {
        var attempt = try self.parseJson(payload);
        defer attempt.deinit();

        const obj = attempt.getT(.object, "d").?;

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
        if (self.handler.ready) |event| event(ready);
    }

    if (std.ascii.eqlIgnoreCase(name, "message_delete")) {
        var attempt = try self.parseJson(payload);
        defer attempt.deinit();

        const obj = attempt.getT(.object, "d").?;
        const data = Discord.MessageDelete{
            .id = try Shared.Snowflake.fromRaw(obj.getT(.string, "id").?),
            .channel_id = try Shared.Snowflake.fromRaw(obj.getT(.string, "channel_id").?),
            .guild_id = try Shared.Snowflake.fromMaybe(obj.getT(.string, "guild_id")),
        };

        if (self.handler.message_delete) |event| event(data);
    }

    if (std.ascii.eqlIgnoreCase(name, "message_delete_bulk")) {
        var attempt = try self.parseJson(payload);
        defer attempt.deinit();

        const obj = attempt.getT(.object, "d").?;
        var ids = std.ArrayList([]const u8).init(self.allocator);

        while (obj.getT(.array, "ids").?.iterator().next()) |id| {
            ids.append(id.string.value) catch unreachable;
        }

        const data = Discord.MessageDeleteBulk{
            .ids = try Shared.Snowflake.fromMany(try ids.toOwnedSlice()),
            .channel_id = try Shared.Snowflake.fromRaw(obj.getT(.string, "channel_id").?),
            .guild_id = try Shared.Snowflake.fromMaybe(obj.getT(.string, "guild_id")),
        };

        if (self.handler.message_delete_bulk) |event| event(data);
    }

    if (std.ascii.eqlIgnoreCase(name, "message_update")) {
        var attempt = try self.parseJson(payload);
        defer attempt.deinit();
        const obj = attempt.getT(.object, "d").?;

        const message = try Parser.parseMessage(self.allocator, obj);
        defer if (message.referenced_message) |mptr| self.allocator.destroy(mptr);

        if (self.handler.message_update) |event| event(message);
    }

    if (std.ascii.eqlIgnoreCase(name, "message_create")) {
        var attempt = try self.parseJson(payload);
        defer attempt.deinit();
        const obj = attempt.getT(.object, "d").?;

        const message = try Parser.parseMessage(self.allocator, obj);
        defer if (message.referenced_message) |mptr| self.allocator.destroy(mptr);

        if (self.handler.message_create) |event| event(message);
    } else {
        if (self.handler.any) |anyEvent| anyEvent(payload);
    }
}

pub fn loginWithEmail(allocator: mem.Allocator, settings: struct { login: []const u8, password: []const u8, run: GatewayDispatchEvent, log: Log }) !Self {
    const AUTH_LOGIN = "https://discord.com/api/v9/auth/login";
    const WS_CONNECT = "gateway.discord.gg";

    var body = std.ArrayList(u8).init(allocator);

    const AuthLoginResponse = struct { user_id: []const u8, token: []const u8, user_settings: struct { locale: []const u8, theme: []const u8 } };

    var fetch_options = HttpClient.FetchOptions{
        .location = HttpClient.FetchOptions.Location{
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

    var client = HttpClient{ .allocator = allocator };
    defer client.deinit();

    const res = try client.fetch(fetch_options);

    if (res.status == std.http.Status.ok) {
        const response = try std.json.parseFromSliceLeaky(AuthLoginResponse, allocator, try body.toOwnedSlice(), .{});

        return .{
            .allocator = allocator,
            .token = response.token,
            .intents = @bitCast(@as(u28, @intCast(0))),
            // maybe there is a better way to do this
            .client = try Self._connect_ws(allocator, WS_CONNECT),
            .session_id = undefined,
            .sequence = 0,
            .info = GatewayBotInfo{ .url = "wss://" ++ WS_CONNECT, .shards = 0, .session_start_limit = null },
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
    } else {
        return error.effn;
    }
}

inline fn logif(self: *Self, comptime format: []const u8, args: anytype) void {
    switch (self.log) {
        .yes => debug.info(format, args),
        .no => {},
    }
}
