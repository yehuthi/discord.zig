
# commands to run
```bash
wget https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.gz
tar xvf zlib-1.2.13.tar.gz
rm zlib-1.2.13.tar.gz
mv zlib-1.2.13 zlib
mv zlib lib/zlib
git clone https://github.com/yuzudev/websocket.zig.git ./lib/websocket.zig/
git clone https://github.com/yuzudev/zig-tls12 ./lib/zig-tls12/
git clone https://github.com/jetzig-framework/zmpl.git ./lib/zmpl/
```
or simply run ./install.sh

# features
* idk man

```zig
// Sample code
const Session = @import("discord.zig").Session;
const Discord = @import("discord.zig").Discord;
const Intents = Discord.Intents;
const std = @import("std");

const token = "Bot MTI5ODgzOTgzMDY3OTEzMDE4OA...";

fn message_create(message: Discord.Message) void {
    // do whatever you want
    std.debug.print("captured: {?s}\n", .{message.content});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var handler = try Session.init(allocator, .{
        .token = token,
        .intents = Intents.fromRaw(37379),
        .run = Session.GatewayDispatchEvent{ .message_create = &message_create },
    });
    errdefer handler.deinit();

    const t = try std.Thread.spawn(.{}, Session.readMessage, .{ &handler, null });
    defer t.join();
}
```
