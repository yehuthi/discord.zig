const Shard = @import("discord.zig").Shard;
const Discord = @import("discord.zig").Discord;
const Intents = Discord.Intents;
const Thread = std.Thread;
const std = @import("std");

fn ready(payload: Discord.Ready) void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(message: Discord.Message) void {
    std.debug.print("captured: {?s} send by {s}\n", .{ message.content, message.author.username });
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const token = std.posix.getenv("TOKEN") orelse unreachable;

    var handler = try Shard.login(allocator, .{
        .token = token,
        .intents = Intents.fromRaw(37379),
        .run = Shard.GatewayDispatchEvent{
            .message_create = &message_create,
            .ready = &ready,
        },
        .log = .yes,
    });
    errdefer handler.deinit();

    const t = try Thread.spawn(.{}, Shard.readMessage, .{ &handler, null });
    defer t.join();
}
