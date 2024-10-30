const std = @import("std");

const Thread = std.Thread;
const Allocator = std.mem.Allocator;

fn Job(comptime T: type) type {
    return struct {
        at: i64,
        task: T,
    };
}

pub fn Scheduler(comptime T: type, comptime C: type) type {
    return struct {
        queue: Q,
        running: bool,
        mutex: Thread.Mutex,
        cond: Thread.Condition,
        thread: ?Thread,

        const Q = std.PriorityQueue(Job(T), void, compare);

        fn compare(_: void, a: Job(T), b: Job(T)) std.math.Order {
            return std.math.order(a.at, b.at);
        }

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{
                .cond = .{},
                .mutex = .{},
                .thread = null,
                .running = false,
                .queue = Q.init(allocator, {}),
            };
        }

        pub fn deinit(self: *Self) void {
            self.stop();
            self.queue.deinit();
        }

        pub fn start(self: *Self, ctx: C) !void {
            {
                self.mutex.lock();
                defer self.mutex.unlock();
                if (self.running == true) {
                    return error.AlreadyRunning;
                }
                self.running = true;
            }
            self.thread = try Thread.spawn(.{}, Self.run, .{ self, ctx });
        }

        pub fn stop(self: *Self) void {
            {
                self.mutex.lock();
                defer self.mutex.unlock();
                if (self.running == false) {
                    return;
                }
                self.running = false;
            }

            self.cond.signal();
            self.thread.?.join();
        }

        pub fn scheduleIn(self: *Self, task: T, ms: i64) !void {
            return self.schedule(task, std.time.milliTimestamp() + ms);
        }

        pub fn schedule(self: *Self, task: T, at: i64) !void {
            const job: Job(T) = .{
                .at = at,
                .task = task,
            };

            var reschedule = false;
            {
                self.mutex.lock();
                defer self.mutex.unlock();

                if (self.queue.peek()) |*next| {
                    if (at < next.at) {
                        reschedule = true;
                    }
                } else {
                    reschedule = true;
                }
                try self.queue.add(job);
            }

            if (reschedule) {
                // Our new job is scheduled before our previous earlier job
                // (or we had no previous jobs)
                // We need to reset our schedule
                self.cond.signal();
            }
        }

        // this is running in a separate thread, started by start()
        fn run(self: *Self, ctx: C) void {
            self.mutex.lock();

            while (true) {
                const ms_until_next = self.processPending(ctx);

                // mutex is locked when returning for processPending

                if (self.running == false) {
                    self.mutex.unlock();
                    return;
                }

                if (ms_until_next) |timeout| {
                    const ns = @as(u64, @intCast(timeout * std.time.ns_per_ms));
                    self.cond.timedWait(&self.mutex, ns) catch |err| {
                        std.debug.assert(err == error.Timeout);
                        // on success or error, cond locks mutex, which is what we want
                    };
                } else {
                    self.cond.wait(&self.mutex);
                }
                // if we woke up, it's because a new job was added with a more recent
                // scheduled time. This new job MAY not be ready to run yet, and
                // it's even possible for our cond variable to wake up randomly (as per
                // the docs), but processPending is defensive and will check this for us.
            }
        }

        // we enter this function with mutex locked
        // and we exit this function with the mutex locked
        // importantly, we don't lock the mutex will process the task
        fn processPending(self: *Self, ctx: C) ?i64 {
            while (true) {
                const next = self.queue.peek() orelse {
                    // yes, we must return this function with a locked mutex
                    return null;
                };
                const seconds_until_next = next.at - std.time.milliTimestamp();
                if (seconds_until_next > 0) {
                    // this job isn't ready, yes, the mutex should remain locked!
                    return seconds_until_next;
                }

                // delete the peeked job from the queue, because we're going to process it
                const job = self.queue.remove();
                self.mutex.unlock();
                defer self.mutex.lock();
                job.task.run(ctx, next.at);
            }
        }
    };
}
