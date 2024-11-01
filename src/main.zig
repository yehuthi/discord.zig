const Session = @import("discord.zig");
const std = @import("std");

const TOKEN = "Bot MTI5ODgzOTgzMDY3OTEzMDE4OA.GNojts.iyblGKK0xTWU57QCG5n3hr2Be1whyylTGr44P0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        std.log.warn("Has leaked\n", .{});
    };
    const alloc = gpa.allocator();

    var handler = try Session.init(alloc, .{ .token = TOKEN, .intents = Session.Intents.fromRaw(513) });
    errdefer handler.deinit();

    const t = try std.Thread.spawn(.{}, Session.readMessage, .{&handler});
    defer t.join();
}

test "." {
    _ = @import("types.zig");
}
