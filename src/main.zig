const Handler = @import("discord.zig").Handler;
const Intents = @import("discord.zig").Intents;
const std = @import("std");

const TOKEN = "Bot MTI5ODgzOTgzMDY3OTEzMDE4OA.GNojts.iyblGKK0xTWU57QCG5n3hr2Be1whyylTGr44P0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        std.log.warn("Has leaked\n", .{});
    };
    const alloc = gpa.allocator();

    var handler = try Handler.init(alloc, .{ .token = TOKEN, .intents = Intents.fromRaw(513) });
    errdefer handler.deinit();

    const t = try std.Thread.spawn(.{}, Handler.readMessage, .{&handler});
    defer t.join();
}
