const EmbedTypes = @import("shared.zig").EmbedTypes;

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
