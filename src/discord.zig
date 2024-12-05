pub usingnamespace @import("./structures/types.zig");
pub const Shard = @import("shard.zig");

pub const Internal = @import("internal.zig");
const GatewayDispatchEvent = Internal.GatewayDispatchEvent;
const GatewayBotInfo = Internal.GatewayBotInfo;
const Log = Internal.Log;

pub const Sharder = @import("core.zig");
const SessionOptions = Sharder.SessionOptions;

pub const FetchReq = @import("http.zig").FetchReq;

const std = @import("std");
const mem = std.mem;
const http = std.http;
const json = std.json;

const Self = @This();

allocator: mem.Allocator,
sharder: Sharder,

pub fn init(allocator: mem.Allocator) Self {
    return .{
        .allocator = allocator,
        .sharder = undefined,
    };
}

pub fn deinit(self: *Self) void {
    self.sharder.deinit();
}

pub fn start(self: *Self, settings: struct {
    token: []const u8,
    intents: Self.Intents,
    options: struct {
        spawn_shard_delay: u64 = 5300,
        total_shards: usize = 1,
        shard_start: usize = 0,
        shard_end: usize = 1,
    },
    run: GatewayDispatchEvent(*Shard),
    log: Log,
}) !void {
    var req = FetchReq.init(self.allocator, settings.token);
    defer req.deinit();

    const res = try req.makeRequest(.GET, "/gateway/bot", null);
    const body = try req.body.toOwnedSlice();
    defer self.allocator.free(body);

    // check status idk
    if (res.status != http.Status.ok) {
        @panic("we are cooked\n");
    }

    const parsed = try json.parseFromSlice(GatewayBotInfo, self.allocator, body, .{});
    defer parsed.deinit();

    self.sharder = try Sharder.init(self.allocator, .{
        .token = settings.token,
        .intents = settings.intents,
        .run = settings.run,
        .options = SessionOptions{
            .info = parsed.value,
            .shard_start = settings.options.shard_start,
            .shard_end = @intCast(parsed.value.shards),
            .total_shards = @intCast(parsed.value.shards),
            .spawn_shard_delay = settings.options.spawn_shard_delay,
        },
        .log = settings.log,
    });

    try self.sharder.spawnShards();
}
