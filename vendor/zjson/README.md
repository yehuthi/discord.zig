## zjson

basic usage
```zig
const json = @import("zjson");

const data: []const u8 =
    \\ {
    \\   "username": "yuzu",
    \\   "id": 10000,
    \\   "bot": true
    \\ }
;

const User = struct {
    username: []const u8,
    id: u64,
    bot: bool,
};

const my_user = try json.parse(User, std.testing.allocator, data);
defer my_user.deinit();

try std.testing.expectEqual(10000, my_user.value.id);
try std.testing.expectEqualStrings("yuzu", my_user.value.username);
try std.testing.expect(my_user.bot);
```

definition of your custom parsing as follows
you can define your own to tell the parser how to behave
```zig
/// this is named after the TypeScript `Record<K, V>`
pub fn Record(comptime T: type) type {
    return struct {
        /// the actual data
        map: std.StringHashMapUnmanaged(T),

        /// any function `toJson` has this signature
        pub fn toJson(allocator: mem.Allocator, value: JsonType) !@This() {
            var map: std.StringHashMapUnmanaged(T) = .{};

            var iterator = value.object.iterator();

            while (iterator.next()) |pair| {
                const k = pair.key_ptr.*;
                const v = pair.value_ptr.*;

                // make sure to delete this as placing might fail
                errdefer allocator.free(k);
                errdefer v.deinit(allocator);
                try map.put(allocator, k, try parseInto(T, allocator, v));
            }

            return .{ .map = map };
        }
    };
}
```
