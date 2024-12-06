const User = @import("user.zig").User;
const Snowflake = @import("snowflake.zig").Snowflake;
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

/// https://discord.com/developers/docs/resources/guild#add-guild-member-json-params
pub const AddGuildMember = struct {
    /// access token of a user that has granted your app the `guilds.join` scope
    access_token: []const u8,
    /// Value to set user's nickname to. Requires MANAGE_NICKNAMES permission on the bot
    nick: ?[]const u8,
    /// Array of role ids the member is assigned. Requires MANAGE_ROLES permission on the bot
    roles: ?[][]const u8,
    /// Whether the user is muted in voice channels. Requires MUTE_MEMBERS permission on the bot
    mute: ?bool,
    /// Whether the user is deafened in voice channels. Requires DEAFEN_MEMBERS permission on the bot
    deaf: ?bool,
};

/// https://discord.com/developers/docs/resources/guild#modify-guild-member
pub const ModifyGuildMember = struct {
    /// Value to set users nickname to. Requires the `MANAGE_NICKNAMES` permission
    nick: ?[]const u8,
    /// Array of role ids the member is assigned. Requires the `MANAGE_ROLES` permission
    roles: ?Snowflake,
    /// Whether the user is muted in voice channels. Will throw a 400 if the user is not in a voice channel. Requires the `MUTE_MEMBERS` permission
    mute: ?bool,
    /// Whether the user is deafened in voice channels. Will throw a 400 if the user is not in a voice channel. Requires the `MOVE_MEMBERS` permission
    deaf: ?bool,
    /// Id of channel to move user to (if they are connected to voice). Requires the `MOVE_MEMBERS` permission
    channel_id: ?Snowflake,
    /// When the user's timeout will expire and the user will be able to communicate in the guild again (up to 28 days in the future), set to null to remove timeout. Requires the `MODERATE_MEMBERS` permission. The date must be given in a ISO string form.
    communication_disabled_until: ?[]const u8,
    /// Set the flags for the guild member. Requires the `MANAGE_GUILD` or `MANAGE_ROLES` or the combination of `MODERATE_MEMBERS` and `KICK_MEMBERS` and `BAN_MEMBERS`
    flags: ?isize,
};
