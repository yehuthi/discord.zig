const std = @import("std");
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;

pub fn Omit(comptime T: type, comptime field_names: anytype) type {
    const info = @typeInfo(T);
    switch (info) {
        .@"struct" => |s| {
            comptime var fields: []const std.builtin.Type.StructField = &[_]std.builtin.Type.StructField{};
            outer: inline for (s.fields) |field| {
                if (field.is_comptime) {
                    @compileError("Cannot make Omit of " ++ @typeName(T) ++ ", it has a comptime field " ++ field.name);
                }

                inline for (field_names) |lookup| {
                    if (std.mem.eql(u8, field.name, lookup)) {
                        continue :outer;
                    }
                }

                fields = fields ++ .{field};
            }
            const ti: std.builtin.Type = .{ .@"struct" = .{
                .backing_integer = s.backing_integer,
                .decls = &[_]std.builtin.Type.Declaration{},
                .fields = fields,
                .is_tuple = s.is_tuple,
                .layout = s.layout,
            } };
            return @Type(ti);
        },
        else => @compileError("Cannot make Omit of " ++ @typeName(T) ++
            ", the type must be a struct"),
    }
}

pub fn Partial(comptime T: type) type {
    const info = @typeInfo(T);
    switch (info) {
        .@"struct" => |s| {
            comptime var fields: []const std.builtin.Type.StructField = &[_]std.builtin.Type.StructField{};
            inline for (s.fields) |field| {
                if (field.is_comptime) {
                    @compileError("Cannot make Partial of " ++ @typeName(T) ++ ", it has a comptime field " ++ field.name);
                }
                const optional_type = switch (@typeInfo(field.type)) {
                    .optional => field.type,
                    else => ?field.type,
                };
                const default_value: optional_type = null;
                const aligned_ptr: *align(field.alignment) const anyopaque = @alignCast(@ptrCast(&default_value));
                const optional_field: [1]std.builtin.Type.StructField = [_]std.builtin.Type.StructField{.{
                    .alignment = field.alignment,
                    .default_value = aligned_ptr,
                    .is_comptime = false,
                    .name = field.name,
                    .type = optional_type,
                }};
                fields = fields ++ optional_field;
            }
            const partial_type_info: std.builtin.Type = .{ .@"struct" = .{
                .backing_integer = s.backing_integer,
                .decls = &[_]std.builtin.Type.Declaration{},
                .fields = fields,
                .is_tuple = s.is_tuple,
                .layout = s.layout,
            } };
            return @Type(partial_type_info);
        },
        else => @compileError("Cannot make Partial of " ++ @typeName(T) ++
            ", the type must be a struct"),
    }
    unreachable;
}

test "partial" {
    const PartialObject = Partial(struct {
        foo: []const u8,
        bar: ?[]const u8,
        baz: u32,
    });
    const part = PartialObject{};
    try std.testing.expectEqual(@as(?[]const u8, null), part.foo);
    try std.testing.expectEqual(@as(?[]const u8, null), part.bar);
    try std.testing.expectEqual(@as(?u32, null), part.baz);
}

pub const PresenceStatus = enum {
    online,
    dnd,
    idle,
    offline,
};

/// https://discord.com/developers/docs/resources/user#user-object-premium-types
pub const PremiumTypes = enum {
    None,
    NitroClassic,
    Nitro,
    NitroBasic,
};

/// https://discord.com/developers/docs/resources/user#user-object-user-flags
pub const UserFlags = packed struct {
    DiscordEmployee: bool = false,
    PartneredServerOwner: bool = false,
    HypeSquadEventsMember: bool = false,
    BugHunterLevel1: bool = false,
    _pad: u3 = 0,
    HouseBravery: bool = false,
    HouseBrilliance: bool = false,
    HouseBalance: bool = false,
    EarlySupporter: bool = false,
    TeamUser: bool = false,
    _pad2: u4 = 0,
    BugHunterLevel2: bool = false,
    _pad3: u1 = 0,
    VerifiedBot: bool = false,
    EarlyVerifiedBotDeveloper: bool = false,
    DiscordCertifiedModerator: bool = false,
    BotHttpInteractions: bool = false,
    _pad4: u3 = 0,
    ActiveDeveloper: bool = false,
};

pub const MemberFlags = packed struct {
    ///
    /// Member has left and rejoined the guild
    ///
    /// @remarks
    /// This value is not editable
    ////
    DidRejoin: bool = false,
    ///
    /// Member has completed onboarding
    ///
    /// @remarks
    /// This value is not editable
    ////
    CompletedOnboarding: bool = false,
    /// Member is exempt from guild verification requirements
    BypassesVerification: bool = false,
    ///
    /// Member has started onboarding
    ///
    /// @remarks
    /// This value is not editable
    ////
    StartedOnboarding: bool = false,
    ///
    /// Member is a guest and can only access the voice channel they were invited to
    ///
    /// @remarks
    /// This value is not editable
    ////
    IsGuest: bool = false,
    ///
    /// Member has started Server Guide new member actions
    ///
    /// @remarks
    /// This value is not editable
    ////
    StartedHomeActions: bool = false,
    ///
    /// Member has completed Server Guide new member actions
    ///
    /// @remarks
    /// This value is not editable
    ////
    CompletedHomeActions: bool = false,
    ///
    /// Member's username, display name, or nickname is blocked by AutoMod
    ///
    /// @remarks
    /// This value is not editable
    ////
    AutomodQuarantinedUsername: bool = false,
    _pad: u1 = 0,
    ///
    /// Member has dismissed the DM settings upsell
    ///
    /// @remarks
    /// This value is not editable
    ////
    DmSettingsUpsellAcknowledged: bool = false,
};

/// https://discord.com/developers/docs/resources/channel#channels-resource
pub const ChannelFlags = packed struct {
    None: bool = false,
    /// this thread is pinned to the top of its parent `GUILD_FORUM` channel
    Pinned: bool = false,
    _pad: u3 = 0,
    /// Whether a tag is required to be specified when creating a thread in a `GUILD_FORUM` or a GUILD_MEDIA channel. Tags are specified in the `applied_tags` field.
    RequireTag: bool = false,
    _pad1: u11 = 0,
    /// When set hides the embedded media download options. Available only for media channels.
    HideMediaDownloadOptions: bool = false,
};

/// https://discord.com/developers/docs/topics/permissions#role-object-role-flags
pub const RoleFlags = packed struct {
    None: bool = false,
    /// Role can be selected by members in an onboarding prompt
    InPrompt: bool = false,
};

pub const AttachmentFlags = packed struct {
    None: bool = false,
    _pad: u1 = 0,
    /// This attachment has been edited using the remix feature on mobile
    IsRemix: bool = false,
};

/// https://discord.com/developers/docs/monetization/skus#sku-object-sku-flags
pub const SkuFlags = packed struct {
    _pad: u2 = 0,
    /// SKU is available for purchase
    Available: bool = false,
    _pad1: u5 = 0,
    /// Recurring SKU that can be purchased by a user and applied to a single server. Grants access to every user in that server.
    GuildSubscription: bool = false,
    /// Recurring SKU purchased by a user for themselves. Grants access to the purchasing user in every server.
    UserSubscription: bool = false,
};

/// https://discord.com/developers/docs/resources/channel#message-object-message-flags
pub const MessageFlags = packed struct {
    /// This message has been published to subscribed channels (via Channel Following)
    Crossposted: bool = false,
    /// This message originated from a message in another channel (via Channel Following)
    IsCrosspost: bool = false,
    /// Do not include any embeds when serializing this message
    SuppressEmbeds: bool = false,
    /// The source message for this crosspost has been deleted (via Channel Following)
    SourceMessageDeleted: bool = false,
    /// This message came from the urgent message system
    Urgent: bool = false,
    /// This message has an associated thread, with the same id as the message
    HasThread: bool = false,
    /// This message is only visible to the user who invoked the Interaction
    Ephemeral: bool = false,
    /// This message is an Interaction Response and the bot is "thinking"
    Loading: bool = false,
    /// This message failed to mention some roles and add their members to the thread
    FailedToMentionSomeRolesInThread: bool = false,
    _pad: u4 = 0,
    /// This message will not trigger push and desktop notifications
    SuppressNotifications: bool = false,
    /// This message is a voice message
    IsVoiceMessage: bool = false,
};

/// https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-flags
pub const ActivityFlags = packed struct {
    Instance: bool = false,
    Join: bool = false,
    Spectate: bool = false,
    JoinRequest: bool = false,
    Sync: bool = false,
    Play: bool = false,
    PartyPrivacyFriends: bool = false,
    PartyPrivacyVoiceChannel: bool = false,
    Embedded: bool = false,
};

/// https://discord.com/developers/docs/resources/guild#integration-object-integration-expire-behaviors
pub const IntegrationExpireBehaviors = enum(u4) {
    RemoveRole = 0,
    Kick = 1,
};

/// https://discord.com/developers/docs/topics/teams#data-models-membership-state-enum
pub const TeamMembershipStates = enum(u4) {
    Invited = 1,
    Accepted = 2,
};

/// https://discord.com/developers/docs/topics/oauth2#application-application-flags
pub const ApplicationFlags = packed struct {
    _pad: u5 = 0,
    /// Indicates if an app uses the Auto Moderation API.
    ApplicationAutoModerationRuleCreateBadge: bool = false,
    _pad1: u6 = 0,
    /// Intent required for bots in **100 or more servers*  /// to receive 'presence_update' events
    GatewayPresence: bool = false,
    /// Intent required for bots in under 100 servers to receive 'presence_update' events
    GatewayPresenceLimited: bool = false,
    /// Intent required for bots in **100 or more servers*  /// to receive member-related events like 'guild_member_add'.
    GatewayGuildMembers: bool = false,
    /// Intent required for bots in under 100 servers to receive member-related events like 'guild_member_add'.
    GatewayGuildMembersLimited: bool = false,
    /// Indicates unusual growth of an app that prevents verification
    VerificationPendingGuildLimit: bool = false,
    /// Indicates if an app is embedded within the Discord client (currently unavailable publicly)
    Embedded: bool = false,
    /// Intent required for bots in **100 or more servers*  /// to receive [message content](https://support-dev.discord.com/hc/en-us/articles/4404772028055)
    GatewayMessageContent: bool = false,
    /// Intent required for bots in under 100 servers to receive [message content](https://support-dev.discord.com/hc/en-us/articles/4404772028055), found in Bot Settings
    GatewayMessageContentLimited: bool = false,
    _pad2: u4 = 0,
    /// Indicates if an app has registered global application commands
    ApplicationCommandBadge: bool = false,
};

/// https://discord.com/developers/docs/interactions/message-components#component-types
pub const MessageComponentTypes = enum(u4) {
    /// A container for other components
    ActionRow = 1,
    /// A button object
    Button,
    /// A select menu for picking from choices
    SelectMenu,
    /// A text input object
    InputText,
    /// Select menu for users
    SelectMenuUsers,
    /// Select menu for roles
    SelectMenuRoles,
    /// Select menu for users and roles
    SelectMenuUsersAndRoles,
    /// Select menu for channels
    SelectMenuChannels,
};

pub const TextStyles = enum(u4) {
    /// Intended for short single-line text
    Short = 1,
    /// Intended for much longer inputs
    Paragraph = 2,
};

/// https://discord.com/developers/docs/interactions/message-components#buttons-button-styles
pub const ButtonStyles = enum(u4) {
    /// A blurple button
    Primary = 1,
    /// A grey button
    Secondary,
    /// A green button
    Success,
    /// A red button
    Danger,
    /// A button that navigates to a URL
    Link,
    /// A blurple button to show a Premium item in the shop
    Premium,
};

/// https://discord.com/developers/docs/resources/channel#allowed-mentions-object-allowed-mention-types
pub const AllowedMentionsTypes = enum {
    /// Controls role mentions
    roles,
    /// Controls user mentions
    users,
    /// Controls \@everyone and \@here mentions
    everyone,
};

/// https://discord.com/developers/docs/resources/webhook#webhook-object-webhook-types
pub const WebhookTypes = enum(u4) {
    /// Incoming Webhooks can post messages to channels with a generated token
    Incoming = 1,
    /// Channel Follower Webhooks are internal webhooks used with Channel Following to post new messages into channels
    ChannelFollower,
    /// Application webhooks are webhooks used with Interactions
    Application,
};

