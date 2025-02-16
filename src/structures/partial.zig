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
                    .default_value_ptr = aligned_ptr,
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
