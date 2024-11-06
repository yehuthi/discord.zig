# Discord.zig

A high-performance bleeding edge Discord library in Zig, featuring full API coverage, sharding support, and fine-tuned parsing
* Sharding Support: Ideal for large bots, enabling distributed load handling.
* 100% API Coverage & Fully Typed: Offers complete access to Discord's API with strict typing for reliable and safe code.
* High Performance: Faster than whichever library you can name (WIP)
* Flexible Payload Parsing: Supports payload parsing through both zlib and zstd.
* Language Agnostic: Primarily in Zig, but also compatible with JavaScript. (PERHAPS?)

```zig
// Sample code
const Session = @import("discord.zig").Session;
const Discord = @import("discord.zig").Discord;
const Intents = Discord.Intents;
const std = @import("std");

const token = "Bot MTI5ODgzOTgzMDY3OTEzMDE4OA...";  // Replace with your actual token

fn message_create(message: Discord.Message) void {
    // Define your message handling logic here
    std.debug.print("Captured message: {?s}\n", .{message.content});
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

## event coverage roadmap
| Event                                  | Support |
|----------------------------------------|---------|
| application_command_permissions_update | ❌       |
| auto_moderation_rule_create            | ❌       |
| auto_moderation_rule_update            | ❌       |
| auto_moderation_rule_delete            | ❌       |
| auto_moderation_action_execution       | ❌       |
| channel_create                         | ❌       |
| channel_update                         | ❌       |
| channel_delete                         | ❌       |
| channel_pins_update                    | ❌       |
| thread_create                          | ❌       |
| thread_update                          | ❌       |
| thread_delete                          | ❌       |
| thread_list_sync                       | ❌       |
| thread_member_update                   | ❌       |
| thread_members_update                  | ❌       |
| guild_audit_log_entry_create           | ❌       |
| guild_create                           | ❌       |
| guild_update                           | ❌       |
| guild_delete                           | ❌       |
| guild_ban_add                          | ❌       |
| guild_ban_remove                       | ❌       |
| guild_emojis_update                    | ❌       |
| guild_stickers_update                  | ❌       |
| guild_integrations_update              | ❌       |
| guild_member_add                       | ❌       |
| guild_member_remove                    | ❌       |
| guild_member_update                    | ❌       |
| guild_members_chunk                    | ❌       |
| guild_role_create                      | ❌       |
| guild_role_update                      | ❌       |
| guild_role_delete                      | ❌       |
| guild_scheduled_event_create           | ❌       |
| guild_scheduled_event_update           | ❌       |
| guild_scheduled_event_delete           | ❌       |
| guild_scheduled_event_user_add         | ❌       |
| guild_scheduled_event_user_remove      | ❌       |
| integration_create                     | ❌       |
| integration_update                     | ❌       |
| integration_delete                     | ❌       |
| interaction_create                     | ❌       |
| invite_create                          | ❌       |
| invite_delete                          | ❌       |
| message_create: ?*const fn (message: Discord.Message) void | ✅ |
| message_update: ?*const fn (message: Discord.Message) void | ✅ |
| message_delete: ?*const fn (message: Discord.MessageDelete) void | ✅ |
| message_delete_bulk: ?*const fn (message: Discord.MessageDeleteBulk) void | ✅ |
| message_reaction_add                   | ❌       |
| message_reaction_remove                | ❌       |
| message_reaction_remove_all            | ❌       |
| message_reaction_remove_emoji          | ❌       |
| presence_update                        | ❌       |
| stage_instance_create                  | ❌       |
| stage_instance_update                  | ❌       |
| stage_instance_delete                  | ❌       |
| typing_start                           | ❌       |
| user_update                            | ❌       |
| voice_channel_effect_send              | ❌       |
| voice_state_update                     | ❌       |
| voice_server_update                    | ❌       |
| webhooks_update                        | ❌       |
| entitlement_create                     | ❌       |
| entitlement_update                     | ❌       |
| entitlement_delete                     | ❌       |
| message_poll_vote_add                  | ❌       |
| message_poll_vote_remove               | ❌       |
| ready: ?*const fn (data: Discord.Ready) void | ✅ |
| resumed                                | ❌       |
| any: ?*const fn (data: []const u8) void      | ✅ |

