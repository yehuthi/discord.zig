const Discord = @import("discord.zig");
const Shard = Discord.Shard;
const Internal = Discord.Internal;
const FetchReq = Discord.FetchReq;
const Intents = Discord.Intents;
const Thread = std.Thread;
const std = @import("std");
const fmt = std.fmt;

const INTENTS = 53608447;

fn ready(_: *Shard, payload: Discord.Ready) !void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(session: *Shard, message: Discord.Message) !void {
    std.debug.print("captured: {?s} send by {s}\n", .{ message.content, message.author.username });

    if (message.content) |mc| if (std.ascii.eqlIgnoreCase(mc, "!hi")) {
        const payload: Discord.Partial(Discord.CreateMessage) = .{
            .content = "discord.zig best library",
        };
        _ = try session.sendMessage(message.channel_id, payload);
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var handler = Discord.init(gpa.allocator());
    try handler.start(.{
        .token = std.posix.getenv("DISCORD_TOKEN").?,
        .intents = Intents.fromRaw(INTENTS),
        .run = .{ .message_create = &message_create, .ready = &ready },
        .log = .yes,
        .options = .{},
    });
    errdefer handler.deinit();
}
