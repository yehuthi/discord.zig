const Snowflake = @import("snowflake.zig").Snowflake;
const Channel = @import("channel.zig").Channel;

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
