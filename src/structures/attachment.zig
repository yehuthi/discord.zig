const Snowflake = @import("snowflake.zig").Snowflake;
const AttachmentFlags = @import("shared.zig").AttachmentFlags;

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
    id: Snowflake,
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