/// https://discord.com/developers/docs/resources/channel#embed-object-embed-types
pub const EmbedTypes = union(enum) {
    rich,
    image,
    video,
    gifv,
    article,
    link,
    poll_res,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-default-message-notification-level
pub const DefaultMessageNotificationLevels = enum {
    /// Members will receive notifications for all messages by default
    AllMessages,
    /// Members will receive notifications only for messages that \@mention them by default
    OnlyMentions,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-explicit-content-filter-level
pub const ExplicitContentFilterLevels = enum {
    /// Media content will not be scanned
    Disabled,
    /// Media content sent by members without roles will be scanned
    MembersWithoutRoles,
    /// Media content sent by all members will be scanned
    AllMembers,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-verification-level
pub const VerificationLevels = enum {
    /// Unrestricted
    None,
    /// Must have verified email on account
    Low,
    /// Must be registered on Discord for longer than 5 minutes
    Medium,
    /// Must be a member of the server for longer than 10 minutes
    High,
    /// Must have a verified phone number
    VeryHigh,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-guild-features
pub const GuildFeatures = enum {
    /// Guild has access to set an invite splash background
    INVITE_SPLASH,
    /// Guild has access to set a vanity URL
    VANITY_URL,
    /// Guild is verified
    VERIFIED,
    /// Guild is partnered
    PARTNERED,
    /// Guild can enable welcome screen, Membership Screening, stage channels and discovery, and receives community updates
    COMMUNITY,
    /// Guild has enabled monetization.
    CREATOR_MONETIZABLE_PROVISIONAL,
    /// Guild has enabled the role subscription promo page.
    CREATOR_STORE_PAGE,
    /// Guild has been set as a support server on the App Directory
    DEVELOPER_SUPPORT_SERVER,
    /// Guild has access to create news channels
    NEWS,
    /// Guild is able to be discovered in the directory
    DISCOVERABLE,
    /// Guild is able to be featured in the directory
    FEATURABLE,
    /// Guild has access to set an animated guild icon
    ANIMATED_ICON,
    /// Guild has access to set a guild banner image
    BANNER,
    /// Guild has enabled the welcome screen
    WELCOME_SCREEN_ENABLED,
    /// Guild has enabled [Membership Screening](https://discord.com/developers/docs/resources/guild#membership-screening-object)
    MEMBER_VERIFICATION_GATE_ENABLED,
    /// Guild can be previewed before joining via Membership Screening or the directory
    PREVIEW_ENABLED,
    /// Guild has enabled ticketed events
    TICKETED_EVENTS_ENABLED,
    /// Guild has increased custom sticker slots
    MORE_STICKERS,
    /// Guild is able to set role icons
    ROLE_ICONS,
    /// Guild has role subscriptions that can be purchased.
    ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE,
    /// Guild has enabled role subscriptions.
    ROLE_SUBSCRIPTIONS_ENABLED,
    /// Guild has set up auto moderation rules
    AUTO_MODERATION,
    /// Guild has paused invites, preventing new users from joining
    INVITES_DISABLED,
    /// Guild has access to set an animated guild banner image
    ANIMATED_BANNER,
    /// Guild has disabled alerts for join raids in the configured safety alerts channel
    RAID_ALERTS_DISABLED,
    /// Guild is using the old permissions configuration behavior
    APPLICATION_COMMAND_PERMISSIONS_V2,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-mfa-level
pub const MfaLevels = enum {
    /// Guild has no MFA/2FA requirement for moderation actions
    None,
    /// Guild has a 2FA requirement for moderation actions
    Elevated,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-system-channel-flags
pub const SystemChannelFlags = packed struct {
    /// Suppress member join notifications
    SuppressJoinNotifications: bool = false,
    /// Suppress server boost notifications
    SuppressPremiumSubscriptions: bool = false,
    /// Suppress server setup tips
    SuppressGuildReminderNotifications: bool = false,
    /// Hide member join sticker reply buttons
    SuppressJoinNotificationReplies: bool = false,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-premium-tier
pub const PremiumTiers = enum {
    /// Guild has not unlocked any Server Boost perks
    None,
    /// Guild has unlocked Server Boost level 1 perks
    Tier1,
    /// Guild has unlocked Server Boost level 2 perks
    Tier2,
    /// Guild has unlocked Server Boost level 3 perks
    Tier3,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-guild-nsfw-level
pub const GuildNsfwLevel = enum {
    Default,
    Explicit,
    Safe,
    AgeRestricted,
};

/// https://discord.com/developers/docs/resources/channel#channel-object-channel-types
pub const ChannelTypes = packed struct {
    /// A text channel within a server
    GuildText: bool = false,
    /// A direct message between users
    DM: bool = false,
    /// A voice channel within a server
    GuildVoice: bool = false,
    /// A direct message between multiple users
    GroupDm: bool = false,
    /// An organizational category that contains up to 50 channels
    GuildCategory: bool = false,
    /// A channel that users can follow and crosspost into their own server
    GuildAnnouncement: bool = false,
    _pad: u4 = 0,
    /// A temporary sub-channel within a GUILD_ANNOUNCEMENT channel
    AnnouncementThread: bool = false,
    /// A temporary sub-channel within a GUILD_TEXT or GUILD_FORUM channel
    PublicThread: bool = false,
    /// A temporary sub-channel within a GUILD_TEXT channel that is only viewable by those invited and those with the MANAGE_THREADS permission
    PrivateThread: bool = false,
    /// A voice channel for hosting events with an audience
    GuildStageVoice: bool = false,
    /// A channel in a hub containing the listed servers
    GuildDirectory: bool = false,
    /// A channel which can only contains threads
    GuildForum: bool = false,
    /// Channel that can only contain threads, similar to GUILD_FORUM channels
    GuildMedia: bool = false,
};

pub const OverwriteTypes = enum {
    Role,
    Member,
};

pub const VideoQualityModes = enum(u4) {
    /// Discord chooses the quality for optimal performance
    Auto = 1,
    /// 720p
    Full,
};

/// https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-types
pub const ActivityTypes = enum(u4) {
    Playing = 0,
    Streaming = 1,
    Listening = 2,
    Watching = 3,
    Custom = 4,
    Competing = 5,
};

/// https://discord.com/developers/docs/resources/channel#message-object-message-types
pub const MessageTypes = enum(u8) {
    Default,
    RecipientAdd,
    RecipientRemove,
    Call,
    ChannelNameChange,
    ChannelIconChange,
    ChannelPinnedMessage,
    UserJoin,
    GuildBoost,
    GuildBoostTier1,
    GuildBoostTier2,
    GuildBoostTier3,
    ChannelFollowAdd,
    GuildDiscoveryDisqualified = 14,
    GuildDiscoveryRequalified,
    GuildDiscoveryGracePeriodInitialWarning,
    GuildDiscoveryGracePeriodFinalWarning,
    ThreadCreated,
    Reply,
    ChatInputCommand,
    ThreadStarterMessage,
    GuildInviteReminder,
    ContextMenuCommand,
    AutoModerationAction,
    RoleSubscriptionPurchase,
    InteractionPremiumUpsell,
    StageStart,
    StageEnd,
    StageSpeaker,
    StageTopic = 31,
    GuildApplicationPremiumSubscription,
    GuildIncidentAlertModeEnabled = 36,
    GuildIncidentAlertModeDisabled,
    GuildIncidentReportRaid,
    GuildIncidentReportFalseAlarm,
    PurchaseNotification = 44,
    PollResult = 46,
};

/// https://discord.com/developers/docs/resources/channel#message-object-message-activity-types
pub const MessageActivityTypes = enum(u4) {
    Join = 1,
    Spectate = 2,
    Listen = 3,
    JoinRequest = 5,
};

/// https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-types
pub const StickerTypes = enum(u4) {
    /// an official sticker in a pack
    Standard = 1,
    /// a sticker uploaded to a guild for the guild's members
    Guild = 2,
};

/// https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types
pub const StickerFormatTypes = enum(u4) {
    Png = 1,
    APng,
    Lottie,
    Gif,
};

/// https://discord.com/developers/docs/interactions/slash-commands#interaction-interactiontype
pub const InteractionTypes = enum(u4) {
    Ping = 1,
    ApplicationCommand = 2,
    MessageComponent = 3,
    ApplicationCommandAutocomplete = 4,
    ModalSubmit = 5,
};

/// https://discord.com/developers/docs/interactions/slash-commands#applicationcommandoptiontype
pub const ApplicationCommandOptionTypes = enum(u4) {
    SubCommand = 1,
    SubCommandGroup,
    String,
    Integer,
    Boolean,
    User,
    Channel,
    Role,
    Mentionable,
    Number,
    Attachment,
};

/// https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-audit-log-events
pub const AuditLogEvents = enum(u4) {
    /// Server settings were updated
    GuildUpdate = 1,
    /// Channel was created
    ChannelCreate = 10,
    /// Channel settings were updated
    ChannelUpdate,
    /// Channel was deleted
    ChannelDelete,
    /// Permission overwrite was added to a channel
    ChannelOverwriteCreate,
    /// Permission overwrite was updated for a channel
    ChannelOverwriteUpdate,
    /// Permission overwrite was deleted from a channel
    ChannelOverwriteDelete,
    /// Member was removed from server
    MemberKick = 20,
    /// Members were pruned from server
    MemberPrune,
    /// Member was banned from server
    MemberBanAdd,
    /// Server ban was lifted for a member
    MemberBanRemove,
    /// Member was updated in server
    MemberUpdate,
    /// Member was added or removed from a role
    MemberRoleUpdate,
    /// Member was moved to a different voice channel
    MemberMove,
    /// Member was disconnected from a voice channel
    MemberDisconnect,
    /// Bot user was added to server
    BotAdd,
    /// Role was created
    RoleCreate = 30,
    /// Role was edited
    RoleUpdate,
    /// Role was deleted
    RoleDelete,
    /// Server invite was created
    InviteCreate = 40,
    /// Server invite was updated
    InviteUpdate,
    /// Server invite was deleted
    InviteDelete,
    /// Webhook was created
    WebhookCreate = 50,
    /// Webhook properties or channel were updated
    WebhookUpdate,
    /// Webhook was deleted
    WebhookDelete,
    /// Emoji was created
    EmojiCreate = 60,
    /// Emoji name was updated
    EmojiUpdate,
    /// Emoji was deleted
    EmojiDelete,
    /// Single message was deleted
    MessageDelete = 72,
    /// Multiple messages were deleted
    MessageBulkDelete,
    /// Messaged was pinned to a channel
    MessagePin,
    /// Message was unpinned from a channel
    MessageUnpin,
    /// App was added to server
    IntegrationCreate = 80,
    /// App was updated (as an example, its scopes were updated)
    IntegrationUpdate,
    /// App was removed from server
    IntegrationDelete,
    /// Stage instance was created (stage channel becomes live)
    StageInstanceCreate,
    /// Stage instace details were updated
    StageInstanceUpdate,
    /// Stage instance was deleted (stage channel no longer live)
    StageInstanceDelete,
    /// Sticker was created
    StickerCreate = 90,
    /// Sticker details were updated
    StickerUpdate,
    /// Sticker was deleted
    StickerDelete,
    /// Event was created
    GuildScheduledEventCreate = 100,
    /// Event was updated
    GuildScheduledEventUpdate,
    /// Event was cancelled
    GuildScheduledEventDelete,
    /// Thread was created in a channel
    ThreadCreate = 110,
    /// Thread was updated
    ThreadUpdate,
    /// Thread was deleted
    ThreadDelete,
    /// Permissions were updated for a command
    ApplicationCommandPermissionUpdate = 121,
    /// Auto moderation rule was created
    AutoModerationRuleCreate = 140,
    /// Auto moderation rule was updated
    AutoModerationRuleUpdate,
    /// Auto moderation rule was deleted
    AutoModerationRuleDelete,
    /// Message was blocked by AutoMod according to a rule.
    AutoModerationBlockMessage,
    /// Message was flagged by AutoMod
    AudoModerationFlagMessage,
    /// Member was timed out by AutoMod
    AutoModerationMemberTimedOut,
    /// Creator monetization request was created
    CreatorMonetizationRequestCreated = 150,
    /// Creator monetization terms were accepted
    CreatorMonetizationTermsAccepted,
    /// Guild Onboarding Question was created
    OnBoardingPromptCreate = 163,
    /// Guild Onboarding Question was updated
    OnBoardingPromptUpdate,
    /// Guild Onboarding Question was deleted
    OnBoardingPromptDelete,
    /// Guild Onboarding was created
    OnBoardingCreate,
    /// Guild Onboarding was updated
    OnBoardingUpdate,
    /// Guild Server Guide was created
    HomeSettingsCreate = 190,
    /// Guild Server Guide was updated
    HomeSettingsUpdate,
};

pub const ScheduledEventPrivacyLevel = enum(u4) {
    /// the scheduled event is only accessible to guild members
    GuildOnly = 2,
};

pub const ScheduledEventEntityType = enum(u4) {
    StageInstance = 1,
    Voice,
    External,
};

pub const ScheduledEventStatus = enum(u4) {
    Scheduled = 1,
    Active,
    Completed,
    Canceled,
};

/// https://discord.com/developers/docs/resources/invite#invite-object-target-user-types
pub const TargetTypes = enum(u4) {
    Stream = 1,
    EmbeddedApplication,
};

pub const ApplicationCommandTypes = enum(u4) {
    /// A text-based command that shows up when a user types `/`
    ChatInput = 1,
    /// A UI-based command that shows up when you right click or tap on a user
    User,
    /// A UI-based command that shows up when you right click or tap on a message
    Message,
    /// A UI-based command that represents the primary way to invoke an app's Activity
    PrimaryEntryPoint,
};

pub const ApplicationCommandPermissionTypes = enum(u4) {
    Role = 1,
    User,
    Channel,
};

/// https://discord.com/developers/docs/topics/permissions#permissions-bitwise-permission-flags
pub const BitwisePermissionFlags = packed struct {
    /// Allows creation of instant invites
    CREATE_INSTANT_INVITE: bool = false,
    /// Allows kicking members
    KICK_MEMBERS: bool = false,
    /// Allows banning members
    BAN_MEMBERS: bool = false,
    /// Allows all permissions and bypasses channel permission overwrites
    ADMINISTRATOR: bool = false,
    /// Allows management and editing of channels
    MANAGE_CHANNELS: bool = false,
    /// Allows management and editing of the guild
    MANAGE_GUILD: bool = false,
    /// Allows for the addition of reactions to messages
    ADD_REACTIONS: bool = false,
    /// Allows for viewing of audit logs
    VIEW_AUDIT_LOG: bool = false,
    /// Allows for using priority speaker in a voice channel
    PRIORITY_SPEAKER: bool = false,
    /// Allows the user to go live
    STREAM: bool = false,
    /// Allows guild members to view a channel, which includes reading messages in text channels and joining voice channels
    VIEW_CHANNEL: bool = false,
    /// Allows for sending messages in a channel. (does not allow sending messages in threads)
    SEND_MESSAGES: bool = false,
    /// Allows for sending of /tts messages
    SEND_TTS_MESSAGES: bool = false,
    /// Allows for deletion of other users messages
    MANAGE_MESSAGES: bool = false,
    /// Links sent by users with this permission will be auto-embedded
    EMBED_LINKS: bool = false,
    /// Allows for uploading images and files
    ATTACH_FILES: bool = false,
    /// Allows for reading of message history
    READ_MESSAGE_HISTORY: bool = false,
    /// Allows for using the \@everyone tag to notify all users in a channel, and the \@here tag to notify all online users in a channel
    MENTION_EVERYONE: bool = false,
    /// Allows the usage of custom emojis from other servers
    USE_EXTERNAL_EMOJIS: bool = false,
    /// Allows for viewing guild insights
    VIEW_GUILD_INSIGHTS: bool = false,
    /// Allows for joining of a voice channel
    CONNECT: bool = false,
    /// Allows for speaking in a voice channel
    SPEAK: bool = false,
    /// Allows for muting members in a voice channel
    MUTE_MEMBERS: bool = false,
    /// Allows for deafening of members in a voice channel
    DEAFEN_MEMBERS: bool = false,
    /// Allows for moving of members between voice channels
    MOVE_MEMBERS: bool = false,
    /// Allows for using voice-activity-detection in a voice channel
    USE_VAD: bool = false,
    /// Allows for modification of own nickname
    CHANGE_NICKNAME: bool = false,
    /// Allows for modification of other users nicknames
    MANAGE_NICKNAMES: bool = false,
    /// Allows management and editing of roles
    MANAGE_ROLES: bool = false,
    /// Allows management and editing of webhooks
    MANAGE_WEBHOOKS: bool = false,
    /// Allows for editing and deleting emojis, stickers, and soundboard sounds created by all users
    MANAGE_GUILD_EXPRESSIONS: bool = false,
    /// Allows members to use application commands in text channels
    USE_SLASH_COMMANDS: bool = false,
    /// Allows for requesting to speak in stage channels.
    REQUEST_TO_SPEAK: bool = false,
    /// Allows for editing and deleting scheduled events created by all users
    MANAGE_EVENTS: bool = false,
    /// Allows for deleting and archiving threads, and viewing all private threads
    MANAGE_THREADS: bool = false,
    /// Allows for creating public and announcement threads
    CREATE_PUBLIC_THREADS: bool = false,
    /// Allows for creating private threads
    CREATE_PRIVATE_THREADS: bool = false,
    /// Allows the usage of custom stickers from other servers
    USE_EXTERNAL_STICKERS: bool = false,
    /// Allows for sending messages in threads
    SEND_MESSAGES_IN_THREADS: bool = false,
    /// Allows for launching activities (applications with the `EMBEDDED` flag) in a voice channel.
    USE_EMBEDDED_ACTIVITIES: bool = false,
    /// Allows for timing out users to prevent them from sending or reacting to messages in chat and threads, and from speaking in voice and stage channels
    MODERATE_MEMBERS: bool = false,
    /// Allows for viewing role subscription insights.
    VIEW_CREATOR_MONETIZATION_ANALYTICS: bool = false,
    /// Allows for using soundboard in a voice channel.
    USE_SOUNDBOARD: bool = false,
    /// Allows for creating emojis, stickers, and soundboard sounds, and editing and deleting those created by the current user
    CREATE_GUILD_EXPRESSIONS: bool = false,
    /// Allows for creating scheduled events, and editing and deleting those created by the current user
    CREATE_EVENTS: bool = false,
    /// Allows the usage of custom soundboards sounds from other servers
    USE_EXTERNAL_SOUNDS: bool = false,
    /// Allows sending voice messages
    SEND_VOICE_MESSAGES: bool = false,
    /// Allows sending polls
    SEND_POLLS: bool = false,
    /// Allows user-installed apps to send public responses. When disabled, users will still be allowed to use their apps but the responses will be ephemeral. This only applies to apps not also installed to the server.
    USE_EXTERNAL_APPS: bool = false,
};

pub const PermissionStrings = BitwisePermissionFlags;

/// https://discord.com/developers/docs/topics/opcodes-and-status-codes#opcodes-and-status-codes
pub const GatewayCloseEventCodes = enum(u16) {
    /// A normal closure of the gateway. You may attempt to reconnect.
    NormalClosure = 1000,
    /// We're not sure what went wrong. Try reconnecting?
    UnknownError = 4000,
    /// You sent an invalid [Gateway opcode](https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-opcodes) or an invalid payload for an opcode. Don't do that!
    UnknownOpcode,
    /// You sent an invalid [payload](https://discord.com/developers/docs/topics/gateway#sending-payloads) to us. Don't do that!
    DecodeError,
    /// You sent us a payload prior to [identifying](https://discord.com/developers/docs/topics/gateway-events#identify), or this session has been invalidated.
    NotAuthenticated,
    /// The account token sent with your [identify payload](https://discord.com/developers/docs/topics/gateway-events#identify) is incorrect.
    AuthenticationFailed,
    /// You sent more than one identify payload. Don't do that!
    AlreadyAuthenticated,
    /// The sequence sent when [resuming](https://discord.com/developers/docs/topics/gateway-events#resume) the session was invalid. Reconnect and start a new session.
    InvalidSeq = 4007,
    /// Woah nelly! You're sending payloads to us too quickly. Slow it down! You will be disconnected on receiving this.
    RateLimited,
    /// Your session timed out. Reconnect and start a new one.
    SessionTimedOut,
    /// You sent us an invalid [shard when identifying](https://discord.com/developers/docs/topics/gateway#sharding).
    InvalidShard,
    /// The session would have handled too many guilds - you are required to [shard](https://discord.com/developers/docs/topics/gateway#sharding) your connection in order to connect.
    ShardingRequired,
    /// You sent an invalid version for the gateway.
    InvalidApiVersion,
    /// You sent an invalid intent for a [Gateway Intent](https://discord.com/developers/docs/topics/gateway#gateway-intents). You may have incorrectly calculated the bitwise value.
    InvalidIntents,
    /// You sent a disallowed intent for a [Gateway Intent](https://discord.com/developers/docs/topics/gateway#gateway-intents). You may have tried to specify an intent that you [have not enabled or are not approved for](https://discord.com/developers/docs/topics/gateway#privileged-intents).
    DisallowedIntents,
};

/// https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-opcodes
pub const GatewayOpcodes = enum(u4) {
    /// An event was dispatched.
    Dispatch,
    /// Fired periodically by the client to keep the connection alive.
    Heartbeat,
    /// Starts a new session during the initial handshake.
    Identify,
    /// Update the client's presence.
    PresenceUpdate,
    /// Used to join/leave or move between voice channels.
    VoiceStateUpdate,
    /// Resume a previous session that was disconnected.
    Resume = 6,
    /// You should attempt to reconnect and resume immediately.
    Reconnect,
    /// Request information about offline guild members in a large guild.
    RequestGuildMembers,
    /// The session has been invalidated. You should reconnect and identify/resume accordingly.
    InvalidSession,
    /// Sent immediately after connecting, contains the `heartbeat_interval` to use.
    Hello,
    /// Sent in response to receiving a heartbeat to acknowledge that it has been received.
    HeartbeatACK,
};

pub const GatewayDispatchEventNames = union(enum) {
    APPLICATION_COMMAND_PERMISSIONS_UPDATE,
    AUTO_MODERATION_RULE_CREATE,
    AUTO_MODERATION_RULE_UPDATE,
    AUTO_MODERATION_RULE_DELETE,
    AUTO_MODERATION_ACTION_EXECUTION,
    CHANNEL_CREATE,
    CHANNEL_UPDATE,
    CHANNEL_DELETE,
    CHANNEL_PINS_UPDATE,
    THREAD_CREATE,
    THREAD_UPDATE,
    THREAD_DELETE,
    THREAD_LIST_SYNC,
    THREAD_MEMBER_UPDATE,
    THREAD_MEMBERS_UPDATE,
    GUILD_AUDIT_LOG_ENTRY_CREATE,
    GUILD_CREATE,
    GUILD_UPDATE,
    GUILD_DELETE,
    GUILD_BAN_ADD,
    GUILD_BAN_REMOVE,
    GUILD_EMOJIS_UPDATE,
    GUILD_STICKERS_UPDATE,
    GUILD_INTEGRATIONS_UPDATE,
    GUILD_MEMBER_ADD,
    GUILD_MEMBER_REMOVE,
    GUILD_MEMBER_UPDATE,
    GUILD_MEMBERS_CHUNK,
    GUILD_ROLE_CREATE,
    GUILD_ROLE_UPDATE,
    GUILD_ROLE_DELETE,
    GUILD_SCHEDULED_EVENT_CREATE,
    GUILD_SCHEDULED_EVENT_UPDATE,
    GUILD_SCHEDULED_EVENT_DELETE,
    GUILD_SCHEDULED_EVENT_USER_ADD,
    GUILD_SCHEDULED_EVENT_USER_REMOVE,
    INTEGRATION_CREATE,
    INTEGRATION_UPDATE,
    INTEGRATION_DELETE,
    INTERACTION_CREATE,
    INVITE_CREATE,
    INVITE_DELETE,
    MESSAGE_CREATE,
    MESSAGE_UPDATE,
    MESSAGE_DELETE,
    MESSAGE_DELETE_BULK,
    MESSAGE_REACTION_ADD,
    MESSAGE_REACTION_REMOVE,
    MESSAGE_REACTION_REMOVE_ALL,
    MESSAGE_REACTION_REMOVE_EMOJI,
    PRESENCE_UPDATE,
    STAGE_INSTANCE_CREATE,
    STAGE_INSTANCE_UPDATE,
    STAGE_INSTANCE_DELETE,
    TYPING_START,
    USER_UPDATE,
    VOICE_CHANNEL_EFFECT_SEND,
    VOICE_STATE_UPDATE,
    VOICE_SERVER_UPDATE,
    WEBHOOKS_UPDATE,
    ENTITLEMENT_CREATE,
    ENTITLEMENT_UPDATE,
    ENTITLEMENT_DELETE,
    MESSAGE_POLL_VOTE_ADD,
    MESSAGE_POLL_VOTE_REMOVE,

    READY,
    RESUMED,
};

/// https://discord.com/developers/docs/topics/gateway#list-of-intents
pub const GatewayIntents = packed struct {
    ///
    /// - GUILD_CREATE
    /// - GUILD_UPDATE
    /// - GUILD_DELETE
    /// - GUILD_ROLE_CREATE
    /// - GUILD_ROLE_UPDATE
    /// - GUILD_ROLE_DELETE
    /// - CHANNEL_CREATE
    /// - CHANNEL_UPDATE
    /// - CHANNEL_DELETE
    /// - CHANNEL_PINS_UPDATE
    /// - THREAD_CREATE
    /// - THREAD_UPDATE
    /// - THREAD_DELETE
    /// - THREAD_LIST_SYNC
    /// - THREAD_MEMBER_UPDATE
    /// - THREAD_MEMBERS_UPDATE
    /// - STAGE_INSTANCE_CREATE
    /// - STAGE_INSTANCE_UPDATE
    /// - STAGE_INSTANCE_DELETE
    ////
    Guilds: bool = false,
    ///
    /// - GUILD_MEMBER_ADD
    /// - GUILD_MEMBER_UPDATE
    /// - GUILD_MEMBER_REMOVE
    /// - THREAD_MEMBERS_UPDATE
    ///
    /// This is a privileged intent.
    ////
    GuildMembers: bool = false,
    ///
    /// - GUILD_AUDIT_LOG_ENTRY_CREATE
    /// - GUILD_BAN_ADD
    /// - GUILD_BAN_REMOVE
    ////
    GuildModeration: bool = false,
    ///
    /// - GUILD_EMOJIS_UPDATE
    /// - GUILD_STICKERS_UPDATE
    ////
    GuildEmojisAndStickers: bool = false,
    ///
    /// - GUILD_INTEGRATIONS_UPDATE
    /// - INTEGRATION_CREATE
    /// - INTEGRATION_UPDATE
    /// - INTEGRATION_DELETE
    ////
    GuildIntegrations: bool = false,
    ///
    /// - WEBHOOKS_UPDATE
    ////
    GuildWebhooks: bool = false,
    ///
    /// - INVITE_CREATE
    /// - INVITE_DELETE
    ////
    GuildInvites: bool = false,
    ///
    /// - VOICE_STATE_UPDATE
    /// - VOICE_CHANNEL_EFFECT_SEND
    ////
    GuildVoiceStates: bool = false,
    ///
    /// - PRESENCE_UPDATE
    ///
    /// This is a privileged intent.
    ////
    GuildPresences: bool = false,
    ///
    /// - MESSAGE_CREATE
    /// - MESSAGE_UPDATE
    /// - MESSAGE_DELETE
    /// - MESSAGE_DELETE_BULK
    ///
    /// The messages do not contain content by default.
    /// If you want to receive their content too, you need to turn on the privileged `MESSAGE_CONTENT` intent. */
    GuildMessages: bool = false,
    ///
    /// - MESSAGE_REACTION_ADD
    /// - MESSAGE_REACTION_REMOVE
    /// - MESSAGE_REACTION_REMOVE_ALL
    /// - MESSAGE_REACTION_REMOVE_EMOJI
    ////
    GuildMessageReactions: bool = false,
    ///
    /// - TYPING_START
    ////
    GuildMessageTyping: bool = false,
    ///
    /// - CHANNEL_CREATE
    /// - MESSAGE_CREATE
    /// - MESSAGE_UPDATE
    /// - MESSAGE_DELETE
    /// - CHANNEL_PINS_UPDATE
    ////
    DirectMessages: bool = false,
    ///
    /// - MESSAGE_REACTION_ADD
    /// - MESSAGE_REACTION_REMOVE
    /// - MESSAGE_REACTION_REMOVE_ALL
    /// - MESSAGE_REACTION_REMOVE_EMOJI
    ////
    DirectMessageReactions: bool = false,
    ///
    /// - TYPING_START
    ////
    DirectMessageTyping: bool = false,
    ///
    /// This intent will add all content related values to message events.
    ///
    /// This is a privileged intent.
    ////
    MessageContent: bool = false,
    ///
    /// - GUILD_SCHEDULED_EVENT_CREATE
    /// - GUILD_SCHEDULED_EVENT_UPDATE
    /// - GUILD_SCHEDULED_EVENT_DELETE
    /// - GUILD_SCHEDULED_EVENT_USER_ADD this is experimental and unstable.
    /// - GUILD_SCHEDULED_EVENT_USER_REMOVE this is experimental and unstable.
    ////
    GuildScheduledEvents: bool = false,
    _pad: u4 = 0,
    ///
    /// - AUTO_MODERATION_RULE_CREATE
    /// - AUTO_MODERATION_RULE_UPDATE
    /// - AUTO_MODERATION_RULE_DELETE
    ////
    AutoModerationConfiguration: bool = false,
    ///
    /// - AUTO_MODERATION_ACTION_EXECUTION
    ////
    AutoModerationExecution: bool = false,
    _pad2: u3 = 0,
    ///
    /// - MESSAGE_POLL_VOTE_ADD
    /// - MESSAGE_POLL_VOTE_REMOVE
    ////
    GuildMessagePolls: bool = false,
    ///
    /// - MESSAGE_POLL_VOTE_ADD
    /// - MESSAGE_POLL_VOTE_REMOVE
    ////
    DirectMessagePolls: bool = false,
};

/// https://discord.com/developers/docs/topics/gateway#list-of-intents
pub const Intents = GatewayIntents;

/// https://discord.com/developers/docs/interactions/slash-commands#interaction-response-interactionresponsetype
pub const InteractionResponseTypes = enum(u4) {
    /// ACK a `Ping`
    Pong = 1,
    /// Respond to an interaction with a message
    ChannelMessageWithSource = 4,
    /// ACK an interaction and edit a response later, the user sees a loading state
    DeferredChannelMessageWithSource = 5,
    /// For components, ACK an interaction and edit the original message later; the user does not see a loading state
    DeferredUpdateMessage = 6,
    /// For components, edit the message the component was attached to
    UpdateMessage = 7,
    /// For Application Command Options, send an autocomplete result
    ApplicationCommandAutocompleteResult = 8,
    /// For Command or Component interactions, send a Modal response
    Modal = 9,
    ///
    /// Respond to an interaction with an upgrade button, only available for apps with monetization enabled
    ///
    /// @deprecated You should migrate to the premium button components
    PremiumRequired = 10,
    ///
    /// Launch the Activity associated with the app.
    ///
    /// @remarks
    /// Only available for apps with Activities enabled
    LaunchActivity = 12,
};

pub const SortOrderTypes = enum {
    /// Sort forum posts by activity
    LatestActivity,
    /// Sort forum posts by creation time (from most recent to oldest)
    CreationDate,
};

pub const ForumLayout = enum(u4) {
    /// No default has been set for forum channel.
    NotSet = 0,
    /// Display posts as a list.
    ListView = 1,
    /// Display posts as a collection of tiles.
    GalleryView = 2,
};

/// https://discord.com/developers/docs/reference#image-formatting
/// json is only for stickers
pub const ImageFormat = union(enum) {
    jpg,
    jpeg,
    png,
    webp,
    gif,
    json,
};

/// https://discord.com/developers/docs/reference#image-formatting
pub const ImageSize = isize;

pub const Locales = enum {
    id,
    da,
    de,
    @"en-GB",
    @"en-US",
    @"es-ES",
    @"es-419",
    fr,
    hr,
    it,
    lt,
    hu,
    nl,
    no,
    pl,
    @"pt-BR",
    ro,
    fi,
    @"sv-SE",
    vi,
    tr,
    cs,
    el,
    bg,
    ru,
    uk,
    hi,
    th,
    @"zh-CN",
    ja,
    @"zh-TW",
    ko,
};

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
    id: []const u8,
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
};

/// https://discord.com/developers/docs/topics/oauth2#shared-resources-oauth2-scopes
pub const OAuth2Scope = enum {
    ///
    /// Allows your app to fetch data from a user's "Now Playing/Recently Played" list
    ///
    /// @remarks
    /// This scope is not currently available for apps
    ///
    @"activities.read",
    ///
    /// Allows your app to update a user's activity
    ///
    /// @remarks
    /// This scope not currently available for apps.
    ///
    @"activities.write",
    /// Allows your app to read build data for a user's applications
    @"applications.builds.read",
    ///
    /// Allows your app to upload/update builds for a user's applications
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"applications.builds.upload",
    /// Allows your app to add commands to a guild - included by default with the `bot` scope
    @"applications.commands",
    ///
    /// Allows your app to update its Application Commands via this bearer token
    ///
    /// @remarks
    /// This scope can only be used when using a [Client Credential Grant](https://discord.com/developers/docs/topics/oauth2#client-credentials-grant)
    ///
    @"applications.commands.update",
    /// Allows your app to update permissions for its commands in a guild a user has permissions to
    @"applications.commands.permissions.update",
    /// Allows your app to read entitlements for a user's applications
    @"applications.entitlements",
    /// Allows your app to read and update store data (SKUs, store listings, achievements, etc.) for a user's applications
    @"applications.store.update",
    /// For oauth2 bots, this puts the bot in the user's selected guild by default
    bot,
    /// Allows requests to [/users/@me/connections](https://discord.com/developers/docs/resources/user#get-user-connections)
    connections,
    ///
    /// Allows your app to see information about the user's DMs and group DMs
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"dm_channels.read",
    /// Adds the `email` filed to [/users/@me](https://discord.com/developers/docs/resources/user#get-current-user)
    email,
    /// Allows your app to join users to a group dm
    @"gdm.join",
    /// Allows requests to [/users/@me/guilds](https://discord.com/developers/docs/resources/user#get-current-user-guilds)
    guilds,
    /// Allows requests to [/guilds/{guild.id};/members/{user.id};](https://discord.com/developers/docs/resources/guild#add-guild-member)
    @"guilds.join",
    /// Allows requests to [/users/@me/guilds/{guild.id};/member](https://discord.com/developers/docs/resources/user#get-current-user-guild-member)
    @"guilds.members.read",
    ///
    /// Allows requests to [/users/@me](https://discord.com/developers/docs/resources/user#get-current-user)
    ///
    /// @remarks
    /// The return object from [/users/@me](https://discord.com/developers/docs/resources/user#get-current-user)
    /// does NOT contain the `email` field unless the scope `email` is also used
    ///
    identify,
    ///
    /// For local rpc server api access, this allows you to read messages from all client channels
    /// (otherwise restricted to channels/guilds your app creates)
    ///
    @"messages.read",
    ///
    /// Allows your app to know a user's friends and implicit relationships
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"relationships.read",
    /// Allows your app to update a user's connection and metadata for the app
    @"role_connections.write",
    ///
    ///For local rpc server access, this allows you to control a user's local  client
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    rpc,
    ///
    /// For local rpc server access, this allows you to update a user's activity
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"rpc.activities.write",
    ///
    /// For local rpc server api access, this allows you to receive notifications pushed out to the user
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"rpc.notifications.read",
    ///
    /// For local rpc server access, this allows you to read a user's voice settings and listen for voice events
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"rpc.voice.read",
    ///
    /// For local rpc server access, this allows you to update a user's voice settings
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"rpc.voice.write",
    ///
    /// Allows your app to connect to voice on user's behalf and see all the voice members
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    voice,
    /// Generate a webhook that is returned in the oauth token response for authorization code grants
    @"webhook.incoming",
};

/// https://discord.com/developers/docs/resources/guild#integration-object-integration-structure
pub const Integration = struct {
    /// Integration Id
    id: []const u8,
    /// Integration name
    name: []const u8,
    /// Integration type (twitch, youtube, discord, or guild_subscription).
    type: union(enum) {
        twitch,
        youtube,
        discord,
    },
    /// Is this integration enabled
    enabled: ?bool,
    /// Is this integration syncing
    syncing: ?bool,
    /// Role Id that this integration uses for "subscribers"
    role_id: ?[]const u8,
    /// Whether emoticons should be synced for this integration (twitch only currently)
    enable_emoticons: ?bool,
    /// The behavior of expiring subscribers
    expire_behavior: ?IntegrationExpireBehaviors,
    /// The grace period (in days) before expiring subscribers
    expire_grace_period: ?isize,
    /// When this integration was last synced
    synced_at: ?[]const u8,
    /// How many subscribers this integration has
    subscriber_count: ?isize,
    /// Has this integration been revoked
    revoked: ?bool,
    /// User for this integration
    user: ?User,
    /// Integration account information
    account: IntegrationAccount,
    /// The bot/OAuth2 application for discord integrations
    application: ?IntegrationApplication,
    /// the scopes the application has been authorized for
    scopes: []OAuth2Scope,
};

/// https://discord.com/developers/docs/resources/guild#integration-account-object-integration-account-structure
pub const IntegrationAccount = struct {
    /// Id of the account
    id: []const u8,
    /// Name of the account
    name: []const u8,
};

/// https://discord.com/developers/docs/resources/guild#integration-application-object-integration-application-structure
pub const IntegrationApplication = struct {
    /// The id of the app
    id: []const u8,
    /// The name of the app
    name: []const u8,
    /// the icon hash of the app
    icon: ?[]const u8,
    /// The description of the app
    description: []const u8,
    /// The bot associated with this application
    bot: ?User,
};

/// https://github.com/discord/discord-api-docs/blob/master/docs/topics/Gateway.md#integration-create-event-additional-fields
pub const IntegrationCreateUpdate = struct {
    /// Integration Id
    id: []const u8,
    /// Integration name
    name: []const u8,
    /// Integration type (twitch, youtube, discord, or guild_subscription).
    type: union(enum) {
        twitch,
        youtube,
        discord,
    },
    /// Is this integration enabled
    enabled: ?bool,
    /// Is this integration syncing
    syncing: ?bool,
    /// Role Id that this integration uses for "subscribers"
    role_id: ?[]const u8,
    /// Whether emoticons should be synced for this integration (twitch only currently)
    enable_emoticons: ?bool,
    /// The behavior of expiring subscribers
    expire_behavior: ?IntegrationExpireBehaviors,
    /// The grace period (in days) before expiring subscribers
    expire_grace_period: ?isize,
    /// When this integration was last synced
    synced_at: ?[]const u8,
    /// How many subscribers this integration has
    subscriber_count: ?isize,
    /// Has this integration been revoked
    revoked: ?bool,
    /// User for this integration
    user: ?User,
    /// Integration account information
    account: IntegrationAccount,
    /// The bot/OAuth2 application for discord integrations
    application: ?IntegrationApplication,
    /// the scopes the application has been authorized for
    scopes: []OAuth2Scope,
    /// Id of the guild
    guild_id: []const u8,
};

/// https://github.com/discord/discord-api-docs/blob/master/docs/topics/Gateway.md#integration-delete-event-fields
pub const IntegrationDelete = struct {
    /// Integration id
    id: []const u8,
    /// Id of the guild
    guild_id: []const u8,
    /// Id of the bot/OAuth2 application for this discord integration
    application_id: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway#guild-integrations-update
pub const GuildIntegrationsUpdate = struct {
    /// id of the guild whose integrations were updated
    guild_id: []const u8,
};

/// https://discord.com/developers/docs/topics/gateway#typing-start
pub const TypingStart = struct {
    /// Unix time (in seconds) of when the user started typing
    timestamp: isize,
    /// id of the channel
    channel_id: []const u8,
    /// id of the guild
    guild_id: ?[]const u8,
    /// id of the user
    user_id: []const u8,
    /// The member who started typing if this happened in a guild
    member: ?Member,
};

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

/// https://discord.com/developers/docs/resources/user#avatar-decoration-data-object
pub const AvatarDecorationData = struct {
    /// the avatar decoration hash
    asset: []const u8,
    /// id of the avatar decoration's SKU
    sku_id: []const u8,
};

/// https://discord.com/developers/docs/resources/application#application-object
pub const Application = struct {
    /// The name of the app
    name: []const u8,
    /// The description of the app
    description: []const u8,
    /// An array of rpc origin urls, if rpc is enabled
    rpc_origins: []?[]const u8,
    /// The url of the app's terms of service
    terms_of_service_url: ?[]const u8,
    /// The url of the app's privacy policy
    privacy_policy_url: ?[]const u8,
    /// The hex encoded key for verification in interactions and the GameSDK's GetTicket
    verify_key: []const u8,
    ///If this application is a game sold on , this field will be the id of the "Game SKU" that is created, if exists
    primary_sku_id: ?[]const u8,
    ///If this application is a game sold on , this field will be the URL slug that links to the store page
    slug: ?[]const u8,
    /// The application's public flags
    flags: ?ApplicationFlags,
    /// The id of the app
    id: []const u8,
    /// The icon hash of the app
    icon: ?[]const u8,
    /// When false only app owner can join the app's bot to guilds
    bot_public: bool,
    /// When true the app's bot will only join upon completion of the full oauth2 code grant flow
    bot_require_code_grant: bool,
    /// Partial user object containing info on the owner of the application
    owner: ?Partial(User),
    /// If the application belongs to a team, this will be a list of the members of that team
    team: ?Team,
    /// Guild associated with the app. For example, a developer support server.
    guild_id: ?[]const u8,
    /// A partial object of the associated guild
    guild: ?Partial(Guild),
    ///If this application is a game sold on , this field will be the hash of the image on store embeds
    cover_image: ?[]const u8,
    /// up to 5 tags describing the content and functionality of the application
    tags: []?[]const u8,
    /// settings for the application's default in-app authorization link, if enabled
    install_params: ?InstallParams,
    /// Default scopes and permissions for each supported installation context.
    integration_types_config: ?Partial(AutoHashMapUnmanaged(ApplicationIntegrationType, ApplicationIntegrationTypeConfiguration)),
    /// the application's default custom authorization link, if enabled
    custom_install_url: ?[]const u8,
    /// the application's role connection verification entry point, which when configured will render the app as a verification method in the guild role verification configuration
    role_connections_verification_url: ?[]const u8,
    /// An approximate count of the app's guild membership.
    approximate_guild_count: ?isize,
    /// Approximate count of users that have installed the app.
    approximate_user_install_count: ?isize,
    /// Partial user object for the bot user associated with the app
    bot: ?Partial(User),
    /// Array of redirect URIs for the app
    redirect_uris: []?[]const u8,
    /// Interactions endpoint URL for the app
    interactions_endpoint_url: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/application#application-object-application-integration-type-configuration-object
pub const ApplicationIntegrationTypeConfiguration = struct {
    ///
    /// Install params for each installation context's default in-app authorization link
    ///
    /// https://discord.com/developers/docs/resources/application#install-params-object-install-params-structure
    ///
    oauth2_install_params: ?InstallParams,
};

pub const ApplicationIntegrationType = enum(u4) {
    /// App is installable to servers
    GuildInstall = 0,
    /// App is installable to users
    UserInstall = 1,
};

/// TODO: implement
pub const TokenExchange = null;

pub const TokenExchangeAuthorizationCode = struct {
    grant_type: []const u8, //"authorization_code",
    /// The code for the token exchange
    code: []const u8,
    /// The redirect_uri associated with this authorization
    redirect_uri: []const u8,
};

/// https://discord.com/developers/docs/topics/oauth2#client-credentials-grant
pub const TokenExchangeRefreshToken = struct {
    grant_type: "refresh_token",
    /// the user's refresh token
    refresh_token: []const u8,
};

/// https://discord.com/developers/docs/topics/oauth2#client-credentials-grant
pub const TokenExchangeClientCredentials = struct {
    grant_type: "client_credentials",
    /// The scope(s) for the access token
    scope: []OAuth2Scope,
};

pub const AccessTokenResponse = struct {
    /// The access token of the user
    access_token: []const u8,
    /// The type of token
    token_type: []const u8,
    /// The isize of seconds after that the access token is expired
    expires_in: isize,
    ///
    /// The refresh token to refresh the access token
    ///
    /// @remarks
    /// When the token exchange is a client credentials type grant this value is not defined.
    ///
    refresh_token: []const u8,
    /// The scopes for the access token
    scope: []const u8,
    /// The webhook the user created for the application. Requires the `webhook.incoming` scope
    webhook: ?IncomingWebhook,
    /// The guild the bot has been added. Requires the `bot` scope
    guild: ?Guild,
};

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
    id: []const u8,
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
    metadata: AutoHashMapUnmanaged([]const u8, []const u8),
};

/// https://discord.com/developers/docs/topics/teams#data-models-team-object
pub const Team = struct {
    /// Hash of the image of the team's icon
    icon: ?[]const u8,
    /// Unique ID of the team
    id: []const u8,
    /// Members of the team
    members: []TeamMember,
    /// User ID of the current team owner
    owner_user_id: []const u8,
    /// Name of the team
    name: []const u8,
};

/// https://discord.com/developers/docs/topics/teams#data-models-team-members-object
pub const TeamMember = struct {
    /// The user's membership state on the team
    membership_state: TeamMembershipStates,
    /// The id of the parent team of which they are a member
    team_id: []const u8,
    /// The avatar, discriminator, id, username, and global_name of the user
    /// TODO: needs fixing
    user: struct {
        /// Unique ID of the user
        id: []const u8,
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

/// https://discord.com/developers/docs/topics/gateway#webhooks-update-webhook-update-event-fields
pub const WebhookUpdate = struct {
    /// id of the guild
    guild_id: []const u8,
    /// id of the channel
    channel_id: []const u8,
};

/// https://discord.com/developers/docs/resources/channel#allowed-mentions-object
pub const AllowedMentions = struct {
    /// An array of allowed mention types to parse from the content.
    parse: []?AllowedMentionsTypes,
    /// For replies, whether to mention the author of the message being replied to (default false)
    replied_user: ?bool,
    /// Array of role_ids to mention (Max size of 100)
    roles: []?[]const u8,
    /// Array of user_ids to mention (Max size of 100)
    users: []?[]const u8,
};

/// https://discord.com/developers/docs/resources/channel#embed-object
pub const Embed = struct {
    /// Title of embed
    title: ?[]const u8,
    /// Type of embed (always "rich" for webhook embeds)
    type: ?EmbedTypes,
    /// Description of embed
    description: ?[]const u8,
    /// Url of embed
    url: ?[]const u8,
    /// Color code of the embed
    color: ?isize,
    /// Timestamp of embed content
    timestamp: ?[]const u8,
    /// Footer information
    footer: ?EmbedFooter,
    /// Image information
    image: ?EmbedImage,
    /// Thumbnail information
    thumbnail: ?EmbedThumbnail,
    /// Video information
    video: ?EmbedVideo,
    /// Provider information
    provider: ?EmbedProvider,
    /// Author information
    author: ?EmbedAuthor,
    /// Fields information
    fields: []?EmbedField,
};

/// https://discord.com/developers/docs/resources/channel#embed-object-embed-author-structure
pub const EmbedAuthor = struct {
    /// Name of author
    name: []const u8,
    /// Url of author
    url: ?[]const u8,
    /// Url of author icon (only supports http(s) and attachments)
    icon_url: ?[]const u8,
    /// A proxied url of author icon
    proxy_icon_url: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/channel#embed-object-embed-field-structure
pub const EmbedField = struct {
    /// Name of the field
    name: []const u8,
    /// Value of the field
    value: []const u8,
    /// Whether or not this field should display inline
    @"inline": ?bool,
};

/// https://discord.com/developers/docs/resources/channel#embed-object-embed-footer-structure
pub const EmbedFooter = struct {
    /// Footer text
    text: []const u8,
    /// Url of footer icon (only supports http(s) and attachments)
    icon_url: ?[]const u8,
    /// A proxied url of footer icon
    proxy_icon_url: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/channel#embed-object-embed-image-structure
pub const EmbedImage = struct {
    /// Source url of image (only supports http(s) and attachments)
    url: []const u8,
    /// A proxied url of the image
    proxy_url: ?[]const u8,
    /// Height of image
    height: ?isize,
    /// Width of image
    width: ?isize,
};

pub const EmbedProvider = struct {
    /// Name of provider
    name: ?[]const u8,
    /// Url of provider
    url: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/channel#embed-object-embed-thumbnail-structure
pub const EmbedThumbnail = struct {
    /// Source url of thumbnail (only supports http(s) and attachments)
    url: []const u8,
    /// A proxied url of the thumbnail
    proxy_url: ?[]const u8,
    /// Height of thumbnail
    height: ?isize,
    /// Width of thumbnail
    width: ?isize,
};

/// https://discord.com/developers/docs/resources/channel#embed-object-embed-video-structure
pub const EmbedVideo = struct {
    /// Source url of video
    url: ?[]const u8,
    /// A proxied url of the video
    proxy_url: ?[]const u8,
    /// Height of video
    height: ?isize,
    /// Width of video
    width: ?isize,
};

/// https://discord.com/developers/docs/resources/channel#attachment-object
pub const Attachment = struct {
    /// Name of file attached
    filename: []const u8,
    /// The title of the file
    title: ?[]const u8,
    /// The attachment's [media type](https://en.wikipedia.org/wiki/Media_type)
    content_type: ?[]const u8,
    /// Size of file in bytes
    size: isize,
    /// Source url of file
    url: []const u8,
    /// A proxied url of file
    proxy_url: []const u8,
    /// Attachment id
    id: []const u8,
    /// description for the file (max 1024 characters)
    description: ?[]const u8,
    /// Height of file (if image)
    height: ?isize,
    /// Width of file (if image)
    width: ?isize,
    /// whether this attachment is ephemeral. Ephemeral attachments will automatically be removed after a set period of time. Ephemeral attachments on messages are guaranteed to be available as long as the message itself exists.
    ephemeral: ?bool,
    /// The duration of the audio file for a voice message
    duration_secs: ?isize,
    /// A base64 encoded bytearray representing a sampled waveform for a voice message
    waveform: ?[]const u8,
    /// Attachment flags combined as a bitfield
    flags: ?AttachmentFlags,
};

/// https://discord.com/developers/docs/resources/webhook#webhook-object-webhook-structure
/// TODO: implement
pub const Webhook = null;

pub const IncomingWebhook = struct {
    /// The type of the webhook
    type: WebhookTypes,
    /// The secure token of the webhook (returned for Incoming Webhooks)
    token: ?[]const u8,
    /// The url used for executing the webhook (returned by the webhooks OAuth2 flow)
    url: ?[]const u8,

    /// The id of the webhook
    id: []const u8,
    /// The guild id this webhook is for
    guild_id: ?[]const u8,
    /// The channel id this webhook is for
    channel_id: []const u8,
    /// The user this webhook was created by (not returned when getting a webhook with its token)
    user: ?User,
    /// The default name of the webhook
    name: ?[]const u8,
    /// The default user avatar hash of the webhook
    avatar: ?[]const u8,
    /// The bot/OAuth2 application that created this webhook
    application_id: ?[]const u8,
    /// The guild of the channel that this webhook is following (returned for Channel Follower Webhooks)
    source_guild: ?Partial(Guild),
    /// The channel that this webhook is following (returned for Channel Follower Webhooks)
    source_channel: ?Partial(Channel),
};

pub const ApplicationWebhook = struct {
    /// The type of the webhook
    type: WebhookTypes.Application,
    /// The secure token of the webhook (returned for Incoming Webhooks)
    token: ?[]const u8,
    /// The url used for executing the webhook (returned by the webhooks OAuth2 flow)
    url: ?[]const u8,

    /// The id of the webhook
    id: []const u8,
    /// The guild id this webhook is for
    guild_id: ?[]const u8,
    /// The channel id this webhook is for
    channel_id: ?[]const u8,
    /// The user this webhook was created by (not returned when getting a webhook with its token)
    user: ?User,
    /// The default name of the webhook
    name: ?[]const u8,
    /// The default user avatar hash of the webhook
    avatar: ?[]const u8,
    /// The bot/OAuth2 application that created this webhook
    application_id: ?[]const u8,
    /// The guild of the channel that this webhook is following (returned for Channel Follower Webhooks), field will be absent if the webhook creator has since lost access to the guild where the followed channel resides
    source_guild: ?Partial(Guild),
    /// The channel that this webhook is following (returned for Channel Follower Webhooks), field will be absent if the webhook creator has since lost access to the guild where the followed channel resides
    source_channel: ?Partial(Channel),
};

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
    id: []const u8,
    /// Icon hash
    icon: ?[]const u8,
    /// Icon hash, returned when in the template object
    icon_hash: ?[]const u8,
    /// Splash hash
    splash: ?[]const u8,
    /// Discovery splash hash; only present for guilds with the "DISCOVERABLE" feature
    discovery_splash: ?[]const u8,
    /// Id of the owner
    owner_id: []const u8,
    /// Total permissions for the user in the guild (excludes overwrites and implicit permissions)
    permissions: ?[]const u8,
    /// Id of afk channel
    afk_channel_id: ?[]const u8,
    /// The channel id that the widget will generate an invite to, or null if set to no invite
    widget_channel_id: ?[]const u8,
    /// Roles in the guild
    roles: []Role,
    /// Custom guild emojis
    emojis: []Emoji,
    /// Application id of the guild creator if it is bot-created
    application_id: ?[]const u8,
    /// The id of the channel where guild notices such as welcome messages and boost events are posted
    system_channel_id: ?[]const u8,
    /// The id of the channel where community guilds can display rules and/or guidelines
    rules_channel_id: ?[]const u8,
    /// When this guild was joined at
    joined_at: ?[]const u8,
    /// States of members currently in voice channels; lacks the guild_id key
    voice_states: []?Omit(VoiceState, .{"guildId"}),
    /// Users in the guild
    members: []?Member,
    /// Channels in the guild
    channels: []?Channel,
    /// All active threads in the guild that the current user has permission to view
    threads: []?Channel,
    /// Presences of the members in the guild, will only include non-offline members if the size is greater than large threshold
    presences: []?Partial(PresenceUpdate),
    /// Banner hash
    banner: ?[]const u8,
    ///The preferred locale of a Community guild; used in server discovery and notices from ; defaults to "en-US"
    preferred_locale: []const u8,
    ///The id of the channel where admins and moderators of Community guilds receive notices from
    public_updates_channel_id: ?[]const u8,
    /// The welcome screen of a Community guild, shown to new members, returned in an Invite's guild object
    welcome_screen: ?WelcomeScreen,
    /// Stage instances in the guild
    stage_instances: []?StageInstance,
    /// Custom guild stickers
    stickers: []?Sticker,
    ///The id of the channel where admins and moderators of Community guilds receive safety alerts from
    safety_alerts_channel_id: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/permissions#role-object-role-structure
pub const Role = struct {
    /// Role id
    id: []const u8,
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
    bot_id: ?[]const u8,
    /// The id of the integration this role belongs to
    integration_id: ?[]const u8,
    /// Whether this is the guild's premium subscriber role
    /// Tags with type ?bool represent booleans. They will be present and set to null if they are "true", and will be not present if they are "false".
    premium_subscriber: ?bool,
    /// Id of this role's subscription sku and listing.
    subscription_listing_id: ?[]const u8,
    /// Whether this role is available for purchase.
    /// Tags with type ?bool represent booleans. They will be present and set to null if they are "true", and will be not present if they are "false".
    available_for_purchase: ?bool,
    /// Whether this is a guild's linked role
    /// Tags with type ?bool represent booleans. They will be present and set to null if they are "true", and will be not present if they are "false".
    guild_connections: ?bool,
};

/// https://discord.com/developers/docs/resources/emoji#emoji-object-emoji-structure
pub const Emoji = struct {
    /// Emoji name (can only be null in reaction emoji objects)
    name: ?[]const u8,
    /// Emoji id
    id: ?[]const u8,
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

/// https://discord.com/developers/docs/resources/voice#voice-state-object-voice-state-structure
pub const VoiceState = struct {
    /// The session id for this voice state
    session_id: []const u8,
    /// The guild id this voice state is for
    guild_id: ?[]const u8,
    /// The channel id this user is connected to
    channel_id: ?[]const u8,
    /// The user id this voice state is for
    user_id: []const u8,
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

/// https://discord.com/developers/docs/resources/channel#channel-object
pub const Channel = struct {
    /// The id of the channel
    id: []const u8,
    /// The type of channel
    type: ChannelTypes,
    /// The id of the guild
    guild_id: ?[]const u8,
    /// Sorting position of the channel (channels with the same position are sorted by id)
    position: ?isize,
    /// Explicit permission overwrites for members and roles
    permission_overwrites: []?Overwrite,
    /// The name of the channel (1-100 characters)
    name: ?[]const u8,
    /// The channel topic (0-4096 characters for GUILD_FORUM channels, 0-1024 characters for all others)
    topic: ?[]const u8,
    /// Whether the channel is nsfw
    nsfw: ?bool,
    /// The id of the last message sent in this channel (may not point to an existing or valid message)
    last_message_id: ?[]const u8,
    /// The bitrate (in bits) of the voice or stage channel
    bitrate: ?isize,
    /// The user limit of the voice or stage channel
    user_limit: ?isize,
    /// Amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission `manage_messages` or `manage_channel`, are unaffected
    rate_limit_per_user: ?isize,
    /// the recipients of the DM
    recipients: []?User,
    /// icon hash of the group DM
    icon: ?[]const u8,
    /// Id of the creator of the thread
    owner_id: ?[]const u8,
    /// Application id of the group DM creator if it is bot-created
    application_id: ?[]const u8,
    /// For group DM channels: whether the channel is managed by an application via the `gdm.join` OAuth2 scope.,
    managed: ?bool,
    /// For guild channels: Id of the parent category for a channel (each parent category can contain up to 50 channels), for threads: id of the text channel this thread was created,
    parent_id: ?[]const u8,
    /// When the last pinned message was pinned. This may be null in events such as GUILD_CREATE when a message is not pinned.
    last_pin_timestamp: ?[]const u8,
    /// Voice region id for the voice or stage channel, automatic when set to null
    rtc_region: ?[]const u8,
    /// The camera video quality mode of the voice channel, 1 when not present
    video_quality_mode: ?VideoQualityModes,
    /// An approximate count of messages in a thread, stops counting at 50
    message_count: ?isize,
    /// An approximate count of users in a thread, stops counting at 50
    member_count: ?isize,
    /// Thread-specific fields not needed by other channels
    thread_metadata: ?ThreadMetadata,
    /// Thread member object for the current user, if they have joined the thread, only included on certain API endpoints
    member: ?ThreadMember,
    /// Default duration for newly created threads, in minutes, to automatically archive the thread after recent activity, can be set to: 60, 1440, 4320, 10080,
    default_auto_archive_duration: ?isize,
    /// computed permissions for the invoking user in the channel, including overwrites, only included when part of the resolved data received on a slash command interaction. This does not include implicit permissions, which may need to be checked separately.
    permissions: ?[]const u8,
    /// The flags of the channel
    flags: ?ChannelFlags,
    /// isize of messages ever sent in a thread, it's similar to `message_count` on message creation, but will not decrement the isize when a message is deleted
    total_message_sent: ?isize,
    /// The set of tags that can be used in a GUILD_FORUM channel
    available_tags: []?ForumTag,
    /// The IDs of the set of tags that have been applied to a thread in a GUILD_FORUM channel
    applied_tags: []?[]const u8,
    /// the emoji to show in the add reaction button on a thread in a GUILD_FORUM channel
    default_reaction_emoji: ?DefaultReactionEmoji,
    /// the initial rate_limit_per_user to set on newly created threads in a channel. this field is copied to the thread at creation time and does not live update.
    default_thread_rate_limit_per_user: ?isize,
    /// the default sort order type used to order posts in GUILD_FORUM channels. Defaults to null, which indicates a preferred sort order hasn't been set by a channel admin
    default_sort_order: ?SortOrderTypes,
    /// the default forum layout view used to display posts in `GUILD_FORUM` channels. Defaults to `0`, which indicates a layout view has not been set by a channel admin
    default_forum_layout: ?ForumLayout,
    /// When a thread is created this will be true on that channel payload for the thread.
    newly_created: ?bool,
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
    guild_id: []const u8,
    /// User's current activities
    activities: []Activity,
    /// User's platform-dependent status
    client_status: ClientStatus,
};

/// https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-structure
pub const WelcomeScreen = struct {
    /// The server description shown in the welcome screen
    description: ?[]const u8,
    /// The channels shown in the welcome screen, up to 5
    welcome_channels: []WelcomeScreenChannel,
};

/// https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-channel-structure
pub const WelcomeScreenChannel = struct {
    /// The description shown for the channel
    description: []const u8,
    /// The channel's id
    channel_id: []const u8,
    /// The emoji id, if the emoji is custom
    emoji_id: ?[]const u8,
    /// The emoji name if custom, the unicode character if standard, or `null` if no emoji is set
    emoji_name: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/stage-instance#auto-closing-stage-instance-structure
pub const StageInstance = struct {
    /// The topic of the Stage instance (1-120 characters)
    topic: []const u8,
    /// The id of this Stage instance
    id: []const u8,
    /// The guild id of the associated Stage channel
    guild_id: []const u8,
    /// The id of the associated Stage channel
    channel_id: []const u8,
    /// The id of the scheduled event for this Stage instance
    guild_scheduled_event_id: ?[]const u8,
};

pub const ThreadMetadata = struct {
    /// Whether the thread is archived
    archived: bool,
    /// Duration in minutes to automatically archive the thread after recent activity
    auto_archive_duration: isize,
    /// When a thread is locked, only users with `MANAGE_THREADS` can unarchive it
    locked: bool,
    /// whether non-moderators can add other non-moderators to a thread; only available on private threads
    invitable: ?bool,
    /// Timestamp when the thread's archive status was last changed, used for calculating recent activity
    archive_timestamp: []const u8,
    /// Timestamp when the thread was created; only populated for threads created after 2022-01-09
    create_timestamp: ?[]const u8,
};

pub const ThreadMember = struct {
    /// Any user-thread settings, currently only used for notifications
    flags: isize,
    /// The id of the thread
    id: []const u8,
    /// The id of the user
    user_id: []const u8,
    /// The time the current user last joined the thread
    join_timestamp: []const u8,
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
    application_id: ?[]const u8,
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
    application_id: []const u8,
    /// Activity Instance ID
    instance_id: []const u8,
    /// Unique identifier for the launch
    launch_id: []const u8,
    /// The Location the instance is runnning in
    location: ActivityLocation,
    /// The IDs of the Users currently connected to the instance
    users: [][]const u8,
};

/// https://discord.com/developers/docs/resources/application#get-application-activity-instance-activity-location-object
pub const ActivityLocation = struct {
    /// The unique identifier for the location
    id: []const u8,
    /// Enum describing kind of location
    kind: ActivityLocationKind,
    /// The id of the Channel
    channel_id: []const u8,
    /// The id of the Guild
    guild_id: ?[]const u8,
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
    id: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway#activity-object-activity-party
pub const ActivityParty = struct {
    /// Used to show the party's current and maximum size
    size: ?[2]i64,
    /// The id of the party
    id: ?[]const u8,
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

pub const Overwrite = struct {
    /// Either 0 (role) or 1 (member)
    type: OverwriteTypes,
    /// Role or user id
    id: []const u8,
    /// Permission bit set
    allow: ?[]const u8,
    /// Permission bit set
    deny: ?[]const u8,
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

/// TODO: fix this
pub const MessageComponent = isize;

/// https://discord.com/developers/docs/resources/channel#message-object
pub const Message = struct {
    /// id of the message
    id: []const u8,
    /// id of the channel the message was sent in
    channel_id: []const u8,
    ///
    /// id of the guild the message was sent in
    /// Note: For MESSAGE_CREATE and MESSAGE_UPDATE events, the message object may not contain a guild_id or member field since the events are sent directly to the receiving user and the bot who sent the message, rather than being sent through the guild like non-ephemeral messages.,
    ///
    guild_id: ?[]const u8,
    ///
    /// The author of this message (not guaranteed to be a valid user)
    /// Note: The author object follows the structure of the user object, but is only a valid user in the case where the message is generated by a user or bot user. If the message is generated by a webhook, the author object corresponds to the webhook's id, username, and avatar. You can tell if a message is generated by a webhook by checking for the webhook_id on the message object.,
    ///
    author: User,
    ///
    /// Member properties for this message's author
    /// Note: The member object exists in `MESSAGE_CREATE` and `MESSAGE_UPDATE` events from text-based guild channels. This allows bots to obtain real-time member data without requiring bots to store member state in memory.,
    ///
    member: ?Member,
    /// Contents of the message
    content: ?[]const u8,
    /// When this message was sent
    timestamp: []const u8,
    /// When this message was edited (or null if never)
    edited_timestamp: ?[]const u8,
    /// Whether this was a TTS message
    tts: bool,
    /// Whether this message mentions everyone
    mention_everyone: bool,
    ///
    /// Users specifically mentioned in the message
    /// Note: The user objects in the mentions array will only have the partial member field present in `MESSAGE_CREATE` and `MESSAGE_UPDATE` events from text-based guild channels.,
    ///
    mentions: []struct {
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
        id: []const u8,
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
        /// server member
        member: ?Partial(Member),
    },
    /// Roles specifically mentioned in this message
    mention_roles: []?[]const u8,
    ///
    /// Channels specifically mentioned in this message
    /// Note: Not all channel mentions in a message will appear in `mention_channels`. Only textual channels that are visible to everyone in a discoverable guild will ever be included. Only crossposted messages (via Channel Following) currently include `mention_channels` at all. If no mentions in the message meet these requirements, this field will not be sent.,
    ///
    mention_channels: []?ChannelMention,
    /// Any attached files
    attachments: []Attachment,
    /// Any embedded content
    embeds: []Embed,
    /// Reactions to the message
    reactions: []?Reaction,
    /// Used for validating a message was sent
    nonce: union(enum) {
        int: ?isize,
        string: []const u8,
    },
    /// Whether this message is pinned
    pinned: bool,
    /// If the message is generated by a webhook, this is the webhook's id
    webhook_id: ?[]const u8,
    /// Type of message
    type: MessageTypes,
    /// Sent with Rich Presence-related chat embeds
    activity: ?MessageActivity,
    /// Sent with Rich Presence-related chat embeds
    application: ?Partial(Application),
    /// if the message is an Interaction or application-owned webhook, this is the id of the application
    application_id: ?[]const u8,
    /// Data showing the source of a crosspost, channel follow add, pin, or reply message
    message_reference: ?Omit(MessageReference, .{"failIfNotExists"}),
    /// Message flags combined as a bitfield
    flags: ?MessageFlags,
    ///
    /// The stickers sent with the message (bots currently can only receive messages with stickers, not send)
    /// @deprecated
    ///
    stickers: []?Sticker,
    ///
    /// The message associated with the `message_reference`
    /// Note: This field is only returned for messages with a `type` of `19` (REPLY). If the message is a reply but the `referenced_message` field is not present, the backend did not attempt to fetch the message that was being replied to, so its state is unknown. If the field exists but is null, the referenced message was deleted.,
    /// TAKES A POINTER
    referenced_message: ?*Message,
    /// The message associated with the `message_reference`. This is a minimal subset of fields in a message (e.g. `author` is excluded.)
    message_snapshots: []?MessageSnapshot,
    /// sent if the message is sent as a result of an interaction
    interaction_metadata: ?MessageInteractionMetadata,
    ///
    /// Sent if the message is a response to an Interaction
    ///
    /// @deprecated Deprecated in favor of {@link interaction_metadata};
    ///
    interaction: ?MessageInteraction,
    /// The thread that was started from this message, includes thread member object
    thread: ?Omit(Channel, .{"member"}), //& { member: ThreadMember };,
    /// The components related to this message
    components: ?[]MessageComponent,
    /// Sent if the message contains stickers
    sticker_items: []?StickerItem,
    /// A generally increasing integer (there may be gaps or duplicates) that represents the approximate position of the message in a thread, it can be used to estimate the relative position of the message in a thread in company with `total_message_sent` on parent thread
    position: ?isize,
    /// The poll object
    poll: ?Poll,
    /// The call associated with the message
    call: ?MessageCall,
};

/// https://discord.com/developers/docs/resources/channel#message-call-object
pub const MessageCall = struct {
    /// Array of user object ids that participated in the call
    participants: [][]const u8,
    /// Time when call ended
    ended_timestamp: []const u8,
};

/// https://discord.com/developers/docs/resources/channel#channel-mention-object
pub const ChannelMention = struct {
    /// id of the channel
    id: []const u8,
    /// id of the guild containing the channel
    guild_id: []const u8,
    /// The type of channel
    type: isize,
    /// The name of the channel
    name: []const u8,
};

/// https://discord.com/developers/docs/resources/channel#reaction-object
pub const Reaction = struct {
    /// Total isize of times this emoji has been used to react (including super reacts)
    count: isize,
    ///
    count_details: ReactionCountDetails,
    /// Whether the current user reacted using this emoji
    me: bool,
    ///
    me_burst: bool,
    /// Emoji information
    emoji: Partial(Emoji),
    /// HEX colors used for super reaction
    burst_colors: [][]const u8,
};

/// https://discord.com/developers/docs/resources/channel#get-reactions-reaction-types
pub const ReactionType = enum {
    Normal,
    Burst,
};

/// https://discord.com/developers/docs/resources/channel#reaction-count-details-object
pub const ReactionCountDetails = struct {
    /// Count of super reactions
    burst: isize,
    ///
    normal: isize,
};

/// https://discord.com/developers/docs/resources/channel#message-object-message-activity-structure
pub const MessageActivity = struct {
    /// Type of message activity
    type: MessageActivityTypes,
    /// `party_id` from a Rich Presence event
    party_id: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/channel#message-object-message-reference-structure
pub const MessageReference = struct {
    /// Type of reference
    type: ?MessageReferenceType,
    /// id of the originating message
    message_id: ?[]const u8,
    ///
    /// id of the originating message's channel
    /// Note: `channel_id` is optional when creating a reply, but will always be present when receiving an event/response that includes this data model.,
    ///
    channel_id: ?[]const u8,
    /// id of the originating message's guild
    guild_id: ?[]const u8,
    /// When sending, whether to error if the referenced message doesn't exist instead of sending as a normal (non-reply) message, default true
    fail_if_not_exists: bool,
};

/// https://discord.com/developers/docs/resources/channel#message-reference-object-message-reference-types
pub const MessageReferenceType = enum {
    ///
    /// A standard reference used by replies.
    ///
    /// @remarks
    /// When the type is set to this value, the field referenced_message on the message will be present
    ///
    Default,
    ///
    /// Reference used to point to a message at a point in time.
    ///
    /// @remarks
    /// When the type is set to this value, the field message_snapshot on the message will be present
    ///
    /// This value can only be used for basic messages;
    /// i.e. messages which do not have strong bindings to a non global entity.
    /// Thus we support only messages with `DEFAULT` or `REPLY` types, but disallowed if there are any polls, calls, or components.
    ///
    Forward,
};

/// https://discord.com/developers/docs/resources/channel#message-snapshot-object-message-snapshot-structure
pub const MessageSnapshot = struct {
    /// https://discord.com/developers/docs/resources/channel#message-object
    /// Minimal subset of fields in the forwarded message
    message: struct {
        content: ?[]const u8,
        timestamp: []const u8,
        edited_timestamp: ?[]const u8,
        mentions: []struct {
            username: []const u8,
            global_name: ?[]const u8,
            locale: ?[]const u8,
            flags: ?isize,
            premium_type: ?PremiumTypes,
            public_flags: ?isize,
            accent_color: ?isize,
            id: []const u8,
            discriminator: []const u8,
            avatar: ?[]const u8,
            bot: ?bool,
            system: ?bool,
            mfa_enabled: ?bool,
            verified: ?bool,
            email: ?[]const u8,
            banner: ?[]const u8,
            avatar_decoration_data: ?AvatarDecorationData,
            member: ?Partial(Member),
        },
        mention_roles: []?[]const u8,
        type: MessageTypes,
        flags: ?MessageFlags,
        stickers: []?Sticker,
        components: ?[]MessageComponent,
        sticker_items: []?StickerItem,
        attachments: []Attachment,
        embeds: []Embed,
    },
};

/// https://discord.com/developers/docs/resources/poll#poll-object
pub const Poll = struct {
    /// The question of the poll. Only `text` is supported.
    question: PollMedia,
    /// Each of the answers available in the poll. There is a maximum of 10 answers per poll.
    answers: []PollAnswer,
    ///
    /// The time when the poll ends.
    ///
    /// @remarks
    /// `expiry` is marked as nullable to support non-expiring polls in the future, but all polls have an expiry currently.
    ///
    expiry: ?[]const u8,
    /// Whether a user can select multiple answers
    allow_multiselect: bool,
    /// The layout type of the poll
    layout_type: PollLayoutType,
    ///
    /// The results of the poll
    ///
    /// @remarks
    /// This value will not be sent by discord under specific conditions where they don't fetch them on their backend. When this value is missing it should be interpreted as "Unknown results" and not as "No results"
    ///The results may not be totally accurate while the poll has not ended. When it ends discord will re-calculate all the results and set {@link PollResult.is_finalized}; to true
    ///
    results: ?PollResult,
};

/// https://discord.com/developers/docs/resources/poll#layout-type
pub const PollLayoutType = enum(u4) {
    /// The default layout
    Default = 1,
};

/// https://discord.com/developers/docs/resources/poll#poll-media-object
pub const PollMedia = struct {
    ///
    /// The text of the field
    ///
    /// @remarks
    /// `text` should always be non-null for both questions and answers, but this is subject to changes.
    /// The maximum length of `text` is 300 for the question, and 55 for any answer.
    ///
    text: ?[]const u8,
    ///
    /// The emoji of the field
    ///
    /// @remarks
    /// When creating a poll answer with an emoji, one only needs to send either the `id` (custom emoji) or `name` (default emoji) as the only field.
    ///
    emoji: ?Partial(Emoji),
};

/// https://discord.com/developers/docs/resources/poll#poll-answer-object
pub const PollAnswer = struct {
    ///
    /// The id of the answer
    ///
    /// @remarks
    ///This id labels each answer. It starts at 1 and goes up sequentially.  recommend against depending on this value as is a implementation detail.
    ///
    answer_id: isize,
    /// The data of the answer
    poll_media: PollMedia,
};

pub const PollAnswerCount = struct {
    ///The {@link PollAnswer.answer_id | answer_id};
    id: isize,
    /// The isize of votes for this answer
    count: isize,
    /// Whether the current user voted for this answer
    me_voted: bool,
};

/// https://discord.com/developers/docs/resources/poll#poll-results-object
pub const PollResult = struct {
    /// Whether the votes have been precisely counted
    is_finalized: bool,
    /// The counts for each answer
    answer_counts: []PollAnswerCount,
};

/// https://discord.com/developers/docs/resources/poll#get-answer-voters-response-body
pub const GetAnswerVotesResponse = struct {
    /// Users who voted for this answer
    users: []User,
};

/// https://discord.com/developers/docs/topics/gateway-events#message-poll-vote-add
pub const PollVoteAdd = struct {
    /// ID of the user. Usually a snowflake
    user_id: []const u8,
    /// ID of the channel. Usually a snowflake
    channel_id: []const u8,
    /// ID of the message. Usually a snowflake
    message_id: []const u8,
    /// ID of the guild. Usually a snowflake
    guild_id: ?[]const u8,
    /// ID of the answer.
    answer_id: isize,
};

/// https://discord.com/developers/docs/topics/gateway-events#message-poll-vote-remove
pub const PollVoteRemove = struct {
    /// ID of the user. Usually a snowflake
    user_id: []const u8,
    /// ID of the channel. Usually a snowflake
    channel_id: []const u8,
    /// ID of the message. Usually a snowflake
    message_id: []const u8,
    /// ID of the guild. Usually a snowflake
    guild_id: ?[]const u8,
    /// ID of the answer.
    answer_id: isize,
};

/// https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-structure
pub const Sticker = struct {
    /// [Id of the sticker](https://discord.com/developers/docs/reference#image-formatting)
    id: []const u8,
    /// Id of the pack the sticker is from
    pack_id: ?[]const u8,
    /// Name of the sticker
    name: []const u8,
    /// Description of the sticker
    description: []const u8,
    /// a unicode emoji representing the sticker's expression
    tags: []const u8,
    /// [type of sticker](https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-types)
    type: StickerTypes,
    /// [Type of sticker format](https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types)
    format_type: StickerFormatTypes,
    ///  Whether or not the sticker is available
    available: ?bool,
    /// Id of the guild that owns this sticker
    guild_id: ?[]const u8,
    /// The user that uploaded the sticker
    user: ?User,
    /// A sticker's sort order within a pack
    sort_value: ?isize,
};

/// https://discord.com/developers/docs/interactions/receiving-and-responding#message-interaction-object-message-interaction-structure
pub const MessageInteraction = struct {
    /// Id of the interaction
    id: []const u8,
    /// The type of interaction
    type: InteractionTypes,
    /// The name of the ApplicationCommand including the name of the subcommand/subcommand group
    name: []const u8,
    /// The user who invoked the interaction
    user: User,
    /// The member who invoked the interaction in the guild
    member: ?Partial(Member),
};

/// https://discord.com/developers/docs/resources/channel#message-interaction-metadata-object-message-interaction-metadata-structure
pub const MessageInteractionMetadata = struct {
    /// Id of the interaction
    id: []const u8,
    /// The type of interaction
    type: InteractionTypes,
    /// User who triggered the interaction
    user: User,
    /// IDs for installation context(s) related to an interaction
    authorizing_integration_owners: Partial(AutoHashMapUnmanaged(ApplicationIntegrationType, []const u8)),
    /// ID of the original response message, present only on follow-up messages
    original_response_message_id: ?[]const u8,
    /// ID of the message that contained interactive component, present only on messages created from component interactions
    interacted_message_id: ?[]const u8,
    /// Metadata for the interaction that was used to open the modal, present only on modal submit interactions
    /// TAKES A POINTER
    triggering_interaction_metadata: ?*MessageInteractionMetadata,
};

/// https://discord.com/developers/docs/resources/sticker#sticker-item-object-sticker-item-structure
pub const StickerItem = struct {
    /// Id of the sticker
    id: []const u8,
    /// Name of the sticker
    name: []const u8,
    /// [Type of sticker format](https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types)
    format_type: StickerFormatTypes,
};

/// https://discord.com/developers/docs/resources/sticker#sticker-pack-object-sticker-pack-structure
pub const StickerPack = struct {
    /// id of the sticker pack
    id: []const u8,
    /// the stickers in the pack
    stickers: []Sticker,
    /// name of the sticker pack
    name: []const u8,
    /// id of the pack's SKU
    sku_id: []const u8,
    /// id of a sticker in the pack which is shown as the pack's icon
    cover_sticker_id: ?[]const u8,
    /// description of the sticker pack
    description: []const u8,
    /// id of the sticker pack's [banner image](https://discord.com/developers/docs/reference#image-formatting)
    banner_asset_id: ?[]const u8,
};

pub const Interaction = struct {
    /// Id of the interaction
    id: []const u8,
    /// Id of the application this interaction is for
    application_id: []const u8,
    /// The type of interaction
    type: InteractionTypes,
    /// Guild that the interaction was sent from
    guild: ?Partial(Guild),
    /// The guild it was sent from
    guild_id: ?[]const u8,
    /// The channel it was sent from
    channel: Partial(Channel),
    ///
    /// The ID of channel it was sent from
    ///
    /// @remarks
    /// It is recommended that you begin using this channel field to identify the source channel of the interaction as they may deprecate the existing channel_id field in the future.
    ///
    channel_id: ?[]const u8,
    /// Guild member data for the invoking user, including permissions
    member: ?InteractionMember,
    /// User object for the invoking user, if invoked in a DM
    user: ?User,
    /// A continuation token for responding to the interaction
    token: []const u8,
    /// Read-only property, always `1`
    version: 1,
    /// For the message the button was attached to
    message: ?Message,
    /// the command data payload
    data: ?InteractionData,
    /// The selected language of the invoking user
    locale: ?[]const u8,
    /// The guild's preferred locale, if invoked in a guild
    guild_locale: ?[]const u8,
    /// The computed permissions for a bot or app in the context of a specific interaction (including channel overwrites)
    app_permissions: []const u8,
    /// For monetized apps, any entitlements for the invoking user, representing access to premium SKUs
    entitlements: []Entitlement,
    /// Mapping of installation contexts that the interaction was authorized for to related user or guild IDs.
    authorizing_integration_owners: Partial(AutoHashMapUnmanaged(ApplicationIntegrationType, []const u8)),
    /// Context where the interaction was triggered from
    context: ?InteractionContextType,
};

/// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-callback-interaction-callback-response-object
pub const InteractionCallbackResponse = struct {
    /// The interaction object associated with the interaction response
    interaction: InteractionCallback,
    /// The resource that was created by the interaction response.
    resource: ?InteractionResource,
};

/// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-callback-interaction-callback-object
pub const InteractionCallback = struct {
    /// ID of the interaction
    id: []const u8,
    /// Interaction type
    type: InteractionTypes,
    /// Instance ID of the Activity if one was launched or joined
    activity_instance_id: ?[]const u8,
    /// ID of the message that was created by the interaction
    response_message_id: ?[]const u8,
    /// Whether or not the message is in a loading state
    response_message_loading: ?bool,
    /// Whether or not the response message was ephemeral
    response_message_ephemeral: ?bool,
};

/// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-callback-interaction-callback-resource-object
pub const InteractionResource = struct {
    type: InteractionResponseTypes,
    ///
    /// Represents the Activity launched by this interaction.
    ///
    /// @remarks
    /// Only present if type is `LAUNCH_ACTIVITY`.
    ///
    activity_instance: ?ActivityInstanceResource,
    ///
    /// Message created by the interaction.
    ///
    /// @remarks
    /// Only present if type is either `CHANNEL_MESSAGE_WITH_SOURCE` or `UPDATE_MESSAGE`.
    ///
    message: ?Message,
};

/// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-callback-interaction-callback-activity-instance-resource
pub const ActivityInstanceResource = struct {
    /// Instance ID of the Activity if one was launched or joined.
    id: []const u8,
};

/// https://discord.com/developers/docs/resources/guild#guild-member-object
pub const InteractionMember = struct {
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
    /// when the user's timeout will expire and the user will be able to communicate in the guild again (set null to remove timeout), null or a time in the past if the user is not timed out
    communication_disabled_until: ?[]const u8,
    /// Guild member flags
    flags: isize,
    /// data for the member's guild avatar decoration
    avatar_decoration_data: ?AvatarDecorationData,
    /// The user object for this member
    user: User,
    /// Total permissions of the member in the channel, including overwrites, returned when in the interaction object
    permissions: []const u8,
};

pub const InteractionData = struct {
    /// The type of component
    component_type: ?MessageComponentTypes,
    /// The custom id provided for this component.
    custom_id: ?[]const u8,
    /// The components if its a Modal Submit interaction.
    components: ?[]MessageComponent,
    /// The values chosen by the user.
    values: []?[]const u8,
    /// The Id of the invoked command
    id: []const u8,
    /// The name of the invoked command
    name: []const u8,
    /// the type of the invoked command
    type: ApplicationCommandTypes,
    /// Converted users + roles + channels + attachments
    resolved: ?struct {
        /// The Ids and Message objects
        messages: ?AutoHashMapUnmanaged([]const u8, Message),
        /// The Ids and User objects
        users: ?AutoHashMapUnmanaged([]const u8, User),
        /// The Ids and partial Member objects
        members: ?AutoHashMapUnmanaged([]const u8, Omit(InteractionMember, .{ "user", "deaf", "mute" })),
        /// The Ids and Role objects
        roles: ?AutoHashMapUnmanaged([]const u8, Role),
        /// The Ids and partial Channel objects
        channels: ?AutoHashMapUnmanaged([]const u8, struct {
            id: []const u8,
            type: ChannelTypes,
            name: ?[]const u8,
            permissions: ?[]const u8,
        }),
        /// The ids and attachment objects
        attachments: AutoHashMapUnmanaged([]const u8, Attachment),
    },
    /// The params + values from the user
    options: []?InteractionDataOption,
    /// The target id if this is a context menu command.
    target_id: ?[]const u8,
    /// the id of the guild the command is registered to
    guild_id: ?[]const u8,
};

pub const InteractionDataOption = struct {
    /// Name of the parameter
    name: []const u8,
    /// Value of application command option type
    type: ApplicationCommandOptionTypes,
    /// Value of the option resulting from user input
    value: ?union(enum) {
        string: []const u8,
        bool: bool,
        integer: isize,
    },
    /// Present if this option is a group or subcommand
    options: []?InteractionDataOption,
    /// `true` if this option is the currently focused option for autocomplete
    focused: ?bool,
};

pub const ListActiveThreads = struct {
    /// The active threads
    threads: []Channel,
    /// A thread member object for each returned thread the current user has joined
    members: []ThreadMember,
};

pub const ListArchivedThreads = struct {
    /// The active threads
    threads: []Channel,
    /// A thread member object for each returned thread the current user has joined
    members: []ThreadMember,
    /// Whether there are potentially additional threads that could be returned on a subsequent call
    has_more: bool,
};

pub const ThreadListSync = struct {
    /// The id of the guild
    guild_id: []const u8,
    /// The parent channel ids whose threads are being synced. If omitted, then threads were synced for the entire guild. This array may contain channelIds that have no active threads as well, so you know to clear that data
    channel_ids: []?[]const u8,
    /// All active threads in the given channels that the current user can access
    threads: []Channel,
    /// All thread member objects from the synced threads for the current user, indicating which threads the current user has been added to
    members: []ThreadMember,
};

/// https://discord.com/developers/docs/resources/audit-log#audit-log-object
pub const AuditLog = struct {
    /// List of webhooks found in the audit log
    webhooks: []Webhook,
    /// List of users found in the audit log
    users: []User,
    /// List of audit log entries, sorted from most to least recent
    audit_log_entries: []AuditLogEntry,
    /// List of partial integration objects
    integrations: []Partial(Integration),
    ///
    /// List of threads found in the audit log.
    /// Threads referenced in `THREAD_CREATE` and `THREAD_UPDATE` events are included in the threads map since archived threads might not be kept in memory by clients.
    ///
    threads: []Channel,
    /// List of guild scheduled events found in the audit log
    guild_scheduled_events: []?ScheduledEvent,
    /// List of auto moderation rules referenced in the audit log
    auto_moderation_rules: []?AutoModerationRule,
    /// List of application commands referenced in the audit log
    application_commands: []ApplicationCommand,
};

/// https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object
pub const AutoModerationRule = struct {
    /// The id of this rule
    id: []const u8,
    /// The guild id of the rule
    guild_id: []const u8,
    /// The name of the rule
    name: []const u8,
    /// The id of the user who created this rule.
    creator_id: []const u8,
    /// Indicates in what event context a rule should be checked.
    event_type: AutoModerationEventTypes,
    /// The type of trigger for this rule
    trigger_type: AutoModerationTriggerTypes,
    /// The metadata used to determine whether a rule should be triggered.
    trigger_metadata: AutoModerationRuleTriggerMetadata,
    /// Actions which will execute whenever a rule is triggered.
    actions: []AutoModerationAction,
    /// Whether the rule is enabled.
    enabled: bool,
    /// The role ids that are whitelisted. Max 20.
    exempt_roles: [][]const u8,
    /// The channel ids that are whitelisted. Max 50.
    exempt_channels: [][]const u8,
};

pub const AutoModerationEventTypes = enum(u4) {
    /// When a user sends a message
    MessageSend = 1,
    /// Wen a member edits their profile
    MemberUpdate,
};

pub const AutoModerationTriggerTypes = enum(u4) {
    /// Check if content contains words from a user defined list of keywords. Max 6 per guild
    Keyword = 1,
    /// Check if content represents generic spam. Max 1 per guild
    Spam = 3,
    /// Check if content contains words from internal pre-defined word sets. Max 1 per guild
    KeywordPreset,
    /// Check if content contains more unique mentions than allowed. Max 1 per guild
    MentionSpam,
    /// Check if member profile contains words from a user defined list of keywords. Max 1 per guild
    MemberProfile,
};

pub const AutoModerationRuleTriggerMetadata = struct {
    ///
    /// The keywords needed to match.
    ///
    /// @remarks
    /// Only present with {@link AutoModerationTriggerTypes.Keyword}; and {@link AutoModerationTriggerTypes.MemberProfile};.
    ///
    /// Can have up to 1000 elements in the array and each []const u8 can have up to 60 characters
    ///
    keyword_filter: []?[]const u8,
    ///
    /// Regular expression patterns which will be matched against content.
    ///
    /// @remarks
    /// Only present with {@link AutoModerationTriggerTypes.Keyword}; and {@link AutoModerationTriggerTypes.MemberProfile};.
    ///
    /// Can have up to 10 elements in the array and each []const u8 can have up to 260 characters
    ///
    regex_patterns: [][]const u8,
    ///
    /// The pre-defined lists of words to match from.
    ///
    /// @remarks
    /// Only present with {@link AutoModerationTriggerTypes.KeywordPreset};.
    ///
    presets: []?AutoModerationRuleTriggerMetadataPresets,
    ///
    /// The substrings which will exempt from triggering the preset trigger type.
    ///
    /// @remarks
    /// Only present with {@link AutoModerationTriggerTypes.Keyword};, {@link AutoModerationTriggerTypes.KeywordPreset}; and {@link AutoModerationTriggerTypes.MemberProfile};.
    ///
    /// When used with {@link AutoModerationTriggerTypes.Keyword}; and {@link AutoModerationTriggerTypes.MemberProfile}; there can have up to 100 elements in the array and each []const u8 can have up to 60 characters.
    /// When used with {@link AutoModerationTriggerTypes.KeywordPreset}; there can have up to 1000 elements in the array and each []const u8 can have up to 60 characters.
    ///
    allow_list: []?[]const u8,
    ///
    /// Total isize of mentions (role & user) allowed per message.
    ///
    /// @remarks
    /// Only present with {@link AutoModerationTriggerTypes.MentionSpam};.
    ///
    /// Maximum of 50
    ///
    mention_total_limit: ?isize,
    ///
    /// Whether to automatically detect mention raids.
    ///
    /// @remarks
    /// Only present with {@link AutoModerationTriggerTypes.MentionSpam};.
    ///
    mention_raid_protection_enabled: ?bool,
};

pub const AutoModerationRuleTriggerMetadataPresets = enum(u4) {
    /// Words that may be considered forms of swearing or cursing
    Profanity = 1,
    /// Words that refer to sexually explicit behavior or activity
    SexualContent,
    /// Personal insults or words that may be considered hate speech
    Slurs,
};

pub const AutoModerationAction = struct {
    /// The type of action to take when a rule is triggered
    type: AutoModerationActionType,
    /// additional metadata needed during execution for this specific action type
    metadata: AutoModerationActionMetadata,
};

pub const AutoModerationActionType = enum(u4) {
    /// Blocks the content of a message according to the rule
    BlockMessage = 1,
    /// Logs user content to a specified channel
    SendAlertMessage,
    ///
    /// Times out user for specified duration
    ///
    /// @remarks
    /// A timeout action can only be set up for {@link AutoModerationTriggerTypes.Keyword}; and {@link AutoModerationTriggerTypes.MentionSpam}; rules.
    ///
    /// The `MODERATE_MEMBERS` permission is required to use the timeout action type.
    ///
    Timeout,
    /// prevents a member from using text, voice, or other interactions
    BlockMemberInteraction,
};

pub const AutoModerationActionMetadata = struct {
    /// The id of channel to which user content should be logged. Only in ActionType.SendAlertMessage
    channel_id: ?[]const u8,
    /// Additional explanation that will be shown to members whenever their message is blocked. Maximum of 150 characters. Only supported for AutoModerationActionType.BlockMessage
    custom_message: ?[]const u8,
    /// Timeout duration in seconds maximum of 2419200 seconds (4 weeks). Only supported for TriggerType.Keyword && Only in ActionType.Timeout
    duration_seconds: ?isize,
};

/// https://discord.com/developers/docs/topics/gateway-events#auto-moderation-action-execution-auto-moderation-action-execution-event-fields
pub const AutoModerationActionExecution = struct {
    /// The id of the guild
    guild_id: []const u8,
    /// The id of the rule that was executed
    rule_id: []const u8,
    /// The id of the user which generated the content which triggered the rule
    user_id: []const u8,
    /// The content from the user
    content: []const u8,
    /// Action which was executed
    action: AutoModerationAction,
    /// The trigger type of the rule that was executed.
    rule_trigger_type: AutoModerationTriggerTypes,
    /// The id of the channel in which user content was posted
    channel_id: ?[]const u8,
    /// The id of the message. Will not exist if message was blocked by automod or content was not part of any message
    message_id: ?[]const u8,
    /// The id of any system auto moderation messages posted as a result of this action
    alert_system_message_id: ?[]const u8,
    /// The word or phrase that triggerred the rule.
    matched_keyword: ?[]const u8,
    /// The substring in content that triggered the rule
    matched_content: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-audit-log-entry-structure
pub const AuditLogEntry = struct {
    /// ID of the affected entity (webhook, user, role, etc.)
    target_id: ?[]const u8,
    /// Changes made to the `target_id`
    /// TODO: change this
    changes: []?AuditLogChange(noreturn),
    /// User or app that made the changes
    user_id: ?[]const u8,
    /// ID of the entry
    id: []const u8,
    /// Type of action that occurred
    action_type: AuditLogEvents,
    /// Additional info for certain event types
    options: ?OptionalAuditEntryInfo,
    /// Reason for the change (1-512 characters)
    reason: ?[]const u8,
};

pub fn AuditLogChange(comptime T: type) type {
    return T;
}

/// https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-optional-audit-entry-info
pub const OptionalAuditEntryInfo = struct {
    ///
    /// ID of the app whose permissions were targeted.
    ///
    /// Event types: `APPLICATION_COMMAND_PERMISSION_UPDATE`,
    ///
    application_id: ?[]const u8,
    ///
    /// Name of the Auto Moderation rule that was triggered.
    ///
    /// Event types: `AUTO_MODERATION_BLOCK_MESSAGE`, `AUTO_MODERATION_FLAG_TO_CHANNEL`, `AUTO_MODERATION_USER_COMMUNICATION_DISABLED`,
    ///
    auto_moderation_rule_name: ?[]const u8,
    ///
    /// Trigger type of the Auto Moderation rule that was triggered.
    ///
    /// Event types: `AUTO_MODERATION_BLOCK_MESSAGE`, `AUTO_MODERATION_FLAG_TO_CHANNEL`, `AUTO_MODERATION_USER_COMMUNICATION_DISABLED`,
    ///
    auto_moderation_rule_trigger_type: ?[]const u8,
    ///
    /// Channel in which the entities were targeted.
    ///
    /// Event types: `MEMBER_MOVE`, `MESSAGE_PIN`, `MESSAGE_UNPIN`, `MESSAGE_DELETE`, `STAGE_INSTANCE_CREATE`, `STAGE_INSTANCE_UPDATE`, `STAGE_INSTANCE_DELETE`,
    ///
    channel_id: ?[]const u8,
    ///
    /// isize of entities that were targeted.
    ///
    /// Event types: `MESSAGE_DELETE`, `MESSAGE_BULK_DELETE`, `MEMBER_DISCONNECT`, `MEMBER_MOVE`,
    ///
    count: ?[]const u8,
    ///
    /// isize of days after which inactive members were kicked.
    ///
    /// Event types: `MEMBER_PRUNE`,
    ///
    delete_member_days: ?[]const u8,
    ///
    /// ID of the overwritten entity.
    ///
    /// Event types: `CHANNEL_OVERWRITE_CREATE`, `CHANNEL_OVERWRITE_UPDATE`, `CHANNEL_OVERWRITE_DELETE`,
    ///
    id: ?[]const u8,
    ///
    /// isize of members removed by the prune.
    ///
    /// Event types: `MEMBER_PRUNE`,
    ///
    members_removed: ?[]const u8,
    ///
    /// ID of the message that was targeted.
    ///
    /// Event types: `MESSAGE_PIN`, `MESSAGE_UNPIN`, `STAGE_INSTANCE_CREATE`, `STAGE_INSTANCE_UPDATE`, `STAGE_INSTANCE_DELETE`,
    ///
    message_id: ?[]const u8,
    ///
    /// Name of the role if type is "0" (not present if type is "1").
    ///
    /// Event types: `CHANNEL_OVERWRITE_CREATE`, `CHANNEL_OVERWRITE_UPDATE`, `CHANNEL_OVERWRITE_DELETE`,
    ///
    role_name: ?[]const u8,
    ///
    /// Type of overwritten entity - "0", for "role", or "1" for "member".
    ///
    /// Event types: `CHANNEL_OVERWRITE_CREATE`, `CHANNEL_OVERWRITE_UPDATE`, `CHANNEL_OVERWRITE_DELETE`,
    ///
    type: ?[]const u8,
    ///
    /// The type of integration which performed the action
    ///
    /// Event types: `MEMBER_KICK`, `MEMBER_ROLE_UPDATE`,
    ///
    integration_type: ?[]const u8,
};

pub const ScheduledEvent = struct {
    /// the id of the scheduled event
    id: []const u8,
    /// the guild id which the scheduled event belongs to
    guild_id: []const u8,
    /// the channel id in which the scheduled event will be hosted if specified
    channel_id: ?[]const u8,
    /// the id of the user that created the scheduled event
    creator_id: ?[]const u8,
    /// the name of the scheduled event
    name: []const u8,
    /// the description of the scheduled event
    description: ?[]const u8,
    /// the time the scheduled event will start
    scheduled_start_time: []const u8,
    /// the time the scheduled event will end if it does end.
    scheduled_end_time: ?[]const u8,
    /// the privacy level of the scheduled event
    privacy_level: ScheduledEventPrivacyLevel,
    /// the status of the scheduled event
    status: ScheduledEventStatus,
    /// the type of hosting entity associated with a scheduled event
    entity_type: ScheduledEventEntityType,
    /// any additional id of the hosting entity associated with event
    entity_id: ?[]const u8,
    /// the entity metadata for the scheduled event
    entity_metadata: ?ScheduledEventEntityMetadata,
    /// the user that created the scheduled event
    creator: ?User,
    /// the isize of users subscribed to the scheduled event
    user_count: ?isize,
    /// the cover image hash of the scheduled event
    image: ?[]const u8,
    /// the definition for how often this event should recur
    recurrence_rule: ?ScheduledEventRecurrenceRule,
};

pub const ScheduledEventEntityMetadata = struct {
    /// location of the event
    location: ?[]const u8,
};

pub const ScheduledEventRecurrenceRule = struct {
    /// Starting time of the recurrence interval
    start: []const u8,
    /// Ending time of the recurrence interval
    end: ?[]const u8,
    /// How often the event occurs
    frequency: ScheduledEventRecurrenceRuleFrequency,
    /// The spacing between the events, defined by `frequency`. For example, `frequency` of `Weekly` and an `interval` of `2` would be "every-other week"
    interval: isize,
    /// Set of specific days within a week for the event to recur on
    by_weekday: []?ScheduledEventRecurrenceRuleWeekday,
    /// List of specific days within a specific week (1-5) to recur on
    by_n_weekday: []?ScheduledEventRecurrenceRuleNWeekday,
    /// Set of specific months to recur on
    by_month: []?ScheduledEventRecurrenceRuleMonth,
    /// Set of specific dates within a month to recur on
    by_month_day: []?isize,
    /// Set of days within a year to recur on (1-364)
    by_year_day: []?isize,
    /// The total amount of times that the event is allowed to recur before stopping
    count: ?isize,
};

pub const ScheduledEventRecurrenceRuleFrequency = enum {
    Yearly,
    Monthly,
    Weekly,
    Daily,
};

pub const ScheduledEventRecurrenceRuleWeekday = enum {
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
    Sunday,
};

pub const ScheduledEventRecurrenceRuleNWeekday = struct {
    /// The week to reoccur on. 1 - 5
    n: isize,
    /// The day within the week to reoccur on
    day: ScheduledEventRecurrenceRuleWeekday,
};

pub const ScheduledEventRecurrenceRuleMonth = enum(u4) {
    January = 1,
    February,
    March,
    April,
    May,
    June,
    July,
    August,
    September,
    October,
    November,
    December,
};

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

/// https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-structure
pub const ApplicationCommand = struct {
    /// Type of command, defaults to `ApplicationCommandTypes.ChatInput`
    type: ?ApplicationCommandTypes,
    ///
    /// Name of command, 1-32 characters.
    /// `ApplicationCommandTypes.ChatInput` command names must match the following regex `^[-_\p{L};\p{N};\p{sc=Deva};\p{sc=Thai};]{1,32};$` with the unicode flag set.
    /// If there is a lowercase variant of any letters used, you must use those.
    /// Characters with no lowercase variants and/or uncased letters are still allowed.
    /// ApplicationCommandTypes.User` and `ApplicationCommandTypes.Message` commands may be mixed case and can include spaces.
    ///
    name: []const u8,
    /// Localization object for `name` field. Values follow the same restrictions as `name`
    name_localizations: ?[]const u8, //?Localization,
    /// Description for `ApplicationCommandTypes.ChatInput` commands, 1-100 characters.
    description: ?[]const u8,
    /// Localization object for `description` field. Values follow the same restrictions as `description`
    description_localizations: ?[]const u8, //?Localization,
    /// Parameters for the command, max of 25
    options: []?ApplicationCommandOption,
    /// Set of permissions represented as a bit set
    default_member_permissions: ?[]const u8,
    ///
    /// Installation contexts where the command is available
    ///
    /// @remarks
    /// This value is available only for globally-scoped commands
    /// Defaults to the application configured contexts
    ///
    integration_types: []?ApplicationIntegrationType,
    ///
    /// Interaction context(s) where the command can be used
    ///
    /// @remarks
    /// This value is available only for globally-scoped commands
    /// By default, all interaction context types included for new commands.
    ///
    contexts: []?InteractionContextType,
    ///
    /// Indicates whether the command is available in DMs with the app, only for globally-scoped commands. By default, commands are visible.
    ///
    /// @deprecated use {@link contexts}; instead
    ///
    dm_permission: ?bool,
    /// Indicates whether the command is age-restricted, defaults to false
    nsfw: ?bool,
    /// Auto incrementing version identifier updated during substantial record changes
    version: ?[]const u8,
    ///
    ///Determines whether the interaction is handled by the app's interactions handler or by
    ///
    /// @remarks
    /// This can only be set for application commands of type `PRIMARY_ENTRY_POINT` for applications with the `EMBEDDED` flag (i.e. applications that have an Activity).
    ///
    handler: ?InteractionEntryPointCommandHandlerType,
    /// Unique ID of command
    id: []const u8,
    /// ID of the parent application
    application_id: []const u8,
    /// Guild id of the command, if not global
    guild_id: ?[]const u8,
};

pub const CreateApplicationCommand = struct {
    /// Type of command, defaults to `ApplicationCommandTypes.ChatInput`
    type: ?ApplicationCommandTypes,
    ///
    /// Name of command, 1-32 characters.
    /// `ApplicationCommandTypes.ChatInput` command names must match the following regex `^[-_\p{L};\p{N};\p{sc=Deva};\p{sc=Thai};]{1,32};$` with the unicode flag set.
    /// If there is a lowercase variant of any letters used, you must use those.
    /// Characters with no lowercase variants and/or uncased letters are still allowed.
    /// ApplicationCommandTypes.User` and `ApplicationCommandTypes.Message` commands may be mixed case and can include spaces.
    ///
    name: []const u8,
    /// Localization object for `name` field. Values follow the same restrictions as `name`
    name_localizations: []const u8, //?Localization,
    /// Description for `ApplicationCommandTypes.ChatInput` commands, 1-100 characters.
    description: ?[]const u8,
    /// Localization object for `description` field. Values follow the same restrictions as `description`
    description_localizations: []const u8, //?Localization,
    /// Parameters for the command, max of 25
    options: []?ApplicationCommandOption,
    /// Set of permissions represented as a bit set
    default_member_permissions: ?[]const u8,
    ///
    /// Installation contexts where the command is available
    ///
    /// @remarks
    /// This value is available only for globally-scoped commands
    /// Defaults to the application configured contexts
    ///
    integration_types: []?ApplicationIntegrationType,
    ///
    /// Interaction context(s) where the command can be used
    ///
    /// @remarks
    /// This value is available only for globally-scoped commands
    /// By default, all interaction context types included for new commands.
    ///
    contexts: []?InteractionContextType,
    ///
    /// Indicates whether the command is available in DMs with the app, only for globally-scoped commands. By default, commands are visible.
    ///
    /// @deprecated use {@link contexts}; instead
    ///
    dm_permission: ?bool,
    /// Indicates whether the command is age-restricted, defaults to false
    nsfw: ?bool,
    /// Auto incrementing version identifier updated during substantial record changes
    version: ?[]const u8,
    ///
    ///Determines whether the interaction is handled by the app's interactions handler or by
    ///
    /// @remarks
    /// This can only be set for application commands of type `PRIMARY_ENTRY_POINT` for applications with the `EMBEDDED` flag (i.e. applications that have an Activity).
    ///
    handler: ?InteractionEntryPointCommandHandlerType,
};

pub const InteractionEntryPointCommandHandlerType = enum(u4) {
    /// The app handles the interaction using an interaction token
    AppHandler = 1,
    /// handles the interaction by launching an Activity and sending a follow-up message without coordinating with the app
    LaunchActivity = 2,
};

/// https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure
pub const ApplicationCommandOption = struct {
    /// Type of option
    type: ApplicationCommandOptionTypes,
    ///
    /// Name of command, 1-32 characters.
    ///
    /// @remarks
    ///This value should be unique within an array of {@link ApplicationCommandOption};
    ///
    /// {@link ApplicationCommandTypes.ChatInput | ChatInput}; command names must match the following regex `^[-_\p{L};\p{N};\p{sc=Deva};\p{sc=Thai};]{1,32};$` with the unicode flag set.
    /// If there is a lowercase variant of any letters used, you must use those.
    /// Characters with no lowercase variants and/or uncased letters are still allowed.
    ///
    /// {@link ApplicationCommandTypes.User | User}; and {@link ApplicationCommandTypes.Message | Message}; commands may be mixed case and can include spaces.
    ///
    name: []const u8,
    /// Localization object for the `name` field. Values follow the same restrictions as `name`
    name_localizations: []const u4, //?Localization,
    /// 1-100 character description
    description: []const u8,
    /// Localization object for the `description` field. Values follow the same restrictions as `description`
    description_localizations: ?[]const u8, //?Localization,
    ///
    /// If the parameter is required or optional. default `false`
    ///
    /// @remarks
    /// Valid in all option types except {@link ApplicationCommandOptionTypes.SubCommand | SubCommand}; and {@link ApplicationCommandOptionTypes.SubCommandGroup | SubCommandGroup};
    ///
    required: ?bool,
    ///
    /// Choices for the option from which the user can choose, max 25
    ///
    /// @remarks
    /// Only valid in options of type {@link ApplicationCommandOptionTypes.[]const u8 | []const u8};, {@link ApplicationCommandOptionTypes.Integer | Integer};, or {@link ApplicationCommandOptionTypes.isize | isize};
    ///
    /// If you provide an array of choices, they will be the ONLY accepted values for this option
    ///
    choices: []?ApplicationCommandOptionChoice,
    ///
    /// If the option is a subcommand or subcommand group type, these nested options will be the parameters
    ///
    /// @remarks
    /// Only valid in option of type {@link ApplicationCommandOptionTypes.SubCommand | SubCommand}; or {@link ApplicationCommandOptionTypes.SubCommandGroup | SubCommandGroup};
    ///
    options: []?ApplicationCommandOption,
    ///
    /// If autocomplete interactions are enabled for this option.
    ///
    /// @remarks
    /// Only valid in options of type {@link ApplicationCommandOptionTypes.[]const u8 | []const u8};, {@link ApplicationCommandOptionTypes.Integer | Integer};, or {@link ApplicationCommandOptionTypes.isize | isize};
    ///
    ///When {@link ApplicationCommandOption.choices | choices}; are provided, this may not be set to true
    ///
    autocomplete: ?bool,
    ///
    /// The channels shown will be restricted to these types
    ///
    /// @remarks
    /// Only valid in option of type {@link ApplicationCommandOptionTypes.Channel | Channel};
    ///
    channel_types: []?ChannelTypes,
    ///
    /// The minimum permitted value
    ///
    /// @remarks
    /// Only valid in options of type {@link ApplicationCommandOptionTypes.Integer | Integer}; or {@link ApplicationCommandOptionTypes.isize | isize};
    ///
    min_value: ?isize,
    ///
    /// The maximum permitted value
    ///
    /// @remarks
    /// Only valid in options of type {@link ApplicationCommandOptionTypes.Integer | Integer}; or {@link ApplicationCommandOptionTypes.isize | isize};
    ///
    max_value: ?isize,
    ///
    /// The minimum permitted length, should be in the range of from 0 to 600
    ///
    /// @remarks
    /// Only valid in options of type {@link ApplicationCommandOptionTypes.[]const u8 | []const u8};
    ///
    min_length: ?isize,
    ///
    /// The maximum permitted length, should be in the range of from 0 to 600
    ///
    /// @remarks
    /// Only valid in options of type {@link ApplicationCommandOptionTypes.[]const u8 | []const u8};
    ///
    max_length: ?isize,
};

/// https://discord.com/developers/docs/interactions/application-commands#application-command-permissions-object
pub const ApplicationCommandOptionChoice = struct {
    /// 1-100 character choice name
    name: []const u8,
    /// Localization object for the `name` field. Values follow the same restrictions as `name`
    name_localizations: []const u8, //?Localization,
    /// Value for the choice, up to 100 characters if []const u8
    value: union(enum) {
        string: []const u8,
        integer: isize,
    },
};

/// https://discord.com/developers/docs/interactions/slash-commands#guildapplicationcommandpermissions
pub const GuildApplicationCommandPermissions = struct {
    /// ID of the command or the application ID. When the `id` field is the application ID instead of a command ID, the permissions apply to all commands that do not contain explicit overwrites.
    id: []const u8,
    /// ID of the application the command belongs to
    application_id: []const u8,
    /// ID of the guild
    guild_id: []const u8,
    /// Permissions for the command in the guild, max of 100
    permissions: []ApplicationCommandPermissions,
};

/// https://discord.com/developers/docs/interactions/slash-commands#applicationcommandpermissions
pub const ApplicationCommandPermissions = struct {
    /// ID of the role, user, or channel. It can also be a permission constant
    id: []const u8,
    /// ApplicationCommandPermissionTypes.Role, ApplicationCommandPermissionTypes.User, or ApplicationCommandPermissionTypes.Channel
    type: ApplicationCommandPermissionTypes,
    /// `true` to allow, `false`, to disallow
    permission: bool,
};

/// https://discord.com/developers/docs/resources/guild#get-guild-widget-example-get-guild-widget
pub const GuildWidget = struct {
    id: []const u8,
    name: []const u8,
    instant_invite: []const u8,
    channels: []struct {
        id: []const u8,
        name: []const u8,
        position: isize,
    },
    members: []struct {
        id: []const u8,
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
    id: []const u8,
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

/// https://discord.com/developers/docs/resources/channel#followed-channel-object
pub const FollowedChannel = struct {
    /// Source message id
    channel_id: []const u8,
    /// Created target webhook id
    webhook_id: []const u8,
};

/// https://discord.com/developers/docs/topics/gateway#payloads-gateway-payload-structure
pub fn GatewayPayload(comptime T: type) type {
    const OBJ = struct {
        /// opcode for the payload
        op: isize,
        /// Event data
        d: ?T,
        /// Sequence isize, used for resuming sessions and heartbeats
        s: ?isize,
        /// The event name for this payload
        t: ?GatewayDispatchEventNames,
    };

    return OBJ;
}

/// https://discord.com/developers/docs/topics/gateway#guild-members-chunk
pub const GuildMembersChunk = struct {
    /// The id of the guild
    guild_id: []const u8,
    /// Set of guild members
    members: []MemberWithUser,
    /// The chunk index in the expected chunks for this response (0 <= chunk_index < chunk_count)
    chunk_index: isize,
    /// The total isize of expected chunks for this response
    chunk_count: isize,
    /// If passing an invalid id to `REQUEST_GUILD_MEMBERS`, it will be returned here
    not_found: []?[]const u8,
    /// If passing true to `REQUEST_GUILD_MEMBERS`, presences of the returned members will be here
    presences: []?PresenceUpdate,
    /// The nonce used in the Guild Members Request
    nonce: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway#channel-pins-update
pub const ChannelPinsUpdate = struct {
    /// The id of the guild
    guild_id: ?[]const u8,
    /// The id of the channel
    channel_id: []const u8,
    /// The time at which the most recent pinned message was pinned
    last_pin_timestamp: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway#guild-role-delete
pub const GuildRoleDelete = struct {
    /// id of the guild
    guild_id: []const u8,
    /// id of the role
    role_id: []const u8,
};

/// https://discord.com/developers/docs/topics/gateway#guild-ban-add
pub const GuildBanAddRemove = struct {
    /// id of the guild
    guild_id: []const u8,
    /// The banned user
    user: User,
};

/// https://discord.com/developers/docs/topics/gateway#message-reaction-remove
pub const MessageReactionRemove = struct {
    /// The id of the user
    user_id: []const u8,
    /// The id of the channel
    channel_id: []const u8,
    /// The id of the message
    message_id: []const u8,
    /// The id of the guild
    guild_id: ?[]const u8,
    /// The emoji used to react
    emoji: Partial(Emoji),
    /// The id of the author of this message
    message_author_id: ?[]const u8,
    /// true if this is a super-reaction
    burst: bool,
    /// The type of reaction
    type: ReactionType,
};

/// https://discord.com/developers/docs/topics/gateway#message-reaction-add
pub const MessageReactionAdd = struct {
    /// The id of the user
    user_id: []const u8,
    /// The id of the channel
    channel_id: []const u8,
    /// The id of the message
    message_id: []const u8,
    /// The id of the guild
    guild_id: ?[]const u8,
    /// The member who reacted if this happened in a guild
    member: ?MemberWithUser,
    /// The emoji used to react
    emoji: Partial(Emoji),
    /// The id of the author of this message
    message_author_id: ?[]const u8,
    /// true if this is a super-reaction
    burst: bool,
    /// Colors used for super-reaction animation in "#rrggbb" format
    burst_colors: []?[]const u8,
    /// The type of reaction
    type: ReactionType,
};

/// https://discord.com/developers/docs/topics/gateway#voice-server-update
pub const VoiceServerUpdate = struct {
    /// Voice connection token
    token: []const u8,
    /// The guild this voice server update is for
    guild_id: []const u8,
    /// The voice server host
    endpoint: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway-events#voice-channel-effect-send-voice-channel-effect-send-event-fields
pub const VoiceChannelEffectSend = struct {
    /// ID of the channel the effect was sent in
    channel_id: []const u8,
    /// ID of the guild the effect was sent in
    guild_id: []const u8,
    /// ID of the user who sent the effect
    user_id: []const u8,
    /// The emoji sent, for emoji reaction and soundboard effects
    emoji: ?Emoji,
    /// The type of emoji animation, for emoji reaction and soundboard effects
    animation_type: ?VoiceChannelEffectAnimationType,
    /// The ID of the emoji animation, for emoji reaction and soundboard effects
    animation_id: ?isize,
    /// The ID of the soundboard sound, for soundboard effects
    sound_id: union(enum) {
        string: ?[]const u8,
        integer: isize,
    },
    /// The volume of the soundboard sound, from 0 to 1, for soundboard effects
    sound_volume: ?isize,
};

/// https://discord.com/developers/docs/topics/gateway-events#voice-channel-effect-send-animation-types
pub const VoiceChannelEffectAnimationType = enum(u4) {
    /// A fun animation, sent by a Nitro subscriber
    Premium = 0,
    /// The standard animation
    Basic = 1,
};

/// https://discord.com/developers/docs/topics/gateway#invite-create
pub const InviteCreate = struct {
    /// The channel the invite is for
    channel_id: []const u8,
    /// The unique invite code
    code: []const u8,
    /// The time at which the invite was created
    created_at: []const u8,
    /// The guild of the invite
    guild_id: ?[]const u8,
    /// The user that created the invite
    inviter: ?User,
    /// How long the invite is valid for (in seconds)
    max_age: isize,
    /// The maximum isize of times the invite can be used
    max_uses: isize,
    /// The type of target for this voice channel invite
    target_type: TargetTypes,
    /// The target user for this invite
    target_user: ?User,
    /// The embedded application to open for this voice channel embedded application invite
    target_application: ?Partial(Application),
    /// Whether or not the invite is temporary (invited users will be kicked on disconnect unless they're assigned a role)
    temporary: bool,
    /// How many times the invite has been used (always will be 0)
    uses: isize,
};

/// https://discord.com/developers/docs/topics/gateway#hello
pub const Hello = struct {
    /// The interval (in milliseconds) the client should heartbeat with
    heartbeat_interval: isize,
};

/// https://discord.com/developers/docs/topics/gateway#ready
pub const Ready = struct {
    /// Gateway version
    v: isize,
    /// Information about the user including email
    user: User,
    /// The guilds the user is in
    guilds: []UnavailableGuild,
    /// Used for resuming connections
    session_id: []const u8,
    /// Gateway url for resuming connections
    resume_gateway_url: []const u8,
    /// The shard information associated with this session, if sent when identifying
    shard: ?[2]isize,
    /// Contains id and flags
    application: struct {
        name: ?[]const u8,
        description: ?[]const u8,
        rpc_origins: ?[]?[]const u8,
        terms_of_service_url: ?[]const u8,
        privacy_policy_url: ?[]const u8,
        verify_key: ?[]const u8,
        primary_sku_id: ?[]const u8,
        slug: ?[]const u8,
        icon: ?[]const u8,
        bot_public: ?bool,
        bot_require_code_grant: ?bool,
        owner: ?Partial(User),
        team: ?Team,
        guild_id: ?[]const u8,
        guild: ?Partial(Guild),
        cover_image: ?[]const u8,
        tags: ?[]?[]const u8,
        install_params: ?InstallParams,
        integration_types_config: ?Partial(AutoHashMapUnmanaged(ApplicationIntegrationType, ApplicationIntegrationTypeConfiguration)),
        custom_install_url: ?[]const u8,
        role_connections_verification_url: ?[]const u8,
        approximate_guild_count: ?isize,
        approximate_user_install_count: ?isize,
        bot: ?Partial(User),
        redirect_uris: []?[]const u8,
        interactions_endpoint_url: ?[]const u8,

        flags: ?ApplicationFlags,
        id: []const u8,
    },
};

/// https://discord.com/developers/docs/resources/guild#unavailable-guild-object
pub const UnavailableGuild = struct {
    unavailable: ?bool,
    id: []const u8,
};

/// https://discord.com/developers/docs/topics/gateway#message-delete-bulk
pub const MessageDeleteBulk = struct {
    /// The ids of the messages
    ids: [][]const u8,
    /// The id of the channel
    channel_id: []const u8,
    /// The id of the guild
    guild_id: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/template#template-object-template-structure
pub const Template = struct {
    /// The template code (unique Id)
    code: []const u8,
    /// Template name
    name: []const u8,
    /// The description for the template
    description: ?[]const u8,
    /// isize of times this template has been used
    usage_count: isize,
    /// The Id of the user who created the template
    creator_id: []const u8,
    /// The user who created the template
    creator: User,
    /// When this template was created
    created_at: []const u8,
    /// When this template was last synced to the source guild
    updated_at: []const u8,
    /// The Id of the guild this template is based on
    source_guild_id: []const u8,
    /// The guild snapshot this template contains
    serialized_source_guild: TemplateSerializedSourceGuild,
    is_dirty: ?bool,
};

pub const TemplateSerializedSourceGuild = null;

/// https://discord.com/developers/docs/topics/gateway#guild-member-add
pub const GuildMemberAdd = struct {
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
    /// id of the guild
    guild_id: []const u8,
};

/// https://discord.com/developers/docs/topics/gateway#message-delete
pub const MessageDelete = struct {
    /// The id of the message
    id: []const u8,
    /// The id of the channel
    channel_id: []const u8,
    /// The id of the guild
    guild_id: ?[]const u8,
};

/// https://discord.com/developers/docs/topics/gateway#thread-members-update-thread-members-update-event-fields
pub const ThreadMembersUpdate = struct {
    /// The id of the thread
    id: []const u8,
    /// The id of the guild
    guild_id: []const u8,
    /// The users who were added to the thread
    added_members: []?ThreadMember,
    /// The id of the users who were removed from the thread
    removed_member_ids: []?[]const u8,
    /// the approximate isize of members in the thread, capped at 50
    member_count: isize,
};

/// https://discord.com/developers/docs/topics/gateway#thread-member-update
pub const ThreadMemberUpdate = struct {
    /// The id of the thread
    id: []const u8,
    /// The id of the guild
    guild_id: []const u8,
    /// The timestamp when the bot joined this thread.
    joined_at: []const u8,
    /// The flags this user has for this thread. Not useful for bots.
    flags: isize,
};

/// https://discord.com/developers/docs/topics/gateway#guild-role-create
pub const GuildRoleCreate = struct {
    /// The id of the guild
    guild_id: []const u8,
    /// The role created
    role: Role,
};

/// https://discord.com/developers/docs/topics/gateway#guild-emojis-update
pub const GuildEmojisUpdate = struct {
    /// id of the guild
    guild_id: []const u8,
    /// Array of emojis
    emojis: []Emoji,
};

/// https://discord.com/developers/docs/topics/gateway-events#guild-stickers-update
pub const GuildStickersUpdate = struct {
    /// id of the guild
    guild_id: []const u8,
    /// Array of sticker
    stickers: []Sticker,
};

/// https://discord.com/developers/docs/topics/gateway#guild-member-update
pub const GuildMemberUpdate = struct {
    /// The id of the guild
    guild_id: []const u8,
    /// User role ids
    roles: [][]const u8,
    /// The user
    user: User,
    /// Nickname of the user in the guild
    nick: ?[]const u8,
    /// the member's [guild avatar hash](https://discord.com/developers/docs/reference#image-formatting)
    avatar: []const u8,
    /// When the user joined the guild
    joined_at: []const u8,
    /// When the user starting boosting the guild
    premium_since: ?[]const u8,
    /// whether the user is deafened in voice channels
    deaf: ?bool,
    /// whether the user is muted in voice channels
    mute: ?bool,
    /// Whether the user has not yet passed the guild's Membership Screening requirements
    pending: ?bool,
    /// when the user's [timeout](https://support.discord.com/hc/en-us/articles/4413305239191-Time-Out-FAQ) will expire and the user will be able to communicate in the guild again, null or a time in the past if the user is not timed out. Will throw a 403 error if the user has the ADMINISTRATOR permission or is the owner of the guild
    communication_disabled_until: ?[]const u8,
    /// Data for the member's guild avatar decoration
    avatar_decoration_data: ?AvatarDecorationData,
    /// Guild member flags
    flags: ?isize,
};

/// https://discord.com/developers/docs/topics/gateway#message-reaction-remove-all
pub const MessageReactionRemoveAll = null;

/// https://discord.com/developers/docs/topics/gateway#guild-role-update
pub const GuildRoleUpdate = struct {
    /// The id of the guild
    guild_id: []const u8,
    /// The role updated
    role: Role,
};

pub const ScheduledEventUserAdd = struct {
    /// id of the guild scheduled event
    guild_scheduled_event_id: []const u8,
    /// id of the user
    user_id: []const u8,
    /// id of the guild
    guild_id: []const u8,
};

/// https://discord.com/developers/docs/topics/gateway#message-reaction-remove-emoji
pub const MessageReactionRemoveEmoji = null;

/// https://discord.com/developers/docs/topics/gateway#guild-member-remove
pub const GuildMemberRemove = struct {
    /// The id of the guild
    guild_id: []const u8,
    /// The user who was removed
    user: User,
};

/// https://discord.com/developers/docs/resources/guild#ban-object
pub const Ban = struct {
    /// The reason for the ban
    reason: ?[]const u8,
    /// The banned user
    user: User,
};

pub const ScheduledEventUserRemove = struct {
    /// id of the guild scheduled event
    guild_scheduled_event_id: []const u8,
    /// id of the user
    user_id: []const u8,
    /// id of the guild
    guild_id: []const u8,
};

/// https://discord.com/developers/docs/topics/gateway#invite-delete
pub const InviteDelete = struct {
    /// The channel of the invite
    channel_id: []const u8,
    /// The guild of the invite
    guild_id: ?[]const u8,
    /// The unique invite code
    code: []const u8,
};

/// https://discord.com/developers/docs/resources/voice#voice-region-object-voice-region-structure
pub const VoiceRegion = struct {
    /// Unique Id for the region
    id: []const u8,
    /// Name of the region
    name: []const u8,
    /// true for a single server that is closest to the current user's client
    optimal: bool,
    /// Whether this is a deprecated voice region (avoid switching to these)
    deprecated: bool,
    /// Whether this is a custom voice region (used for events/etc)
    custom: bool,
};

pub const GuildWidgetSettings = struct {
    /// whether the widget is enabled
    enabled: bool,
    /// the widget channel id
    channel_id: ?[]const u8,
};

pub const InstallParams = struct {
    /// Scopes to add the application to the server with
    scopes: []OAuth2Scope,
    /// Permissions to request for the bot role
    permissions: []const u8,
};

pub const ForumTag = struct {
    /// The id of the tag
    id: []const u8,
    /// The name of the tag (0-20 characters)
    name: []const u8,
    /// Whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission
    moderated: bool,
    /// The id of a guild's custom emoji At most one of emoji_id and emoji_name may be set.
    emoji_id: []const u8,
    /// The unicode character of the emoji
    emoji_name: ?[]const u8,
};

pub const DefaultReactionEmoji = struct {
    /// The id of a guild's custom emoji
    emoji_id: []const u8,
    /// The unicode character of the emoji
    emoji_name: ?[]const u8,
};

pub const ModifyChannel = struct {
    /// 1-100 character channel name
    name: ?[]const u8,
    /// The type of channel; only conversion between text and news is supported and only in guilds with the "NEWS" feature
    type: ?ChannelTypes,
    /// The position of the channel in the left-hand listing
    position: ?isize,
    /// 0-1024 character channel topic
    topic: ?[]const u8,
    /// Whether the channel is nsfw
    nsfw: ?bool,
    /// Amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission `manage_messages` or `manage_channel`, are unaffected
    rate_limit_per_user: ?isize,
    /// The bitrate (in bits) of the voice channel; 8000 to 96000 (128000 for VIP servers)
    bitrate: ?isize,
    /// The user limit of the voice channel; 0 refers to no limit, 1 to 99 refers to a user limit
    user_limit: ?isize,
    /// Channel or category-specific permissions
    permission_overwrites: []?Overwrite,
    /// Id of the new parent category for a channel
    parent_id: ?[]const u8,
    /// Voice region id for the voice channel, automatic when set to null
    rtc_region: ?[]const u8,
    /// The camera video quality mode of the voice channel
    video_quality_mode: ?VideoQualityModes,
    /// Whether the thread is archived
    archived: ?bool,
    /// Duration in minutes to automatically archive the thread after recent activity
    auto_archive_duration: ?isize,
    /// When a thread is locked, only users with `MANAGE_THREADS` can unarchive it
    locked: ?bool,
    /// whether non-moderators can add other non-moderators to a thread; only available on private threads
    invitable: ?bool,
    /// The set of tags that can be used in a GUILD_FORUM channel
    available_tags: []struct {
        /// The id of the tag
        id: []const u8,
        /// The name of the tag (0-20 characters)
        name: []const u8,
        /// Whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission
        moderated: bool,
        /// The id of a guild's custom emoji At most one of emoji_id and emoji_name may be set.
        emoji_id: []const u8,
        /// The unicode character of the emoji
        emoji_name: []const u8,
    },
    /// The IDs of the set of tags that have been applied to a thread in a GUILD_FORUM channel; limited to 5
    applied_tags: []?[]const u8,
    /// the emoji to show in the add reaction button on a thread in a GUILD_FORUM channel
    default_reaction_emoji: ?struct {
        /// The id of a guild's custom emoji
        emoji_id: []const u8,
        /// The unicode character of the emoji
        emoji_name: ?[]const u8,
    },
    /// the initial rate_limit_per_user to set on newly created threads in a channel. this field is copied to the thread at creation time and does not live update.
    default_thread_rate_limit_per_user: ?isize,
    /// the default sort order type used to order posts in forum channels
    default_sort_order: ?SortOrderTypes,
    /// the default forum layout view used to display posts in `GUILD_FORUM` channels. Defaults to `0`, which indicates a layout view has not been set by a channel admin
    default_forum_layout: ?ForumLayout,
};

/// https://discord.com/developers/docs/resources/emoji#create-guild-emoji
pub const CreateGuildEmoji = struct {
    /// Name of the emoji
    name: []const u8,
    ///The 128x128 emoji image. Emojis and animated emojis have a maximum file size of 256kb. Attempting to upload an emoji larger than this limit will fail and return 400 Bad Request and an error message, but not a JSON status code. If a URL is provided to the image parameter, eno will automatically convert it to a base64 []const u8 internally.
    image: []const u8,
    /// Roles allowed to use this emoji
    roles: []?[]const u8,
};

/// https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
pub const ModifyGuildEmoji = struct {
    /// Name of the emoji
    name: ?[]const u8,
    /// Roles allowed to use this emoji
    roles: []?[]const u8,
};

pub const CreateGuildChannel = struct {
    /// Channel name (1-100 characters)
    name: []const u8,
    /// The type of channel
    type: ?ChannelTypes,
    /// Channel topic (0-1024 characters)
    topic: ?[]const u8,
    /// The bitrate (in bits) of the voice channel (voice only)
    bitrate: ?isize,
    /// The user limit of the voice channel (voice only)
    user_limit: ?isize,
    /// Amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission `manage_messages` or `manage_channel`, are unaffected
    rate_limit_per_user: ?isize,
    /// Sorting position of the channel
    position: ?isize,
    /// The channel's permission overwrites
    permission_overwrites: []?Overwrite,
    /// Id of the parent category for a channel
    parent_id: ?[]const u8,
    /// Whether the channel is nsfw
    nsfw: ?bool,
    /// Default duration (in minutes) that clients (not the API) use for newly created threads in this channel, to determine when to automatically archive the thread after the last activity
    default_auto_archive_duration: ?isize,
    /// Emoji to show in the add reaction button on a thread in a forum channel
    default_reaction_emoji: ?struct {
        /// The id of a guild's custom emoji. Exactly one of `emojiId` and `emojiName` must be set.
        emoji_id: ?[]const u8,
        /// The unicode character of the emoji. Exactly one of `emojiId` and `emojiName` must be set.
        emoji_name: ?[]const u8,
    },
    /// Set of tags that can be used in a forum channel
    available_tags: ?[]struct {
        /// The id of the tag
        id: []const u8,
        /// The name of the tag (0-20 characters)
        name: []const u8,
        /// whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission
        moderated: bool,
        /// The id of a guild's custom emoji
        emoji_id: []const u8,
        /// The unicode character of the emoji
        emoji_name: ?[]const u8,
    },
    /// the default sort order type used to order posts in forum channels
    default_sort_order: ?SortOrderTypes,
};

pub const CreateMessage = struct {
    /// The message contents (up to 2000 characters)
    content: ?[]const u8,
    /// Can be used to verify a message was sent (up to 25 characters). Value will appear in the Message Create event.
    nonce: union(enum) {
        string: ?[]const u8,
        integer: isize,
    },
    /// true if this is a TTS message
    tts: ?bool,
    /// Embedded `rich` content (up to 6000 characters)
    embeds: []?Embed,
    /// Allowed mentions for the message
    allowed_mentions: ?AllowedMentions,
    /// Include to make your message a reply
    message_reference: ?struct {
        /// id of the originating message
        message_id: ?[]const u8,
        ///
        /// id of the originating message's channel
        /// Note: `channel_id` is optional when creating a reply, but will always be present when receiving an event/response that includes this data model.,
        ///
        channel_id: ?[]const u8,
        /// id of the originating message's guild
        guild_id: ?[]const u8,
        /// When sending, whether to error if the referenced message doesn't exist instead of sending as a normal (non-reply) message, default true
        fail_if_not_exists: bool,
    },
    /// The components you would like to have sent in this message
    components: ?[]MessageComponent,
    /// IDs of up to 3 stickers in the server to send in the message
    stickerIds: ?union(enum) { one: struct { []const u8 }, two: struct { []const u8 }, three: struct { []const u8 } },
};

/// https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
pub const ModifyGuildWelcomeScreen = struct {
    /// Whether the welcome screen is enabled
    enabled: ?bool,
    /// Channels linked in the welcome screen and their display options
    welcome_screen: []?WelcomeScreenChannel,
    /// The server description to show in the welcome screen
    description: ?[]const u8,
};

pub const FollowAnnouncementChannel = struct {
    /// The id of the channel to send announcements to.
    webhook_channel_id: []const u8,
};

pub const EditChannelPermissionOverridesOptions = struct {
    /// Permission bit set
    allow: []const u8,
    /// Permission bit set
    deny: []const u8,
    /// Either 0 (role) or 1 (member)
    type: OverwriteTypes,
};

/// https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
pub const ModifyGuildChannelPositions = struct {
    /// Channel id
    id: []const u8,
    /// Sorting position of the channel
    position: ?isize,
    /// Syncs the permission overwrites with the new parent, if moving to a new category
    lock_positions: ?bool,
    /// The new parent ID for the channel that is moved
    parent_id: ?[]const u8,
};

pub const CreateWebhook = struct {
    /// Name of the webhook (1-80 characters)
    name: []const u8,
    /// Image url for the default webhook avatar
    avatar: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/channel#start-thread-in-forum-channel
pub const CreateForumPostWithMessage = struct {
    /// 1-100 character channel name
    name: []const u8,
    /// duration in minutes to automatically archive the thread after recent activity, can be set to: 60, 1440, 4320, 10080,
    auto_archive_duration: ?isize,
    /// amount of seconds a user has to wait before sending another message (0-21600)
    rate_limit_per_user: ?isize,
    /// contents of the first message in the forum thread
    message: struct {
        /// Message contents (up to 2000 characters)
        content: ?[]const u8,
        /// Embedded rich content (up to 6000 characters)
        embeds: []?Embed,
        /// Allowed mentions for the message
        allowed_mentions: []?AllowedMentions,
        /// Components to include with the message
        components: []?[]MessageComponent,
        /// IDs of up to 3 stickers in the server to send in the message
        sticker_ids: []?[]const u8,
        /// JSON-encoded body of non-file params, only for multipart/form-data requests. See {@link https://discord.com/developers/docs/reference#uploading-files Uploading Files};
        payload_json: ?[]const u8,
        /// Attachment objects with filename and description. See {@link https://discord.com/developers/docs/reference#uploading-files Uploading Files};
        attachments: []?Attachment,
        /// Message flags combined as a bitfield, only SUPPRESS_EMBEDS can be set
        flags: ?MessageFlags,
    },
    /// the IDs of the set of tags that have been applied to a thread in a GUILD_FORUM channel
    applied_tags: []?[]const u8,
};

pub const ArchivedThreads = struct {
    threads: []Channel,
    members: []ThreadMember,
    hasMore: bool,
};

pub const ActiveThreads = struct {
    threads: []Channel,
    members: []ThreadMember,
};

pub const VanityUrl = struct {
    code: ?[]const u8,
    uses: isize,
};

pub const PrunedCount = struct {
    pruned: isize,
};

/// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-guild-onboarding-structure
pub const GuildOnboarding = struct {
    /// ID of the guild this onboarding is part of
    guild_id: []const u8,
    /// Prompts shown during onboarding and in customize community
    prompts: []GuildOnboardingPrompt,
    /// Channel IDs that members get opted into automatically
    default_channel_ids: [][]const u8,
    /// Whether onboarding is enabled in the guild
    enabled: bool,
    /// Current mode of onboarding
    mode: GuildOnboardingMode,
};

/// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-onboarding-prompt-structure
pub const GuildOnboardingPrompt = struct {
    /// ID of the prompt
    id: []const u8,
    /// Type of prompt
    type: GuildOnboardingPromptType,
    /// Options available within the prompt
    options: []GuildOnboardingPromptOption,
    /// Title of the prompt
    title: []const u8,
    /// Indicates whether users are limited to selecting one option for the prompt
    single_select: bool,
    /// Indicates whether the prompt is required before a user completes the onboarding flow
    required: bool,
    /// Indicates whether the prompt is present in the onboarding flow. If `false`, the prompt will only appear in the Channels & Roles tab
    in_onboarding: bool,
};

/// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-option-structure
pub const GuildOnboardingPromptOption = struct {
    /// ID of the prompt option
    id: []const u8,
    /// IDs for channels a member is added to when the option is selected
    channel_ids: [][]const u8,
    /// IDs for roles assigned to a member when the option is selected
    role_ids: [][]const u8,
    ///
    /// Emoji of the option
    ///
    /// @remarks
    /// When creating or updating a prompt option, the `emoji_id`, `emoji_name`, and `emoji_animated` fields must be used instead of the emoji object.
    ///
    emoji: ?Emoji,
    ///
    /// Emoji ID of the option
    ///
    /// @remarks
    /// When creating or updating a prompt option, the `emoji_id`, `emoji_name`, and `emoji_animated` fields must be used instead of the emoji object.
    ///
    emoji_id: ?[]const u8,
    ///
    /// Emoji name of the option
    ///
    /// @remarks
    /// When creating or updating a prompt option, the `emoji_id`, `emoji_name`, and `emoji_animated` fields must be used instead of the emoji object.
    ///
    emoji_name: ?[]const u8,
    ///
    /// Whether the emoji is animated
    ///
    /// @remarks
    /// When creating or updating a prompt option, the `emoji_id`, `emoji_name`, and `emoji_animated` fields must be used instead of the emoji object.
    ///
    emoji_animated: ?bool,
    /// Title of the option
    title: []const u8,
    /// Description of the option
    description: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-types
pub const GuildOnboardingPromptType = enum {
    MultipleChoice,
    DropDown,
};

/// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-onboarding-mode
pub const GuildOnboardingMode = enum {
    /// Counts only Default Channels towards constraints
    OnboardingDefault,
    /// Counts Default Channels and Questions towards constraints
    OnboardingAdvanced,
};

/// https://discord.com/developers/docs/topics/teams#team-member-roles-team-member-role-types
pub const TeamMemberRole = enum {
    /// Owners are the most permissiable role, and can take destructive, irreversible actions like deleting the team itself. Teams are limited to 1 owner.
    owner,
    /// Admins have similar access as owners, except they cannot take destructive actions on the team or team-owned apps.
    admin,
    /// broken
    ///
    developer,
    /// Read-only members can access information about a team and any team-owned apps. Some examples include getting the IDs of applications and exporting payout records.
    read_only,
};

/// https://discord.com/developers/docs/monetization/entitlements#entitlement-object-entitlement-structure
pub const Entitlement = struct {
    /// ID of the entitlement
    id: []const u8,
    /// ID of the SKU
    sku_id: []const u8,
    /// ID of the user that is granted access to the entitlement's sku
    user_id: ?[]const u8,
    /// ID of the guild that is granted access to the entitlement's sku
    guild_id: ?[]const u8,
    /// ID of the parent application
    application_id: []const u8,
    /// Type of entitlement
    type: EntitlementType,
    /// Entitlement was deleted
    deleted: bool,
    /// Start date at which the entitlement is valid. Not present when using test entitlements
    starts_at: ?[]const u8,
    /// Date at which the entitlement is no longer valid. Not present when using test entitlements
    ends_at: ?[]const u8,
    /// For consumable items, whether or not the entitlement has been consumed
    consumed: ?bool,
};

/// https://discord.com/developers/docs/monetization/entitlements#entitlement-object-entitlement-types
pub const EntitlementType = enum(u4) {
    /// Entitlement was purchased by user
    Purchase = 1,
    ///Entitlement for  Nitro subscription
    PremiumSubscription = 2,
    /// Entitlement was gifted by developer
    DeveloperGift = 3,
    /// Entitlement was purchased by a dev in application test mode
    TestModePurchase = 4,
    /// Entitlement was granted when the SKU was free
    FreePurchase = 5,
    /// Entitlement was gifted by another user
    UserGift = 6,
    /// Entitlement was claimed by user for free as a Nitro Subscriber
    PremiumPurchase = 7,
    /// Entitlement was purchased as an app subscription
    ApplicationSubscription = 8,
};

/// https://discord.com/developers/docs/monetization/skus#sku-object-sku-structure
pub const Sku = struct {
    /// ID of SKU
    id: []const u8,
    /// Type of SKU
    type: SkuType,
    /// ID of the parent application
    application_id: []const u8,
    /// Customer-facing name of your premium offering
    name: []const u8,
    /// System-generated URL slug based on the SKU's name
    slug: []const u8,
    /// SKU flags combined as a bitfield
    flags: SkuFlags,
};

/// https://discord.com/developers/docs/monetization/skus#sku-object-sku-types
pub const SkuType = enum(u4) {
    /// Durable one-time purchase
    Durable = 2,
    /// Consumable one-time purchase
    Consumable = 3,
    /// Represents a recurring subscription
    Subscription = 5,
    /// System-generated group for each SUBSCRIPTION SKU created
    SubscriptionGroup = 6,
};

/// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-context-types
pub const InteractionContextType = enum {
    /// Interaction can be used within servers
    Guild,
    /// Interaction can be used within DMs with the app's bot user
    BotDm,
    /// Interaction can be used within Group DMs and DMs other than the app's bot user
    PrivateChannel,
};

/// https://discord.com/developers/docs/resources/guild#bulk-guild-ban
pub const BulkBan = struct {
    /// list of user ids, that were successfully banned
    banned_users: [][]const u8,
    /// list of user ids, that were not banned
    failed_users: [][]const u8,
};
