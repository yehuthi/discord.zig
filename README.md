# Discord.zig

A high-performance bleeding edge Discord library in Zig, featuring full API coverage, sharding support, and fine-tuned parsing
* Sharding Support: Ideal for large bots, enabling distributed load handling.
* 100% API Coverage & Fully Typed: Offers complete access to Discord's API with strict typing for reliable and safe code.
* High Performance: Faster than whichever library you can name (WIP)
* Flexible Payload Parsing: Supports payload parsing through both zlib and zstd*.
* Proper error handling

```zig
const std = @import("std");
const Discord = @import("discord.zig");
const Shard = Discord.Shard;
const Intents = Discord.Intents;

fn ready(_: *Shard, payload: Discord.Ready) !void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(session: *Shard, message: Discord.Message) !void {
    if (message.content) |mc| if (std.ascii.eqlIgnoreCase(mc, "!hi")) {
        var result = try session.sendMessage(message.channel_id, .{ .content = "discord.zig best lib" });
        defer result.deinit();

        switch (result.value) {
            .left => |e| std.debug.panic("Error: {d}\r{s}\n", .{ e.code, e.message }), // or you may tell the end user the error
            .right => |m| std.debug.print("Sent: {?s} sent by {s}\n", .{ m.content, m.author.username }),
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 9999 }){};
    var handler = Discord.init(gpa.allocator());
    try handler.start(.{
        .token = std.posix.getenv("TOKEN").?, // or your token
        .intents = Intents.fromRaw(53608447), // all intents
        .run = .{ .message_create = &message_create, .ready = &ready },
        .log = .yes,
        .options = .{},
    });
    errdefer handler.deinit();
}
```
## Installation
```zig
// In your build.zig file
const exe = b.addExecutable(.{
    .name = "marin",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});

const dzig = b.dependency("discord.zig", .{});

exe.root_module.addImport("discord.zig", dzig.module("discord.zig"));
```
TIP: make sure you use the latest Zig!

## contributing
Contributions are welcome! Please open an issue or pull request if you'd like to help improve the library.
* Support server: https://discord.gg/RBHkBt7nP5
* The original repo: https://codeberg.org/yuzu/discord.zig

## general roadmap
| Task                                                        | Status |
|-------------------------------------------------------------|--------|
| stablish good sharding support with buckets                 | ✅     |
| finish the event coverage roadmap                           | ✅     |
| proper error handling                                       | ✅     |
| use the priority queues for handling ratelimits (half done) | ❌     |
| make the library scalable with a gateway proxy              | ❌     |
| get a cool logo                                             | ❌     |

## missing events right now
| Event                                  | Support |
|----------------------------------------|---------|
| voice_channel_effect_send              | ❌      |
| voice_state_update                     | ❌      |
| voice_server_update                    | ❌      |

## http methods missing
| Endpoint                               | Support |
|----------------------------------------|---------|
| Audit log                              | ❌      |
| Automod                                | ❌      |
| Guild Scheduled Event related          | ❌      |
| Guild template related                 | ❌      |
| Soundboard related                     | ❌      |
| Stage Instance related                 | ❌      |
| Subscription related                   | ❌      |
| Voice related                          | ❌      |
| Webhook related                        | ❌      |
