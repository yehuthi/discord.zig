const Snowflake = @import("snowflake.zig").Snowflake;
const TeamMembershipStates = @import("shared.zig").TeamMembershipStates;

/// https://discord.com/developers/docs/topics/teams#data-models-team-object
pub const Team = struct {
    /// Hash of the image of the team's icon
    icon: ?[]const u8,
    /// Unique ID of the team
    id: Snowflake,
    /// Members of the team
    members: []TeamMember,
    /// User ID of the current team owner
    owner_user_id: Snowflake,
    /// Name of the team
    name: []const u8,
};

/// https://discord.com/developers/docs/topics/teams#data-models-team-members-object
pub const TeamMember = struct {
    /// The user's membership state on the team
    membership_state: TeamMembershipStates,
    /// The id of the parent team of which they are a member
    team_id: Snowflake,
    /// The avatar, discriminator, id, username, and global_name of the user
    /// TODO: needs fixing
    user: struct {
        /// Unique ID of the user
        id: Snowflake,
        /// The user's username, not unique across the platform
        username: []const u8,
        /// The user's display name, if it is set. For bots, this is the application name
        global_name: []const u8,
        /// The user's discord-tag
        discriminator: []const u8,
        /// The user's avatar hash
        avatar: []const u8,
    },
};
