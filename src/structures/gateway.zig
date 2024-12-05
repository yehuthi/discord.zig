const User = @import("user.zig").User;
const Snowflake = @import("snowflake.zig").Snowflake;
const ActivityTypes = @import("shared.zig").ActivityTypes;

/// https://discord.com/developers/docs/topics/gateway#get-gateway-bot
pub const GetGatewayBot = struct {
    /// The WSS URL that can be used for connecting to the gateway
    url: []const u8,
    /// The recommended isize of shards to use when connecting
    shards: isize,
    /// Information on the current session start limit
    session_start_limit: SessionStartLimit,
};

/// https://discord.com/developers/docs/topics/gateway#session-start-limit-object
pub const SessionStartLimit = struct {
    /// The total isize of session starts the current user is allowed
    total: isize,
    /// The remaining isize of session starts the current user is allowed
    remaining: isize,
    /// The isize of milliseconds after which the limit resets
    reset_after: isize,
    /// The isize of identify requests allowed per 5 seconds
    max_concurrency: isize,
};

/// https://discord.com/developers/docs/topics/gateway#presence-update
pub const PresenceUpdate = struct {
    /// Either "idle", "dnd", "online", or "offline"
    status: union(enum) {
        idle,
        dnd,
        online,
        offline,
    },
    /// The user presence is being updated for
    user: User,
    /// id of the guild
    guild_id: Snowflake,
    /// User's current activities
    activities: []Activity,
    /// User's platform-dependent status
    client_status: ClientStatus,
};

/// https://discord.com/developers/docs/topics/gateway-events#activity-object
pub const Activity = struct {
    /// The activity's name
    name: []const u8,
    /// Activity type
    type: ActivityTypes,
    /// Stream url, is validated when type is 1
    url: ?[]const u8,
    /// Unix timestamp of when the activity was added to the user's session
    created_at: isize,
    /// What the player is currently doing
    details: ?[]const u8,
    /// The user's current party status
    state: ?[]const u8,
    /// Whether or not the activity is an instanced game session
    instance: ?bool,
    /// Activity flags `OR`d together, describes what the payload includes
    flags: ?isize,
    /// Unix timestamps for start and/or end of the game
    timestamps: ?ActivityTimestamps,
    /// Application id for the game
    application_id: ?Snowflake,
    /// The emoji used for a custom status
    emoji: ?ActivityEmoji,
    /// Information for the current party of the player
    party: ?ActivityParty,
    /// Images for the presence and their hover texts
    assets: ?ActivityAssets,
    /// Secrets for Rich Presence joining and spectating
    secrets: ?ActivitySecrets,
    /// The custom buttons shown in the Rich Presence (max 2)
    buttons: []?ActivityButton,
};

/// https://discord.com/developers/docs/resources/application#get-application-activity-instance-activity-instance-object
pub const ActivityInstance = struct {
    /// Application ID
    application_id: Snowflake,
    /// Activity Instance ID
    instance_id: Snowflake,
    /// Unique identifier for the launch
    launch_id: Snowflake,
    /// The Location the instance is runnning in
    location: ActivityLocation,
    /// The IDs of the Users currently connected to the instance
    users: [][]const u8,
};

/// https://discord.com/developers/docs/resources/application#get-application-activity-instance-activity-location-object
pub const ActivityLocation = struct {
    /// The unique identifier for the location
    id: Snowflake,
    /// Enum describing kind of location
    kind: ActivityLocationKind,
    /// The id of the Channel
    channel_id: Snowflake,
    /// The id of the Guild
    guild_id: ?Snowflake,
};

/// https://discord.com/developers/docs/resources/application#get-application-activity-instance-activity-location-kind-enum
pub const ActivityLocationKind = enum {
    /// The Location is a Guild Channel
    gc,
    /// The Location is a Private Channel, such as a DM or GDM
    pc,
};

/// https://discord.com/developers/docs/topics/gateway#client-status-object
pub const ClientStatus = struct {
    /// The user's status set for an active desktop (Windows, Linux, Mac) application session
    desktop: ?[]const u8,
    /// The user's status set for an active mobile (iOS, Android) application session
    mobile: ?[]const u8,
    /// The user's status set for an active web (browser, bot account) application session
    web: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway#activity-object-activity-timestamps
pub const ActivityTimestamps = struct {
    /// Unix time (in milliseconds) of when the activity started
    start: ?isize,
    /// Unix time (in milliseconds) of when the activity ends
    end: ?isize,
};

/// https://discord.com/developers/docs/topics/gateway#activity-object-activity-emoji
pub const ActivityEmoji = struct {
    /// The name of the emoji
    name: []const u8,
    /// Whether this emoji is animated
    animated: ?bool,
    /// The id of the emoji
    id: ?Snowflake,
};

/// https://discord.com/developers/docs/topics/gateway#activity-object-activity-party
pub const ActivityParty = struct {
    /// Used to show the party's current and maximum size
    size: ?[2]i64,
    /// The id of the party
    id: ?Snowflake,
};

/// https://discord.com/developers/docs/topics/gateway#activity-object-activity-assets
pub const ActivityAssets = struct {
    /// Text displayed when hovering over the large image of the activity
    large_text: ?[]const u8,
    /// Text displayed when hovering over the small image of the activity
    small_text: ?[]const u8,
    /// The id for a large asset of the activity, usually a snowflake
    large_image: ?[]const u8,
    /// The id for a small asset of the activity, usually a snowflake
    small_image: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway#activity-object-activity-secrets
pub const ActivitySecrets = struct {
    /// The secret for joining a party
    join: ?[]const u8,
    /// The secret for spectating a game
    spectate: ?[]const u8,
    /// The secret for a specific instanced match
    match: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway#activity-object-activity-buttons
pub const ActivityButton = struct {
    /// The text shown on the button (1-32 characters)
    label: []const u8,
    /// The url opened when clicking the button (1-512 characters)
    url: []const u8,
};
