//! ISC License
//!
//! Copyright (c) 2024-2025 Yuzu
//!
//! Permission to use, copy, modify, and/or distribute this software for any
//! purpose with or without fee is hereby granted, provided that the above
//! copyright notice and this permission notice appear in all copies.
//!
//! THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//! REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
//! AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
//! INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
//! LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
//! OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
//! PERFORMANCE OF THIS SOFTWARE.

const std = @import("std");
const zjson = @import("json");

pub const Snowflake = enum(u64) {
    _,

    pub fn into(self: Snowflake) u64 {
        return @intFromEnum(self);
    }

    pub fn from(int: u64) Snowflake {
        return @enumFromInt(int);
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
            return Snowflake.fromRaw(value.string) catch std.debug.panic("invalid snowflake: {s}\n", .{value.string});
        unreachable;
    }

    pub fn format(self: Snowflake) ![]const u8 {
        var buf: [256]u8 = undefined;
        return std.fmt.bufPrint(&buf, "{d}\n", .{self.into()});
    }
};
