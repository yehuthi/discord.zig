const PremiumTypes = @import("shared.zig").PremiumTypes;
const Snowflake = @import("snowflake.zig").Snowflake;
const Application = @import("application.zig").Application;
const Record = @import("json").Record;
const OAuth2Scope = @import("shared.zig").OAuth2Scope;
const Integration = @import("integration.zig").Integration;
const Partial = @import("partial.zig").Partial;

/// https://discord.com/developers/docs/resources/user#user-object
pub const User = struct {
    /// The user's username, not unique across the platform
    username: []const u8,
    /// The user's display name, if it is set. For bots, this is the application name
    global_name: ?[]const u8,
    /// The user's chosen language option
    locale: ?[]const u8,
    /// The flags on a user's account
    flags: ?isize,
    /// The type of Nitro subscription on a user's account
    premium_type: ?PremiumTypes,
    /// The public flags on a user's account
    public_flags: ?isize,
    /// the user's banner color encoded as an integer representation of hexadecimal color code
    accent_color: ?isize,
    /// The user's id
    id: Snowflake,
    /// The user's discord-tag
    discriminator: []const u8,
    /// The user's avatar hash
    avatar: ?[]const u8,
    /// Whether the user belongs to an OAuth2 application
    bot: ?bool,
    ///Whether the user is an Official  System user (part of the urgent message system)
    system: ?bool,
    /// Whether the user has two factor enabled on their account
    mfa_enabled: ?bool,
    /// Whether the email on this account has been verified
    verified: ?bool,
    /// The user's email
    email: ?[]const u8,
    /// the user's banner, or null if unset
    banner: ?[]const u8,
    /// data for the user's avatar decoration
    avatar_decoration_data: ?AvatarDecorationData,
    clan: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/user#avatar-decoration-data-object
pub const AvatarDecorationData = struct {
    /// the avatar decoration hash
    asset: []const u8,
    /// id of the avatar decoration's SKU
    sku_id: Snowflake,
};

/// TODO: implement
pub const TokenExchange = null;

pub const TokenRevocation = struct {
    /// The access token to revoke
    token: []const u8,
    /// Optional, the type of token you are using for the revocation
    token_type_hint: ?"access_token' | 'refresh_token",
};

/// https://discord.com/developers/docs/topics/oauth2#get-current-authorization-information-response-structure
pub const CurrentAuthorization = struct {
    application: Application,
    /// the scopes the user has authorized the application for
    scopes: []OAuth2Scope,
    /// when the access token expires
    expires: []const u8,
    /// the user who has authorized, if the user has authorized with the `identify` scope
    user: ?User,
};

/// https://discord.com/developers/docs/resources/user#connection-object-connection-structure
pub const Connection = struct {
    /// id of the connection account
    id: Snowflake,
    /// the username of the connection account
    name: []const u8,
    /// the service of this connection
    type: ConnectionServiceType,
    /// whether the connection is revoked
    revoked: ?bool,
    /// an array of partial server integrations
    integrations: []?Partial(Integration),
    /// whether the connection is verified
    verified: bool,
    /// whether friend sync is enabled for this connection
    friend_sync: bool,
    /// whether activities related to this connection will be shown in presence updates
    show_activity: bool,
    /// whether this connection has a corresponding third party OAuth2 token
    two_way_link: bool,
    /// visibility of this connection
    visibility: ConnectionVisibility,
};

/// https://discord.com/developers/docs/resources/user#connection-object-services
pub const ConnectionServiceType = enum {
    @"amazon-music",
    battlenet,
    @"Bungie.net",
    domain,
    ebay,
    epicgames,
    facebook,
    github,
    instagram,
    leagueoflegends,
    paypal,
    playstation,
    reddit,
    riotgames,
    roblox,
    spotify,
    skype,
    steam,
    tiktok,
    twitch,
    twitter,
    xbox,
    youtube,
};

//https://discord.com/developers/docs/resources/user#connection-object-visibility-types
pub const ConnectionVisibility = enum(u4) {
    /// invisible to everyone except the user themselves
    None = 0,
    /// visible to everyone
    Everyone = 1,
};

/// https://discord.com/developers/docs/resources/user#application-role-connection-object-application-role-connection-structure
pub const ApplicationRoleConnection = struct {
    /// the vanity name of the platform a bot has connected (max 50 characters)
    platform_name: ?[]const u8,
    /// the username on the platform a bot has connected (max 100 characters)
    platform_username: ?[]const u8,
    /// object mapping application role connection metadata keys to their stringified value (max 100 characters) for the user on the platform a bot has connected
    metadata: []Record([]const u8),
};
