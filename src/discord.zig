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

const Discord = @import("raw_types.zig");

const debug = std.log.scoped(.@"discord.zig");
const Self = @This();

const GatewayPayload = Discord.GatewayPayload;
const Opcode = Discord.GatewayOpcodes;
const Intents = Discord.Intents;

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
    message_create: *const fn (message: Discord.Message) void = undefined,
    // TODO: implement // message_update: null = null,
    // TODO: implement // message_delete: null = null,
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

    // TODO: implement // ready: null = null,
    // TODO: implement // resumed: null = null,
    any: *const fn (data: []u8) void = undefined,
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
sequence: isize,
heart: Heart = .{ .heartbeatInterval = 45000, .ack = false, .lastBeat = 0 },

///
handler: GatewayDispatchEvent,
packets: std.ArrayList(u8),
inflator: zlib.Decompressor,

///useful for closing the conn
mutex: std.Thread.Mutex = .{},
log: Log = .no,

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

inline fn gateway_url(self: ?*Self) []const u8 {
    // wtf is this?
    if (self) |s| {
        return s.resume_gateway_url orelse s.info.url;
    }

    return "wss://gateway.discord.gg";
}

// identifies in order to connect to Discord and get the online status, this shall be done on hello perhaps
fn identify(self: *Self) !void {
    self.logif("intents: {d}", .{self.intents.toRaw()});
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

const Log = union(enum) { yes, no };

// asks /gateway/bot initializes both the ws client and the http client
pub fn init(allocator: mem.Allocator, args: struct {
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

    conn.handshake("/?v=10&encoding=json&compress=zlib-stream", .{
        .timeout_ms = 1000,
        .headers = "host: gateway.discord.gg",
    }) catch unreachable;

    return conn;
}

pub fn deinit(self: *Self) void {
    self.client.deinit();
    self.logif("killing the whole bot\n", .{});
}

pub fn ensureCompressed(data: []const u8, comptime pattern: []const u8) bool {
    if (data.len < pattern.len) {
        return false;
    }

    const start_index: usize = data.len - pattern.len;

    for (0..pattern.len) |i| {
        if (data[start_index + i] != pattern[i]) return false;
    }
    return true;
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

        if (!Self.ensureCompressed(msg.data, &[4]u8{ 0x00, 0x00, 0xFF, 0xFF }))
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
                    const helloPayload = parsed.value;

                    // PARSE NEW URL IN READY

                    self.heart = Heart{
                        // TODO: fix bug
                        .heartbeatInterval = helloPayload.heartbeat_interval,
                        .ack = false,
                        .lastBeat = 0,
                    };

                    self.logif("starting heart beater. seconds:{d}...\n", .{self.heart.heartbeatInterval});

                    try self.heartbeat();

                    var prng = std.Random.DefaultPrng.init(0);
                    const jitter = std.Random.float(prng.random(), f64);

                    const thread = try std.Thread.spawn(.{}, Self.heartbeat_wait, .{ self, jitter });
                    thread.detach();

                    if (self.resumable()) {
                        try self.resume_();
                        return;
                    } else {
                        try self.identify();
                    }
                }
            },
            Opcode.HeartbeatACK => {
                // perhaps this needs a mutex?
                self.logif("got heartbeat ack\n", .{});

                self.mutex.lock();
                defer self.mutex.unlock();

                self.heart.ack = true;
            },
            Opcode.Heartbeat => {
                self.logif("sending requested heartbeat\n", .{});
                try self.heartbeat();
            },
            Opcode.Reconnect => {
                self.logif("reconnecting\n", .{});
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
        self.logif("zzz for {d}\n", .{self.heart.heartbeatInterval});
        std.Thread.sleep(std.time.ns_per_ms * self.heart.heartbeatInterval);
    } else {
        const timeout = @as(f64, @floatFromInt(self.heart.heartbeatInterval)) * jitter;
        self.logif("zzz for {d} and jitter {d}\n", .{ @as(u64, @intFromFloat(timeout)), jitter });
        std.Thread.sleep(std.time.ns_per_ms * @as(u64, @intFromFloat(timeout)));
    }

    self.logif(">> ♥ and ack received: {}\n", .{self.heart.ack});

    if (self.heart.ack) {
        self.logif("sending unrequested heartbeat\n", .{});
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

    try self.client.write(string.items);
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
    const attempt = try self.parseJson(payload);
    if (std.ascii.eqlIgnoreCase(name, "message_create")) {
        const obj = attempt.getT(.object, "d").?;
        const author_obj = obj.getT(.object, "author").?;
        const member_obj = obj.getT(.object, "member").?;
        const avatar_decoration_data_obj = author_obj.getT(.object, "avatar_decoration_data");
        const avatar_decoration_data_member_obj = author_obj.getT(.object, "avatar_decoration_data");
        const mentions_obj = obj.getT(.array, "mentions").?;
        var mentions = std.ArrayList(Discord.User).init(self.allocator);

        while (mentions_obj.iterator().next()) |m| {
            const avatar_decoration_data_mention_obj = m.getT(.object, "avatar_decoration_data");
            try mentions.append(Discord.User{
                .id = m.getT(.string, "id").?,
                .bot = m.getT(.boolean, "bot") orelse false,
                .username = m.getT(.string, "username").?,
                .accent_color = if (m.getT(.integer, "accent_color")) |ac| @as(isize, @intCast(ac)) else null,
                // note: for selfbots this can be typed with an enu.?,
                .flags = if (m.getT(.integer, "flags")) |fs| @as(isize, @intCast(fs)) else null,
                // also for selfbot.?,
                .email = m.getT(.string, "email"),
                .avatar = m.getT(.string, "avatar"),
                .locale = m.getT(.string, "locale"),
                .system = m.getT(.boolean, "system"),
                .banner = m.getT(.string, "banner"),
                .verified = m.getT(.boolean, "verified"),
                .global_name = m.getT(.string, "global_name"),
                .mfa_enabled = m.getT(.boolean, "mfa_enabled"),
                .public_flags = if (m.getT(.integer, "public_flags")) |pfs| @as(isize, @intCast(pfs)) else null,
                .premium_type = if (m.getT(.integer, "premium_type")) |pfs| @as(Discord.PremiumTypes, @enumFromInt(pfs)) else null,
                .discriminator = m.getT(.string, "discriminator").?,
                .avatar_decoration_data = if (avatar_decoration_data_mention_obj) |addm| Discord.AvatarDecorationData{
                    .asset = addm.getT(.string, "asset").?,
                    .sku_id = addm.getT(.string, "sku_id").?,
                } else null,
            });
        }

        const member = Discord.Member{
            .deaf = member_obj.getT(.boolean, "deaf"),
            .mute = member_obj.getT(.boolean, "mute"),
            .pending = member_obj.getT(.boolean, "pending"),
            .user = null,
            .nick = member_obj.getT(.string, "nick"),
            .avatar = member_obj.getT(.string, "avatar"),
            .roles = &[0][]const u8{},
            .joined_at = member_obj.getT(.string, "joined_at").?,
            .premium_since = member_obj.getT(.string, "premium_since"),
            .permissions = member_obj.getT(.string, "permissions"),
            .communication_disabled_until = member_obj.getT(.string, "communication_disabled_until"),
            .flags = @as(isize, @intCast(member_obj.getT(.integer, "flags").?)),
            .avatar_decoration_data = if (avatar_decoration_data_member_obj) |addm| Discord.AvatarDecorationData{
                .asset = addm.getT(.string, "asset").?,
                .sku_id = addm.getT(.string, "sku_id").?,
            } else null,
        };

        const author = Discord.User{
            .id = author_obj.getT(.string, "id").?,
            .bot = author_obj.getT(.boolean, "bot") orelse false,
            .username = author_obj.getT(.string, "username").?,
            .accent_color = if (author_obj.getT(.integer, "accent_color")) |ac| @as(isize, @intCast(ac)) else null,
            // note: for selfbots this can be typed with an enu.?,
            .flags = if (author_obj.getT(.integer, "flags")) |fs| @as(isize, @intCast(fs)) else null,
            // also for selfbot.?,
            .email = author_obj.getT(.string, "email"),
            .avatar = author_obj.getT(.string, "avatar"),
            .locale = author_obj.getT(.string, "locale"),
            .system = author_obj.getT(.boolean, "system"),
            .banner = author_obj.getT(.string, "banner"),
            .verified = author_obj.getT(.boolean, "verified"),
            .global_name = author_obj.getT(.string, "global_name"),
            .mfa_enabled = author_obj.getT(.boolean, "mfa_enabled"),
            .public_flags = if (author_obj.getT(.integer, "public_flags")) |pfs| @as(isize, @intCast(pfs)) else null,
            .premium_type = if (author_obj.getT(.integer, "premium_type")) |pfs| @as(Discord.PremiumTypes, @enumFromInt(pfs)) else null,
            .discriminator = author_obj.getT(.string, "discriminator").?,
            .avatar_decoration_data = if (avatar_decoration_data_obj) |add| Discord.AvatarDecorationData{
                .asset = add.getT(.string, "asset").?,
                .sku_id = add.getT(.string, "sku_id").?,
            } else null,
        };

        const m = Discord.Message{
            // the id
            .id = obj.getT(.string, "id").?,
            .tts = obj.getT(.boolean, "tts").?,
            .mention_everyone = obj.getT(.boolean, "mention_everyone").?,
            .pinned = obj.getT(.boolean, "pinned").?,
            .type = @as(Discord.MessageTypes, @enumFromInt(obj.getT(.integer, "type").?)),
            .channel_id = obj.getT(.string, "channel_id").?,
            .author = author,
            .member = member,
            .content = obj.getT(.string, "content"),
            .timestamp = obj.getT(.string, "timestamp").?,
            .guild_id = obj.getT(.string, "guild_id"),
            .attachments = &[0]Discord.Attachment{},
            .edited_timestamp = null,
            .mentions = mentions.items,
            .mention_roles = &[0]?[]const u8{},
            .mention_channels = &[0]?Discord.ChannelMention{},
            .embeds = &[0]Discord.Embed{},
            .reactions = &[0]?Discord.Reaction{},
            .nonce = .{ .string = obj.getT(.string, "nonce").? },
            .webhook_id = obj.getT(.string, "webhook_id"),
            .activity = null,
            .application = null,
            .application_id = obj.getT(.string, "application_id"),
            .message_reference = null,
            .flags = if (obj.getT(.integer, "flags")) |fs| @as(Discord.MessageFlags, @bitCast(@as(u15, @intCast(fs)))) else null,
            .stickers = &[0]?Discord.Sticker{},
            .referenced_message = null,
            .message_snapshots = &[0]?Discord.MessageSnapshot{},
            .interaction_metadata = null,
            .interaction = null,
            .thread = null,
            .components = null,
            .sticker_items = &[0]?Discord.StickerItem{},
            .position = if (obj.getT(.integer, "position")) |p| @as(isize, @intCast(p)) else null,
            .poll = null,
            .call = null,
        };

        @call(.auto, self.handler.message_create, .{m});
    } else {}
}

inline fn logif(self: *Self, comptime format: []const u8, args: anytype) void {
    switch (self.log) {
        .yes => debug.info(format, args),
        .no => {},
    }
}
