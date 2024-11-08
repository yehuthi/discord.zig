const Shard = @import("discord.zig").Shard;
const Discord = @import("discord.zig").Discord;
const Internal = @import("discord.zig").Internal;
const Intents = Discord.Intents;
const Thread = std.Thread;
const std = @import("std");

fn ready(_: *Shard, payload: Discord.Ready) void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(session: *Shard, message: Discord.Message) void {
    std.debug.print("captured: {?s} send by {s}\n", .{ message.content, message.author.username });

    if (message.content) |mc| if (std.ascii.eqlIgnoreCase(mc, "!hi")) {
        var req = Shard.FetchReq.init(session.allocator, session.token);
        defer req.deinit();

        const payload: Discord.Partial(Discord.CreateMessage) = .{ .content = "Hi, I'm hang man, your personal assistant" };
        const json = std.json.stringifyAlloc(session.allocator, payload, .{}) catch unreachable;
        defer session.allocator.free(json);
        const path = std.fmt.allocPrint(session.allocator, "/channels/{d}/messages", .{message.channel_id.value()}) catch unreachable;

        _ = req.makeRequest(.POST, path, json) catch unreachable;
    };
}

pub fn main() !void {
    var tsa = std.heap.ThreadSafeAllocator{ .child_allocator = std.heap.c_allocator };

    var handler = try Shard.login(tsa.allocator(), .{
        .token = std.posix.getenv("TOKEN") orelse unreachable,
        .intents = Intents.fromRaw(37379),
        .run = Internal.GatewayDispatchEvent(*Shard){
            .message_create = &message_create,
            .ready = &ready,
        },
        .log = .yes,
    });
    errdefer handler.deinit();
}
