# features
* supports sharding for large bots
* 100% API coverage, fully typed
* faster than any other Discord library
* language-agnostic (may be used with JavaScript)
* parses payloads using either zlib or zstd

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

## event coverage roadmap
* application_command_permissions_update | ❌
* auto_moderation_rule_create | ❌
* auto_moderation_rule_update | ❌
* auto_moderation_rule_delete | ❌
* auto_moderation_action_execution | ❌
* channel_create | ❌
* channel_update | ❌
* channel_delete | ❌
* channel_pins_update | ❌
* thread_create | ❌
* thread_update | ❌
* thread_delete | ❌
* thread_list_sync | ❌
* thread_member_update | ❌
* thread_members_update | ❌
* guild_audit_log_entry_create | ❌
* guild_create | ❌
* guild_update | ❌
* guild_delete | ❌
* guild_ban_add | ❌
* guild_ban_remove | ❌
* guild_emojis_update | ❌
* guild_stickers_update | ❌
* guild_integrations_update | ❌
* guild_member_add | ❌
* guild_member_remove | ❌ 
* guild_member_update | ❌
* guild_members_chunk | ❌
* guild_role_create | ❌
* guild_role_update | ❌
* guild_role_delete | ❌
* guild_scheduled_event_create | ❌
* guild_scheduled_event_update | ❌
* guild_scheduled_event_delete | ❌
* guild_scheduled_event_user_add | ❌
* guild_scheduled_event_user_remove | ❌
* integration_create | ❌
* integration_update | ❌
* integration_delete | ❌
* interaction_create | ❌
* invite_create | ❌
* invite_delete | ❌
* message_create: ?*const fn (message: Discord.Message) void | ✅
* message_update: ?*const fn (message: Discord.Message) void = undefined,
* message_delete: ?*const fn (message: Discord.MessageDelete) void = undefined,
* message_delete_bulk: ?*const fn (message: Discord.MessageDelete) void = undefined,
* message_reaction_add | ❌
* message_reaction_remove | ❌
* message_reaction_remove_all | ❌
* message_reaction_remove_emoji | ❌
* presence_update | ❌
* stage_instance_create | ❌
* stage_instance_update | ❌
* stage_instance_delete | ❌
* typing_start | ❌
* user_update | ❌
* voice_channel_effect_send | ❌
* voice_state_update | ❌
* voice_server_update | ❌
* webhooks_update | ❌
* entitlement_create | ❌
* entitlement_update | ❌
* entitlement_delete | ❌
* message_poll_vote_add | ❌
* message_poll_vote_remove | ❌
* ready: ?*const fn (data: Discord.Ready) void | ✅
* resumed | ❌
* any: ?*const fn (data: []u8) void | ✅

