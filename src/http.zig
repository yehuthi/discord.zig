const std = @import("std");
const mem = std.mem;
const http = std.http;
const json = std.json;
const zjson = @import("json");

pub const BASE_URL = "https://discord.com/api/v10";

// zig fmt: off
pub const MakeRequestError = (
       std.fmt.BufPrintError
    || http.Client.ConnectTcpError
    || http.Client.Request.WaitError
    || http.Client.Request.FinishError
    || http.Client.Request.Writer.Error
    || http.Client.Request.Reader.Error
    || std.Uri.ResolveInPlaceError
    || error{StreamTooLong}
);
// zig fmt: on

pub const FetchReq = struct {
    allocator: mem.Allocator,
    token: []const u8,
    client: http.Client,
    body: std.ArrayList(u8),

    pub fn init(allocator: mem.Allocator, token: []const u8) FetchReq {
        const client = http.Client{ .allocator = allocator };
        return FetchReq{
            .allocator = allocator,
            .client = client,
            .body = std.ArrayList(u8).init(allocator),
            .token = token,
        };
    }

    pub fn deinit(self: *FetchReq) void {
        self.client.deinit();
        self.body.deinit();
    }

    pub fn get(self: *FetchReq, comptime T: type, path: []const u8) !zjson.Owned(T) {
        const result = try self.makeRequest(.GET, path, null);
        if (result.status != .ok)
            return error.FailedRequest;

        const output = try zjson.parse(T, self.allocator, try self.body.toOwnedSlice());
        return output;
    }

    pub fn delete(self: *FetchReq, path: []const u8) !void {
        const result = try self.makeRequest(.DELETE, path, null);
        if (result.status != .no_content)
            return error.FailedRequest;
    }

    pub fn patch(self: *FetchReq, comptime T: type, path: []const u8, object: anytype) !zjson.Owned(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PATCH, path, try string.toOwnedSlice());

        if (result.status != .ok)
            return error.FailedRequest;

        return try zjson.parse(T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn patch2(self: *FetchReq, path: []const u8, object: anytype) !void {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PATCH, path, try string.toOwnedSlice());

        if (result.status != .no_content)
            return error.FailedRequest;
    }

    pub fn put(self: *FetchReq, comptime T: type, path: []const u8, object: anytype) !zjson.Owned(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PUT, path, try string.toOwnedSlice());

        if (result.status != .ok)
            return error.FailedRequest;

        return try zjson.parse(T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn put2(self: *FetchReq, comptime T: type, path: []const u8, object: anytype) !?zjson.Owned(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PUT, path, try string.toOwnedSlice());

        if (result.status == .no_content)
            return null;

        return try zjson.parse(T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn put3(self: *FetchReq, path: []const u8) !void {
        const result = try self.makeRequest(.PUT, path, null);

        if (result.status != .no_content)
            return error.FailedRequest;
    }

    pub fn post(self: *FetchReq, comptime T: type, path: []const u8, object: anytype) !zjson.Owned(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.POST, path, try string.toOwnedSlice());

        if (result.status != .ok)
            return error.FailedRequest;

        return try zjson.parse(T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn makeRequest(self: *FetchReq, method: http.Method, path: []const u8, to_post: ?[]const u8) MakeRequestError!http.Client.FetchResult {
        var buf: [256]u8 = undefined;
        const constructed = try std.fmt.bufPrint(&buf, "{s}{s}", .{ BASE_URL, path });

        var fetch_options = http.Client.FetchOptions{
            .location = http.Client.FetchOptions.Location{ .url = constructed },
            .extra_headers = &[_]http.Header{
                http.Header{ .name = "Accept", .value = "application/json" },
                http.Header{ .name = "Content-Type", .value = "application/json" },
                http.Header{ .name = "Authorization", .value = self.token },
            },
            .method = method,
            .response_storage = .{ .dynamic = &self.body },
        };

        if (to_post != null) {
            fetch_options.payload = to_post;
        }

        const res = try self.client.fetch(fetch_options);
        return res;
    }
};
