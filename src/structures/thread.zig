const Snowflake = @import("snowflake.zig").Snowflake;
const Channel = @import("channel.zig").Channel;
const ChannelTypes = @import("shared.zig").ChannelTypes;
const MessageFlags = @import("shared.zig").MessageFlags;
const Embed = @import("embed.zig").Embed;
const Partial = @import("partial.zig").Partial;
const Attachment = @import("attachment.zig").Attachment;
const AllowedMentions = @import("message.zig").AllowedMentions;
const MessageComponent = @import("message.zig").MessageComponent;

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
    id: Snowflake,
    /// The id of the user
    user_id: Snowflake,
    /// The time the current user last joined the thread
    join_timestamp: []const u8,
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
    guild_id: Snowflake,
    /// The parent channel ids whose threads are being synced. If omitted, then threads were synced for the entire guild. This array may contain channelIds that have no active threads as well, so you know to clear that data
    channel_ids: ?[][]const u8,
    /// All active threads in the given channels that the current user can access
    threads: []Channel,
    /// All thread member objects from the synced threads for the current user, indicating which threads the current user has been added to
    members: []ThreadMember,
};

/// https://discord.com/developers/docs/resources/channel#start-thread-from-message
pub const StartThreadFromMessage = struct {
    /// 1-100 character thread name
    name: []const u8,
    /// Duration in minutes to automatically archive the thread after recent activity
    auto_archive_duration: ?isize,
    /// Amount of seconds a user has to wait before sending another message (0-21600)
    rate_limit_per_user: ?isize,
};

/// https://discord.com/developers/docs/resources/channel#start-thread-without-message
pub const StartThreadWithoutMessage = struct {
    /// 1-100 character thread name,
    name: []const u8,
    /// Duration in minutes to automatically archive the thread after recent activity,
    auto_archive_duration: isize,
    /// Amount of seconds a user has to wait before sending another message (0-21600),
    rateLimitPerUser: ?isize,
    /// the type of thread to create,
    /// may only be AnnouncementThread, PublicThread, or PrivateThread
    type: ChannelTypes,
    /// whether non-moderators can add other non-moderators to a thread; only available when creating a private thread,
    invitable: ?bool,
};

/// https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel-forum-and-media-thread-message-params-object
pub const CreateForumAndMediaThreadMessage = struct {
    /// Message contents (up to 2000 characters)
    content: ?[]const u8,
    /// Up to 10 rich embeds (up to 6000 characters)
    embeds: ?[]Embed,
    /// Allowed mentions for the message
    allowed_mentions: ?AllowedMentions,
    /// Components to include with the message
    components: ?[]MessageComponent,
    /// IDs of up to 3 stickers in the server to send in the message
    sticker_ids: ?[]Snowflake,
    /// Attachment objects with filename and description. See Uploading Files
    attachments: ?[]Partial(Attachment),
    /// Message flags combined as a bitfield (only SUPPRESS_EMBEDS and SUPPRESS_NOTIFICATIONS can be set)
    flags: ?MessageFlags,
};

pub const StartThreadInForumOrMediaChannel = struct {
    /// 1-100 character channel name
    name: []const u8,
    /// Duration in minutes to automatically archive the thread after recent activity, can be set to: 60, 1440, 4320, 10080
    auto_archive_duration: ?isize,
    /// Amount of seconds a user has to wait before sending another message (0-21600)
    rate_limit_per_user: ?isize,
    /// Contents of the first message in the forum/media thread
    message: CreateForumAndMediaThreadMessage,
    /// The IDs of the set of tags that have been applied to a thread in a GUILD_FORUM or a GUILD_MEDIA channel
    applied_tags: ?[]Snowflake,
};
