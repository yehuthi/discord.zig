const Snowflake = @import("snowflake.zig").Snowflake;
const RoleFlags = @import("shared.zig").RoleFlags;

/// https://discord.com/developers/docs/topics/permissions#role-object-role-structure
pub const Role = struct {
    /// Role id
    id: Snowflake,
    /// If this role is showed separately in the user listing
    hoist: bool,
    /// Permission bit set
    permissions: []const u8,
    /// Whether this role is managed by an integration
    managed: bool,
    /// Whether this role is mentionable
    mentionable: bool,
    /// The tags this role has
    tags: ?RoleTags,
    /// the role emoji hash
    icon: ?[]const u8,
    /// Role name
    name: []const u8,
    /// Integer representation of hexadecimal color code
    color: isize,
    /// Position of this role (roles with the same position are sorted by id)
    position: isize,
    /// role unicode emoji
    unicode_emoji: ?[]const u8,
    /// Role flags combined as a bitfield
    flags: RoleFlags,
};

/// https://discord.com/developers/docs/topics/permissions#role-object-role-tags-structure
pub const RoleTags = struct {
    /// The id of the bot this role belongs to
    bot_id: ?Snowflake,
    /// The id of the integration this role belongs to
    integration_id: ?Snowflake,
    /// Whether this is the guild's premium subscriber role
    /// Tags with type ?bool represent booleans. They will be present and set to null if they are "true", and will be not present if they are "false".
    premium_subscriber: ?bool,
    /// Id of this role's subscription sku and listing.
    subscription_listing_id: ?Snowflake,
    /// Whether this role is available for purchase.
    /// Tags with type ?bool represent booleans. They will be present and set to null if they are "true", and will be not present if they are "false".
    available_for_purchase: ?bool,
    /// Whether this is a guild's linked role
    /// Tags with type ?bool represent booleans. They will be present and set to null if they are "true", and will be not present if they are "false".
    guild_connections: ?bool,
};

/// https://discord.com/developers/docs/resources/guild#create-guild-role
pub const CreateGuildRole = struct {
    /// Name of the role, max 100 characters, default: "new role"
    name: ?[]const u8,
    /// Bitwise value of the enabled/disabled permissions, default: everyone permissions in guild
    permissions: ?[][]const u8,
    /// RGB color value, default: 0
    color: ?isize,
    /// Whether the role should be displayed separately in the sidebar, default: false
    hoist: ?bool,
    /// Whether the role should be mentionable, default: false
    mentionable: ?bool,
    /// The role's unicode emoji (if the guild has the `ROLE_ICONS` feature)
    unicode_emoji: ?[]const u8,
    /// the role's icon image (if the guild has the `ROLE_ICONS` feature)
    icon: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/guild#modify-guild-role
pub const ModifyGuildRole = struct {
    /// Name of the role, max 100 characters, default: "new role"
    name: ?[]const u8,
    /// Bitwise value of the enabled/disabled permissions, default: everyone permissions in guild
    permissions: ?[][]const u8,
    /// RGB color value, default: 0
    color: ?isize,
    /// Whether the role should be displayed separately in the sidebar, default: false
    hoist: ?bool,
    /// Whether the role should be mentionable, default: false
    mentionable: ?bool,
    /// The role's unicode emoji (if the guild has the `ROLE_ICONS` feature)
    unicodeEmoji: ?[]const u8,
    /// the role's icon image (if the guild has the `ROLE_ICONS` feature)
    icon: ?[]const u8,
};
