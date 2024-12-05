const GatewayDispatchEventNames = @import("shared.zig").GatewayDispatchEventNames;

pub usingnamespace @import("shared.zig");
pub usingnamespace @import("partial.zig");
pub usingnamespace @import("snowflake.zig");
pub usingnamespace @import("events.zig");

pub usingnamespace @import("application.zig");
pub usingnamespace @import("attachment.zig");
pub usingnamespace @import("auditlog.zig");
pub usingnamespace @import("automod.zig");
pub usingnamespace @import("channel.zig");
pub usingnamespace @import("command.zig");
pub usingnamespace @import("embed.zig");
pub usingnamespace @import("emoji.zig");
pub usingnamespace @import("gateway.zig");
pub usingnamespace @import("guild.zig");
pub usingnamespace @import("integration.zig");
pub usingnamespace @import("integration.zig");
pub usingnamespace @import("invite.zig");
pub usingnamespace @import("member.zig");
pub usingnamespace @import("message.zig");
pub usingnamespace @import("monetization.zig");
pub usingnamespace @import("oauth.zig");
pub usingnamespace @import("poll.zig");
pub usingnamespace @import("role.zig");
pub usingnamespace @import("scheduled_event.zig");
pub usingnamespace @import("team.zig");
pub usingnamespace @import("thread.zig");
pub usingnamespace @import("user.zig");
pub usingnamespace @import("webhook.zig");

/// https://discord.com/developers/docs/topics/gateway#payloads-gateway-payload-structure
pub fn GatewayPayload(comptime T: type) type {
    return struct {
        /// opcode for the payload
        op: isize,
        /// Event data
        d: ?T,
        /// Sequence isize, used for resuming sessions and heartbeats
        s: ?isize,
        /// The event name for this payload
        t: ?[]const u8,
        // t: ?GatewayDispatchEventNames,
    };
}
