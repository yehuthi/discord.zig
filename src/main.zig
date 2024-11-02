const Session = @import("discord.zig");
const Intents = @import("raw_types.zig").Intents;
const Discord = @import("raw_types.zig");
const std = @import("std");

const TOKEN = "Bot MTI5ODgzOTgzMDY3OTEzMDE4OA.GNojts.iyblGKK0xTWU57QCG5n3hr2Be1whyylTGr44P0";

fn message_create(message: Discord.Message) void {
    std.debug.print("captured: {?s}\n", .{message.content});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var handler = try Session.init(allocator, .{
        .token = TOKEN,
        .intents = Intents.fromRaw(37379),
        .run = Session.GatewayDispatchEvent{ .message_create = &message_create },
    });
    errdefer handler.deinit();

    const t = try std.Thread.spawn(.{}, Session.readMessage, .{ &handler, null });
    defer t.join();
}

test "." {
    _ = @import("types.zig");
}
