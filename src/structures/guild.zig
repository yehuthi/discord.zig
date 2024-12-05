const Snowflake = @import("snowflake.zig").Snowflake;
const VerificationLevels = @import("shared.zig").VerificationLevels;
const DefaultMessageNotificationLevels = @import("shared.zig").DefaultMessageNotificationLevels;
const ExplicitContentFilterLevels = @import("shared.zig").ExplicitContentFilterLevels;
const GuildFeatures = @import("shared.zig").GuildFeatures;
const GuildNsfwLevel = @import("shared.zig").GuildNsfwLevel;
const Role = @import("role.zig").Role;
const MemberWithUser = @import("member.zig").MemberWithUser;
const Member = @import("member.zig").Member;
const Channel = @import("channel.zig").Channel;
const MfaLevels = @import("shared.zig").MfaLevels;
const SystemChannelFlags = @import("shared.zig").SystemChannelFlags;
const PremiumTiers = @import("shared.zig").PremiumTiers;
const Emoji = @import("emoji.zig").Emoji;
const Sticker = @import("message.zig").Sticker;
const Partial = @import("partial.zig").Partial;
const PresenceUpdate = @import("gateway.zig").PresenceUpdate;
const WelcomeScreen = @import("channel.zig").WelcomeScreen;
const StageInstance = @import("channel.zig").StageInstance;

/// https://discord.com/developers/docs/resources/guild#guild-object
pub const Guild = struct {
    /// Guild name (2-100 characters, excluding trailing and leading whitespace)
    name: []const u8,
    /// True if the user is the owner of the guild
    owner: ?bool,
    /// Afk timeout in seconds
    afk_timeout: isize,
    /// True if the server widget is enabled
    widget_enabled: ?bool,
    /// Verification level required for the guild
    verification_level: VerificationLevels,
    /// Default message notifications level
    default_message_notifications: DefaultMessageNotificationLevels,
    /// Explicit content filter level
    explicit_content_filter: ExplicitContentFilterLevels,
    /// Enabled guild features
    features: []GuildFeatures,
    /// Required MFA level for the guild
    mfa_level: MfaLevels,
    /// System channel flags
    system_channel_flags: SystemChannelFlags,
    /// True if this is considered a large guild
    large: ?bool,
    /// True if this guild is unavailable due to an outage
    unavailable: ?bool,
    /// Total isize of members in this guild
    member_count: ?isize,
    /// The maximum isize of presences for the guild (the default value, currently 25000, is in effect when null is returned)
    max_presences: ?isize,
    /// The maximum isize of members for the guild
    max_members: ?isize,
    /// The vanity url code for the guild
    vanity_url_code: ?[]const u8,
    /// The description of a guild
    description: ?[]const u8,
    /// Premium tier (Server Boost level)
    premium_tier: PremiumTiers,
    /// The isize of boosts this guild currently has
    premium_subscription_count: ?isize,
    /// The maximum amount of users in a video channel
    max_video_channel_users: ?isize,
    /// Maximum amount of users in a stage video channel
    max_stage_video_channel_users: ?isize,
    /// Approximate isize of members in this guild, returned from the GET /guilds/id endpoint when with_counts is true
    approximate_member_count: ?isize,
    /// Approximate isize of non-offline members in this guild, returned from the GET /guilds/id endpoint when with_counts is true
    approximate_presence_count: ?isize,
    /// Guild NSFW level
    nsfw_level: GuildNsfwLevel,
    /// Whether the guild has the boost progress bar enabled
    premium_progress_bar_enabled: bool,
    /// Guild id
    id: Snowflake,
    /// Icon hash
    icon: ?[]const u8,
    /// Icon hash, returned when in the template object
    icon_hash: ?[]const u8,
    /// Splash hash
    splash: ?[]const u8,
    /// Discovery splash hash; only present for guilds with the "DISCOVERABLE" feature
    discovery_splash: ?[]const u8,
    /// Id of the owner
    owner_id: Snowflake,
    /// Total permissions for the user in the guild (excludes overwrites and implicit permissions)
    permissions: ?[]const u8,
    /// Id of afk channel
    afk_channel_id: ?Snowflake,
    /// The channel id that the widget will generate an invite to, or null if set to no invite
    widget_channel_id: ?Snowflake,
    /// Roles in the guild
    roles: []Role,
    /// Custom guild emojis
    emojis: []Emoji,
    /// Application id of the guild creator if it is bot-created
    application_id: ?Snowflake,
    /// The id of the channel where guild notices such as welcome messages and boost events are posted
    system_channel_id: ?Snowflake,
    /// The id of the channel where community guilds can display rules and/or guidelines
    rules_channel_id: ?Snowflake,
    /// When this guild was joined at
    joined_at: ?[]const u8,
    // States of members currently in voice channels; lacks the guild_id key
    // voice_states: ?[]Omit(VoiceState, .{"guildId"}),
    /// Users in the guild
    members: ?[]Member,
    /// Channels in the guild
    channels: ?[]Channel,
    /// All active threads in the guild that the current user has permission to view
    threads: ?[]Channel,
    /// Presences of the members in the guild, will only include non-offline members if the size is greater than large threshold
    presences: ?[]Partial(PresenceUpdate),
    /// Banner hash
    banner: ?[]const u8,
    ///The preferred locale of a Community guild; used in server discovery and notices from ; defaults to "en-US"
    preferred_locale: []const u8,
    ///The id of the channel where admins and moderators of Community guilds receive notices from
    public_updates_channel_id: ?Snowflake,
    /// The welcome screen of a Community guild, shown to new members, returned in an Invite's guild object
    welcome_screen: ?WelcomeScreen,
    /// Stage instances in the guild
    stage_instances: ?[]StageInstance,
    /// Custom guild stickers
    stickers: ?[]Sticker,
    ///The id of the channel where admins and moderators of Community guilds receive safety alerts from
    safety_alerts_channel_id: ?Snowflake,
};

