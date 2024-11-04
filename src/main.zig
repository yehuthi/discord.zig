const Session = @import("shard.zig");
const Discord = @import("types.zig");
const Intents = Discord.Intents;
const std = @import("std");
const Thread = std.Thread;
const token = "Bot MTI5ODgzOTgzMDY3OTEzMDE4OA.GNojts.iyblGKK0xTWU57QCG5n3hr2Be1whyylTGr44P0";

fn ready(payload: Discord.Ready) void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(message: Discord.Message) void {
    std.debug.print("captured: {?s} send by {s}\n", .{ message.content, message.author.username });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var handler = try Session.init(allocator, .{
        .token = token,
        .intents = Intents.fromRaw(37379),
        .run = Session.GatewayDispatchEvent{
            .message_create = &message_create,
            .ready = &ready,
        },
        .log = .yes,
    });
    errdefer handler.deinit();

    const t = try Thread.spawn(.{}, Session.readMessage, .{ &handler, null });
    defer t.join();
}
