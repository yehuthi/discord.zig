const std = @import("std");
const mem = std.mem;
const Deque = @import("deque");

/// inspired from:
/// https://github.com/tiramisulabs/seyfert/blob/main/src/websocket/structures/timeout.ts
pub const ConnectQueue = struct {
    dequeue: Deque(*const fn () void),
    allocator: mem.Allocator,
    remaining: usize,
    interval_time: u64 = 5000,
    running: bool,
    concurrency: usize = 1,

    pub fn init(allocator: mem.Allocator, concurrency: usize, interval_time: u64) !ConnectQueue {
        return .{
            .allocator = allocator,
            .dequeue = try Deque(*const fn () void).init(allocator),
            .remaining = concurrency,
            .interval_time = interval_time,
            .concurrency = concurrency,
        };
    }

    pub fn deinit(self: *ConnectQueue) void {
        self.dequeue.deinit();
    }

    pub fn push(self: *ConnectQueue, callback: *const fn () void) !void {
        if (self.remaining == 0) {
            return self.dequeue.pushBack(callback);
        }
        self.remaining -= 1;

        if (!self.running) {
            self.startInterval();
            self.running = true;
        }

        if (self.dequeue.items.len < self.concurrency) {
            @call(.auto, callback, .{});
            return;
        }

        return self.dequeue.pushBack(callback);
    }

    fn startInterval(self: *ConnectQueue) void {
        while (self.running) {
            std.Thread.sleep(std.time.ns_per_ms * (self.interval_time / self.concurrency));
            const callback: ?*const fn () void = self.dequeue.popFront();

            while (self.dequeue.items.len == 0 and callback == null) {}

            if (callback) |cb| {
                @call(.auto, cb, .{});
                return;
            }

            if (self.remaining < self.concurrency) {
                self.remaining += 1;
            }

            if (self.dequeue.len() == 0) {
                self.running = false;
            }
        }
    }
};
