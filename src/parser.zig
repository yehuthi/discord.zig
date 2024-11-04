const zmpl = @import("zmpl");
const Discord = @import("raw_types.zig");

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
