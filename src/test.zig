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

fn message_create(session: *Shard, message: Discord.Message) fmt.AllocPrintError!void {
    std.debug.print("captured: {?s} send by {s}\n", .{ message.content, message.author.username });

    if (message.content) |mc| if (std.ascii.eqlIgnoreCase(mc, "!hi")) {
        var req = FetchReq.init(session.allocator, session.details.token);
        defer req.deinit();

        const payload: Discord.Partial(Discord.CreateMessage) = .{ .content = "Hi, I'm hang man, your personal assistant" };
        const json = std.json.stringifyAlloc(session.allocator, payload, .{}) catch unreachable;
        defer session.allocator.free(json);
        const path = try fmt.allocPrint(session.allocator, "/channels/{d}/messages", .{message.channel_id.into()});

        _ = req.makeRequest(.POST, path, json) catch unreachable;
    };
}

fn message_reaction_add(_: *Shard, _: Discord.MessageReactionAdd) !void {}
fn guild_create(_: *Shard, guild: Discord.Guild) !void {
    std.debug.print("{any}\n", .{guild});
}

pub fn main() !void {
    var tsa = std.heap.ThreadSafeAllocator{ .child_allocator = std.heap.c_allocator };

    var handler = Discord.init(tsa.allocator());
    try handler.start(.{
        .token = std.posix.getenv("DISCORD_TOKEN").?,
        .intents = Intents.fromRaw(INTENTS),
        .run = .{ .message_create = &message_create, .ready = &ready, .message_reaction_add = &message_reaction_add },
        .log = .yes,
        .options = .{},
    });
    errdefer handler.deinit();
}
