const User = @import("user.zig").User;
const AvatarDecorationData = @import("user.zig").AvatarDecorationData;

/// https://discord.com/developers/docs/resources/guild#guild-member-object
pub const Member = struct {
    /// Whether the user is deafened in voice channels
    deaf: ?bool,
    /// Whether the user is muted in voice channels
    mute: ?bool,
    /// Whether the user has not yet passed the guild's Membership Screening requirements
    pending: ?bool,
    /// The user this guild member represents
    user: ?User,
    /// This users guild nickname
    nick: ?[]const u8,
    /// The members custom avatar for this server.
    avatar: ?[]const u8,
    /// Array of role object ids
    roles: [][]const u8,
    /// When the user joined the guild
    joined_at: []const u8,
    /// When the user started boosting the guild
    premium_since: ?[]const u8,
    /// The permissions this member has in the guild. Only present on interaction events and OAuth2 current member fetch.
    permissions: ?[]const u8,
    /// when the user's timeout will expire and the user will be able to communicate in the guild again (set null to remove timeout), null or a time in the past if the user is not timed out
    communication_disabled_until: ?[]const u8,
    /// Guild member flags
    flags: isize,
    /// data for the member's guild avatar decoration
    avatar_decoration_data: ?AvatarDecorationData,
};

/// inherits
pub const MemberWithUser = struct {
    /// Whether the user is deafened in voice channels
    deaf: ?bool,
    /// Whether the user is muted in voice channels
    mute: ?bool,
    /// Whether the user has not yet passed the guild's Membership Screening requirements
    pending: ?bool,
    /// This users guild nickname
    nick: ?[]const u8,
    /// The members custom avatar for this server.
    avatar: ?[]const u8,
    /// Array of role object ids
    roles: [][]const u8,
    /// When the user joined the guild
    joined_at: []const u8,
    /// When the user started boosting the guild
    premium_since: ?[]const u8,
    /// The permissions this member has in the guild. Only present on interaction events and OAuth2 current member fetch.
    permissions: ?[]const u8,
    /// when the user's timeout will expire and the user will be able to communicate in the guild again (set null to remove timeout), null or a time in the past if the user is not timed out
    communication_disabled_until: ?[]const u8,
    /// Guild member flags
    flags: isize,
    /// data for the member's guild avatar decoration
    avatar_decoration_data: ?AvatarDecorationData,
    /// The user object for this member
    user: User,
};
