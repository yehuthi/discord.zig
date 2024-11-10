const std = @import("std");
const mem = std.mem;
const http = std.http;

pub const BASE_URL = "https://discord.com/api/v10";

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

    pub fn makeRequest(self: *FetchReq, method: http.Method, path: []const u8, to_post: ?[]const u8) !http.Client.FetchResult {
        var fetch_options = http.Client.FetchOptions{
            .location = http.Client.FetchOptions.Location{
                .url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ BASE_URL, path }),
            },
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
