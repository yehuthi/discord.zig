const Snowflake = @import("snowflake.zig").Snowflake;
const User = @import("user.zig").User;

/// https://discord.com/developers/docs/resources/emoji#emoji-object-emoji-structure
pub const Emoji = struct {
    /// Emoji name (can only be null in reaction emoji objects)
    name: ?[]const u8,
    /// Emoji id
    id: ?Snowflake,
    /// Roles allowed to use this emoji
    roles: []?[]const u8,
    /// User that created this emoji
    user: ?User,
    /// Whether this emoji must be wrapped in colons
    require_colons: ?bool,
    /// Whether this emoji is managed
    managed: ?bool,
    /// Whether this emoji is animated
    animated: ?bool,
    /// Whether this emoji can be used, may be false due to loss of Server Boosts
    available: ?bool,
};
