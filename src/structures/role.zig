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
