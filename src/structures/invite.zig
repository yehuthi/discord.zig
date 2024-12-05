const Snowflake = @import("snowflake.zig").Snowflake;
const User = @import("user.zig").User;
const Guild = @import("guild.zig").Guild;
const Channel = @import("channel.zig").Channel;
const Member = @import("member.zig").Member;
const Application = @import("application.zig").Application;
const MessageActivityTypes = @import("shared.zig").MessageActivityTypes;
const ScheduledEvent = @import("scheduled_event.zig").ScheduledEvent;
const TargetTypes = @import("shared.zig").TargetTypes;
const Partial = @import("partial.zig").Partial;

/// https://discord.com/developers/docs/resources/invite#invite-metadata-object
pub const InviteMetadata = struct {
    /// The type of invite
    type: InviteType,
    /// The invite code (unique Id)
    code: []const u8,
    /// The guild this invite is for
    guild: ?Partial(Guild),
    /// The channel this invite is for
    channel: ?Partial(Channel),
    /// The user who created the invite
    inviter: ?User,
    /// The type of target for this voice channel invite
    target_type: ?TargetTypes,
    /// The target user for this invite
    target_user: ?User,
    /// The embedded application to open for this voice channel embedded application invite
    target_application: ?Partial(Application),
    /// Approximate count of online members (only present when target_user is set)
    approximate_presence_count: ?isize,
    /// Approximate count of total members
    approximate_member_count: ?isize,
    /// The expiration date of this invite, returned from the `GET /invites/<code>` endpoint when `with_expiration` is `true`
    expires_at: ?[]const u8,
    /// Stage instance data if there is a public Stage instance in the Stage channel this invite is for
    stage_instance: ?InviteStageInstance,
    /// guild scheduled event data
    guild_scheduled_event: ?ScheduledEvent,
    /// isize of times this invite has been used
    uses: isize,
    /// Max isize of times this invite can be used
    max_uses: isize,
    /// Duration (in seconds) after which the invite expires
    max_age: isize,
    /// Whether this invite only grants temporary membership
    temporary: bool,
    /// When this invite was created
    created_at: []const u8,
};

/// https://discord.com/developers/docs/resources/invite#invite-object
pub const Invite = struct {
    /// The type of invite
    type: InviteType,
    /// The invite code (unique Id)
    code: []const u8,
    /// The guild this invite is for
    guild: ?Partial(Guild),
    /// The channel this invite is for
    channel: ?Partial(Channel),
    /// The user who created the invite
    inviter: ?User,
    /// The type of target for this voice channel invite
    target_type: ?TargetTypes,
    /// The target user for this invite
    target_user: ?User,
    /// The embedded application to open for this voice channel embedded application invite
    target_application: ?Partial(Application),
    /// Approximate count of online members (only present when target_user is set)
    approximate_presence_count: ?isize,
    /// Approximate count of total members
    approximate_member_count: ?isize,
    /// The expiration date of this invite, returned from the `GET /invites/<code>` endpoint when `with_expiration` is `true`
    expires_at: ?[]const u8,
    /// Stage instance data if there is a public Stage instance in the Stage channel this invite is for
    stage_instance: ?InviteStageInstance,
    /// guild scheduled event data
    guild_scheduled_event: ?ScheduledEvent,
};

pub const InviteType = enum {
    Guild,
    GroupDm,
    Friend,
};

pub const InviteStageInstance = struct {
    /// The members speaking in the Stage
    members: []Partial(Member),
    /// The isize of users in the Stage
    participant_count: isize,
    /// The isize of users speaking in the Stage
    speaker_count: isize,
    /// The topic of the Stage instance (1-120 characters)
    topic: []const u8,
};
