const Session = @import("discord.zig");
const Message = @import("types.zig").Message;
const std = @import("std");

const TOKEN = "Bot MTI5ODgzOTgzMDY3OTEzMDE4OA.GNojts.iyblGKK0xTWU57QCG5n3hr2Be1whyylTGr44P0";

fn message_create(data: Message) void {
    std.debug.print("Event:{s}", .{data.content});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        std.log.warn("Has leaked\n", .{});
    };
    const alloc = gpa.allocator();

    var handler = try Session.init(alloc, .{
        .token = TOKEN,
        .intents = Session.Intents.fromRaw(513),
        .run = Session.GatewayDispatchEvent{ .message_create = &message_create },
    });
    errdefer handler.deinit();

    const t = try std.Thread.spawn(.{}, Session.readMessage, .{ &handler, null });
    defer t.join();
}

test "." {
    _ = @import("types.zig");
}
