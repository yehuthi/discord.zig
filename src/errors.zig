/// an error ought to be matched by `code` for providing the end user with sensible errors
pub const DiscordErrorPayload = struct {
    /// cryptic error code, eg: `MISSING_PERMISSIONS`
    code: []const u8,
    /// human readable error message
    message: []const u8,
};

pub const DiscordError = struct {
    code: usize,
    message: []const u8,
    errors: ?struct { _errors: []DiscordErrorPayload },
};

pub fn Result(comptime T: type) type {
    return @import("json.zig").OwnedEither(DiscordError, T);
}
