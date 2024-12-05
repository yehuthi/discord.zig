const std = @import("std");
const zjson = @import("json");

pub const Snowflake = enum(u64) {
    _,

    pub fn into(self: Snowflake) u64 {
        return @intFromEnum(self);
    }

    pub fn fromMaybe(raw: ?[]const u8) std.fmt.ParseIntError!?Snowflake {
        if (raw) |id| return @enumFromInt(try std.fmt.parseInt(u64, id, 10));
        return null;
    }

    pub fn fromRaw(raw: []const u8) std.fmt.ParseIntError!Snowflake {
        return @enumFromInt(try std.fmt.parseInt(u64, raw, 10));
    }

    pub fn fromMany(allocator: std.mem.Allocator, many: [][]const u8) ![]Snowflake {
        var array = std.ArrayList(Snowflake).init(allocator);

        for (many) |id|
            try array.append(try Snowflake.fromRaw(id));

        return array.toOwnedSlice();
    }

    pub fn toJson(_: std.mem.Allocator, value: zjson.JsonType) !@This() {
        if (value.is(.string))
            return Snowflake.fromRaw(value.string) catch unreachable;
        unreachable;
    }
};
