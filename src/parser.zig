const zmpl = @import("zmpl");
const Discord = @import("types.zig");
const std = @import("std");
const mem = std.mem;
const Snowflake = @import("shared.zig").Snowflake;
const Parser = @import("json");

pub fn parseUser(allocator: mem.Allocator, obj: []const u8) std.fmt.ParseIntError!Discord.User {
    const user= try Parser.parse(Discord.User, allocator, obj);
    return user.value;
}

pub fn parseMember(allocator: mem.Allocator, obj: []const u8) std.fmt.ParseIntError!Discord.Member {
    const member = try Parser.parse(Discord.Member, allocator, obj);
    return member.value;
}

/// caller must free the received referenced_message if any
pub fn parseMessage(allocator: mem.Allocator, obj: *zmpl.Data.Object) (mem.Allocator.Error || std.fmt.ParseIntError)!Discord.Message {
    // parse mentions
    const mentions_obj = obj.getT(.array, "mentions").?;

    var mentions = std.ArrayList(Discord.User).init(allocator);
    defer mentions.deinit();

    while (mentions_obj.iterator().next()) |m| {
        try mentions.append(try parseUser(allocator, &m.object));
    }

    // parse member
    const member = if (obj.getT(.object, "member")) |m| try parseMember(allocator, m) else null;

    // parse message
    const author = try parseUser(allocator, obj.getT(.object, "author").?);

    // the referenced_message if any
    const refmp = try allocator.create(Discord.Message);

    if (obj.getT(.object, "referenced_message")) |m| {
        refmp.* = try parseMessage(allocator, m);
    } else {
        allocator.destroy(refmp);
    }

    // parse message
    const message = Discord.Message{
        // the id
        .id = try Snowflake.fromRaw(obj.getT(.string, "id").?),
        .tts = obj.getT(.boolean, "tts").?,
        .mention_everyone = obj.getT(.boolean, "mention_everyone").?,
        .pinned = obj.getT(.boolean, "pinned").?,
        .type = @as(Discord.MessageTypes, @enumFromInt(obj.getT(.integer, "type").?)),
        .channel_id = try Snowflake.fromRaw(obj.getT(.string, "channel_id").?),
        .author = author,
        .member = member,
        .content = obj.getT(.string, "content"),
        .timestamp = obj.getT(.string, "timestamp").?,
        .guild_id = try Snowflake.fromMaybe(obj.getT(.string, "guild_id")),
        .attachments = &[0]Discord.Attachment{},
        .edited_timestamp = null,
        .mentions = try mentions.toOwnedSlice(),
        .mention_roles = &[0]?[]const u8{},
        .mention_channels = &[0]?Discord.ChannelMention{},
        .embeds = &[0]Discord.Embed{},
        .reactions = &[0]?Discord.Reaction{},
        .nonce = if (obj.get("nonce")) |nonce| switch (nonce.*) {
            .integer => |n| .{ .int = @as(isize, @intCast(n.value)) },
            .string => |n| .{ .string = n.value },
            .Null => null,
            else => unreachable,
        } else null,
        .webhook_id = try Snowflake.fromMaybe(obj.getT(.string, "webhook_id")),
        .activity = null,
        .application = null,
        .application_id = try Snowflake.fromMaybe(obj.getT(.string, "application_id")),
        .message_reference = null,
        .flags = if (obj.getT(.integer, "flags")) |fs| @as(Discord.MessageFlags, @bitCast(@as(u15, @intCast(fs)))) else null,
        .stickers = &[0]?Discord.Sticker{},
        .message_snapshots = &[0]?Discord.MessageSnapshot{},
        .interaction_metadata = null,
        .interaction = null,
        .thread = null,
        .components = null,
        .sticker_items = &[0]?Discord.StickerItem{},
        .position = if (obj.getT(.integer, "position")) |p| @as(isize, @intCast(p)) else null,
        .poll = null,
        .call = null,
        .referenced_message = refmp,
    };
    return message;
}
