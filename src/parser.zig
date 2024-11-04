const zmpl = @import("zmpl");
const Discord = @import("raw_types.zig");
const std = @import("std");

pub fn parseUser(obj: *zmpl.Data.Object) Discord.User {
    const avatar_decoration_data_obj = obj.getT(.object, "avatar_decoration_data");
    const user = Discord.User{
        .clan = null,
        .id = obj.getT(.string, "id").?,
        .bot = obj.getT(.boolean, "bot") orelse false,
        .username = obj.getT(.string, "username").?,
        .accent_color = if (obj.getT(.integer, "accent_color")) |ac| @as(isize, @intCast(ac)) else null,
        // note: for selfbots this can be typed with an enu.?,
        .flags = if (obj.getT(.integer, "flags")) |fs| @as(isize, @intCast(fs)) else null,
        // also for selfbot.?,
        .email = obj.getT(.string, "email"),
        .avatar = obj.getT(.string, "avatar"),
        .locale = obj.getT(.string, "locale"),
        .system = obj.getT(.boolean, "system"),
        .banner = obj.getT(.string, "banner"),
        .verified = obj.getT(.boolean, "verified"),
        .global_name = obj.getT(.string, "global_name"),
        .mfa_enabled = obj.getT(.boolean, "mfa_enabled"),
        .public_flags = if (obj.getT(.integer, "public_flags")) |pfs| @as(isize, @intCast(pfs)) else null,
        .premium_type = if (obj.getT(.integer, "premium_type")) |pfs| @as(Discord.PremiumTypes, @enumFromInt(pfs)) else null,
        .discriminator = obj.getT(.string, "discriminator").?,
        .avatar_decoration_data = if (avatar_decoration_data_obj) |add| Discord.AvatarDecorationData{
            .asset = add.getT(.string, "asset").?,
            .sku_id = add.getT(.string, "sku_id").?,
        } else null,
    };

    return user;
}

pub fn parseMember(obj: *zmpl.Data.Object) Discord.Member {
    const avatar_decoration_data_member_obj = obj.getT(.object, "avatar_decoration_data");
    const member = Discord.Member{
        .deaf = obj.getT(.boolean, "deaf"),
        .mute = obj.getT(.boolean, "mute"),
        .pending = obj.getT(.boolean, "pending"),
        .user = null,
        .nick = obj.getT(.string, "nick"),
        .avatar = obj.getT(.string, "avatar"),
        .roles = &[0][]const u8{},
        .joined_at = obj.getT(.string, "joined_at").?,
        .premium_since = obj.getT(.string, "premium_since"),
        .permissions = obj.getT(.string, "permissions"),
        .communication_disabled_until = obj.getT(.string, "communication_disabled_until"),
        .flags = @as(isize, @intCast(obj.getT(.integer, "flags").?)),
        .avatar_decoration_data = if (avatar_decoration_data_member_obj) |addm| Discord.AvatarDecorationData{
            .asset = addm.getT(.string, "asset").?,
            .sku_id = addm.getT(.string, "sku_id").?,
        } else null,
    };
    return member;
}

pub fn parseMessage(obj: *zmpl.Data.Object) Discord.Message {
    var buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);

    // parse mentions
    const mentions_obj = obj.getT(.array, "mentions").?;

    var mentions = std.ArrayList(Discord.User).init(fba.allocator());
    defer mentions.deinit();

    while (mentions_obj.iterator().next()) |m| {
        mentions.append(parseUser(&m.object)) catch unreachable;
    }

    // parse member
    const member = parseMember(obj.getT(.object, "member").?);

    // parse message
    const author = parseUser(obj.getT(.object, "author").?);

    //_ = if (obj.getT(.object, "referenced_message")) |m| parseMessage(m) else null;

    // parse message
    const message = Discord.Message{
        // the id
        .id = obj.getT(.string, "id").?,
        .tts = obj.getT(.boolean, "tts").?,
        .mention_everyone = obj.getT(.boolean, "mention_everyone").?,
        .pinned = obj.getT(.boolean, "pinned").?,
        .type = @as(Discord.MessageTypes, @enumFromInt(obj.getT(.integer, "type").?)),
        .channel_id = obj.getT(.string, "channel_id").?,
        .author = author,
        .member = member,
        .content = obj.getT(.string, "content"),
        .timestamp = obj.getT(.string, "timestamp").?,
        .guild_id = obj.getT(.string, "guild_id"),
        .attachments = &[0]Discord.Attachment{},
        .edited_timestamp = null,
        .mentions = mentions.items,
        .mention_roles = &[0]?[]const u8{},
        .mention_channels = &[0]?Discord.ChannelMention{},
        .embeds = &[0]Discord.Embed{},
        .reactions = &[0]?Discord.Reaction{},
        .nonce = .{ .string = obj.getT(.string, "nonce").? },
        .webhook_id = obj.getT(.string, "webhook_id"),
        .activity = null,
        .application = null,
        .application_id = obj.getT(.string, "application_id"),
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
        .referenced_message = null,
    };
    return message;
}