/// https://discord.com/developers/docs/resources/voice#voice-state-object-voice-state-structure
pub const VoiceState = struct {
    /// The session id for this voice state
    session_id: []const u8,
    /// The guild id this voice state is for
    guild_id: ?Snowflake,
    /// The channel id this user is connected to
    channel_id: ?Snowflake,
    /// The user id this voice state is for
    user_id: Snowflake,
    /// The guild member this voice state is for
    member: ?MemberWithUser,
    /// Whether this user is deafened by the server
    deaf: bool,
    /// Whether this user is muted by the server
    mute: bool,
    /// Whether this user is locally deafened
    self_deaf: bool,
    /// Whether this user is locally muted
    self_mute: bool,
    /// Whether this user is streaming using "Go Live"
    self_stream: ?bool,
    /// Whether this user's camera is enabled
    self_video: bool,
    /// Whether this user is muted by the current user
    suppress: bool,
    /// The time at which the user requested to speak
    request_to_speak_timestamp: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/guild#get-guild-widget-example-get-guild-widget
pub const GuildWidget = struct {
    id: Snowflake,
    name: []const u8,
    instant_invite: []const u8,
    channels: []struct {
        id: Snowflake,
        name: []const u8,
        position: isize,
    },
    members: []struct {
        id: Snowflake,
        username: []const u8,
        discriminator: []const u8,
        avatar: ?[]const u8,
        status: []const u8,
        avatar_url: []const u8,
    },
    presence_count: isize,
};

/// https://discord.com/developers/docs/resources/guild#guild-preview-object
pub const GuildPreview = struct {
    /// Guild id
    id: Snowflake,
    /// Guild name (2-100 characters)
    name: []const u8,
    /// Icon hash
    icon: ?[]const u8,
    /// Splash hash
    splash: ?[]const u8,
    /// Discovery splash hash
    discovery_splash: ?[]const u8,
    /// Custom guild emojis
    emojis: []Emoji,
    /// Enabled guild features
    features: []GuildFeatures,
    /// Approximate isize of members in this guild
    approximate_member_count: isize,
    /// Approximate isize of online members in this guild
    approximate_presence_count: isize,
    /// The description for the guild, if the guild is discoverable
    description: ?[]const u8,
    /// Custom guild stickers
    stickers: []Sticker,
};
