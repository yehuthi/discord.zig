const std = @import("std");

pub fn Partial(comptime T: type) type {
    const info = @typeInfo(T);
    switch (info) {
        .@"struct" => |s| {
            comptime var fields: []const std.builtin.Type.StructField = &[_]std.builtin.Type.StructField{};
            inline for (s.fields) |field| {
                if (field.is_comptime) {
                    @compileError("Cannot make Partial of " ++ @typeName(T) ++ ", it has a comptime field " ++ field.name);
                }
                const optional_type = switch (@typeInfo(field.type)) {
                    .optional => field.type,
                    else => ?field.type,
                };
                const default_value: optional_type = null;
                const aligned_ptr: *align(field.alignment) const anyopaque = @alignCast(@ptrCast(&default_value));
                const optional_field: [1]std.builtin.Type.StructField = [_]std.builtin.Type.StructField{.{
                    .alignment = field.alignment,
                    .default_value = aligned_ptr,
                    .is_comptime = false,
                    .name = field.name,
                    .type = optional_type,
                }};
                fields = fields ++ optional_field;
            }
            const partial_type_info: std.builtin.Type = .{ .@"struct" = .{
                .backing_integer = s.backing_integer,
                .decls = &[_]std.builtin.Type.Declaration{},
                .fields = fields,
                .is_tuple = s.is_tuple,
                .layout = s.layout,
            } };
            return @Type(partial_type_info);
        },
        else => @compileError("Cannot make Partial of " ++ @typeName(T) ++
            ", the type must be a struct"),
    }
    unreachable;
}
