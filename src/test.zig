//! ISC License
//!
//! Copyright (c) 2024-2025 Yuzu
//!
//! Permission to use, copy, modify, and/or distribute this software for any
//! purpose with or without fee is hereby granted, provided that the above
//! copyright notice and this permission notice appear in all copies.
//!
//! THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//! REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
//! AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
//! INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
//! LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
//! OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
//! PERFORMANCE OF THIS SOFTWARE.

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
        const msg = try session.sendMessage(message.channel_id, .{
            .content = "discord.zig best library",
        });
        defer msg.deinit();
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 9999 }){};
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
