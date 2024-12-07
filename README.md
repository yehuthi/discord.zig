# Discord.zig

A high-performance bleeding edge Discord library in Zig, featuring full API coverage, sharding support, and fine-tuned parsing
* Sharding Support: Ideal for large bots, enabling distributed load handling.
* 100% API Coverage & Fully Typed: Offers complete access to Discord's API with strict typing for reliable and safe code.
* High Performance: Faster than whichever library you can name (WIP)
* Flexible Payload Parsing: Supports payload parsing through both zlib and zstd*.
* Language Agnostic: Primarily in Zig, but also compatible with JavaScript. (PERHAPS?)

```zig
const Client = @import("discord.zig").Client;
const Shard = @import("discord.zig").Shard;
const Discord = @import("discord.zig");
const Intents = Discord.Intents;
const std = @import("std");

fn ready(_: *Shard, payload: Discord.Ready) void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(_: *Shard, message: Discord.Message) void {
    std.debug.print("captured: {?s}\n", .{ message.content });
}

pub fn main() !void {
    var handler = Client.init(allocator);
    try handler.start(.{
        .token = std.posix.getenv("TOKEN") orelse unreachable,
        .intents = Intents.fromRaw(37379),
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
| Application related                    | ❌      |
| Audit log                              | ❌      |
| Automod                                | ❌      |
| Channel related                        | ✅      |
| Emoji related                          | ✅      |
| Entitlement related                    | ❌      |
| Guild related                          | ✅      |
| Guild Scheduled Event related          | ❌      |
| Guild template related                 | ❌      |
| Invite related                         | ✅      |
| Message related                        | ✅      |
| Poll related                           | ✅      |
| SKU related                            | ❌      |
| Soundboard related                     | ❌      |
| Stage Instance related                 | ❌      |
| Sticker related                        | ❌      |
| Subscription related                   | ❌      |
| User related                           | ✅      |
| Voice related                          | ❌      |
| Webhook related                        | ❌      |
