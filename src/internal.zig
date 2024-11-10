const std = @import("std");
const mem = std.mem;
const Deque = @import("deque").Deque;
const Discord = @import("types.zig");
const builtin = @import("builtin");
const IdentifyProperties = @import("shared.zig").IdentifyProperties;

pub const debug = std.log.scoped(.@"discord.zig");

pub const Log = union(enum) { yes, no };

pub const default_identify_properties = IdentifyProperties{
    .os = @tagName(builtin.os.tag),
    .browser = "discord.zig",
    .device = "discord.zig",
};

/// inspired from:
/// https://github.com/tiramisulabs/seyfert/blob/main/src/websocket/structures/timeout.ts
pub fn ConnectQueue(comptime T: type) type {
    return struct {
        pub const RequestWithShard = struct {
            callback: *const fn (self: *RequestWithShard) anyerror!void,
            shard: T,
        };

        dequeue: Deque(RequestWithShard),
        allocator: mem.Allocator,
        remaining: usize,
        interval_time: u64 = 5000,
        running: bool = false,
        concurrency: usize = 1,

        pub fn init(allocator: mem.Allocator, concurrency: usize, interval_time: u64) !ConnectQueue(T) {
            return .{
                .allocator = allocator,
                .dequeue = try Deque(RequestWithShard).init(allocator),
                .remaining = concurrency,
                .interval_time = interval_time,
                .concurrency = concurrency,
            };
        }

        pub fn deinit(self: *ConnectQueue(T)) void {
            self.dequeue.deinit();
        }

        pub fn push(self: *ConnectQueue(T), req: RequestWithShard) !void {
            if (self.remaining == 0) {
                return self.dequeue.pushBack(req);
            }
            self.remaining -= 1;

            if (!self.running) {
                try self.startInterval();
                self.running = true;
            }

            if (self.dequeue.len() < self.concurrency) {
                // perhaps store this?
                const ptr = try self.allocator.create(RequestWithShard);
                ptr.* = req;
                try @call(.auto, req.callback, .{ptr});
                return;
            }

            return self.dequeue.pushBack(req);
        }

        fn startInterval(self: *ConnectQueue(T)) !void {
            while (self.running) {
                std.Thread.sleep(std.time.ns_per_ms * (self.interval_time / self.concurrency));
                const req: ?RequestWithShard = self.dequeue.popFront();

                while (self.dequeue.len() == 0 and req == null) {}

                if (req) |r| {
                    const ptr = try self.allocator.create(RequestWithShard);
                    ptr.* = r;
                    try @call(.auto, r.callback, .{ptr});
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
}

pub const Bucket = struct {
    /// The queue of requests to acquire an available request. Mapped by (shardId, RequestWithPrio)
    queue: std.PriorityQueue(RequestWithPrio, void, Bucket.lessthan),

    limit: usize,
    refill_interval: u64,
    refill_amount: usize,

    /// The amount of requests that have been used up already.
    used: usize = 0,

    /// Whether or not the queue is already processing.
    processing: bool = false,

    /// Whether the timeout should be killed because there is already one running
    should_stop: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    /// The timestamp in milliseconds when the next refill is scheduled.
    refills_at: ?u64 = null,

    pub const RequestWithPrio = struct {
        callback: *const fn () void,
        priority: u32 = 1,
    };

    fn lessthan(_: void, a: RequestWithPrio, b: RequestWithPrio) std.math.Order {
        return std.math.order(a.priority, b.priority);
    }

    pub fn init(allocator: mem.Allocator, limit: usize, refill_interval: u64, refill_amount: usize) Bucket {
        return .{
            .queue = std.PriorityQueue(RequestWithPrio, void, lessthan).init(allocator, {}),
            .limit = limit,
            .refill_interval = refill_interval,
            .refill_amount = refill_amount,
        };
    }

    fn remaining(self: *Bucket) usize {
        if (self.limit < self.used) {
            return 0;
        } else {
            return self.limit - self.used;
        }
    }

    pub fn refill(self: *Bucket) std.Thread.SpawnError!void {
        // Lower the used amount by the refill amount
        self.used = if (self.refill_amount > self.used) 0 else self.used - self.refill_amount;

        // Reset the refills_at timestamp since it just got refilled
        self.refills_at = null;

        if (self.used > 0) {
            if (self.should_stop.load(.monotonic) == true) {
                self.should_stop.store(false, .monotonic);
            }
            const thread = try std.Thread.spawn(.{}, Bucket.timeout, .{self});
            thread.detach;
            self.refills_at = std.time.milliTimestamp() + self.refill_interval;
        }
    }

    fn timeout(self: *Bucket) void {
        while (!self.should_stop.load(.monotonic)) {
            self.refill();
            std.time.sleep(std.time.ns_per_ms * self.refill_interval);
        }
    }

    pub fn processQueue(self: *Bucket) std.Thread.SpawnError!void {
        if (self.processing) return;

        while (self.queue.remove()) |first_element| {
            if (self.remaining() != 0) {
                first_element.callback();
                self.used += 1;

                if (!self.should_stop.load(.monotonic)) {
                    const thread = try std.Thread.spawn(.{}, Bucket.timeout, .{self});
                    thread.detach;
                    self.refills_at = std.time.milliTimestamp() + self.refill_interval;
                }
            } else if (self.refills_at) |ra| {
                const now = std.time.milliTimestamp();
                if (ra > now) std.time.sleep(std.time.ns_per_ms * (ra - now));
            }
        }

        self.processing = false;
    }

    pub fn acquire(self: *Bucket, rq: RequestWithPrio) !void {
        try self.queue.add(rq);
        try self.processQueue();
    }
};

pub fn GatewayDispatchEvent(comptime T: type) type {
    return struct {
        // TODO: implement // application_command_permissions_update: null = null,
        // TODO: implement // auto_moderation_rule_create: null = null,
        // TODO: implement // auto_moderation_rule_update: null = null,
        // TODO: implement // auto_moderation_rule_delete: null = null,
        // TODO: implement // auto_moderation_action_execution: null = null,
        // TODO: implement // channel_create: null = null,
        // TODO: implement // channel_update: null = null,
        // TODO: implement // channel_delete: null = null,
        // TODO: implement // channel_pins_update: null = null,
        // TODO: implement // thread_create: null = null,
        // TODO: implement // thread_update: null = null,
        // TODO: implement // thread_delete: null = null,
        // TODO: implement // thread_list_sync: null = null,
        // TODO: implement // thread_member_update: null = null,
        // TODO: implement // thread_members_update: null = null,
        // TODO: implement // guild_audit_log_entry_create: null = null,
        // TODO: implement // guild_create: null = null,
        // TODO: implement // guild_update: null = null,
        // TODO: implement // guild_delete: null = null,
        // TODO: implement // guild_ban_add: null = null,
        // TODO: implement // guild_ban_remove: null = null,
        // TODO: implement // guild_emojis_update: null = null,
        // TODO: implement // guild_stickers_update: null = null,
        // TODO: implement // guild_integrations_update: null = null,
        // TODO: implement // guild_member_add: null = null,
        // TODO: implement // guild_member_remove: null = null,
        // TODO: implement // guild_member_update: null = null,
        // TODO: implement // guild_members_chunk: null = null,
        // TODO: implement // guild_role_create: null = null,
        // TODO: implement // guild_role_update: null = null,
        // TODO: implement // guild_role_delete: null = null,
        // TODO: implement // guild_scheduled_event_create: null = null,
        // TODO: implement // guild_scheduled_event_update: null = null,
        // TODO: implement // guild_scheduled_event_delete: null = null,
        // TODO: implement // guild_scheduled_event_user_add: null = null,
        // TODO: implement // guild_scheduled_event_user_remove: null = null,
        // TODO: implement // integration_create: null = null,
        // TODO: implement // integration_update: null = null,
        // TODO: implement // integration_delete: null = null,
        // TODO: implement // interaction_create: null = null,
        // TODO: implement // invite_create: null = null,
        // TODO: implement // invite_delete: null = null,
        message_create: ?*const fn (save: T, message: Discord.Message) void = undefined,
        message_update: ?*const fn (save: T, message: Discord.Message) void = undefined,
        message_delete: ?*const fn (save: T, log: Discord.MessageDelete) void = undefined,
        message_delete_bulk: ?*const fn (save: T, log: Discord.MessageDeleteBulk) void = undefined,
        // TODO: implement // message_delete_bulk: null = null,
        // TODO: implement // message_reaction_add: null = null,
        // TODO: implement // message_reaction_remove: null = null,
        // TODO: implement // message_reaction_remove_all: null = null,
        // TODO: implement // message_reaction_remove_emoji: null = null,
        // TODO: implement // presence_update: null = null,
        // TODO: implement // stage_instance_create: null = null,
        // TODO: implement // stage_instance_update: null = null,
        // TODO: implement // stage_instance_delete: null = null,
        // TODO: implement // typing_start: null = null,
        // TODO: implement // user_update: null = null,
        // TODO: implement // voice_channel_effect_send: null = null,
        // TODO: implement // voice_state_update: null = null,
        // TODO: implement // voice_server_update: null = null,
        // TODO: implement // webhooks_update: null = null,
        // TODO: implement // entitlement_create: null = null,
        // TODO: implement // entitlement_update: null = null,
        // TODO: implement // entitlement_delete: null = null,
        // TODO: implement // message_poll_vote_add: null = null,
        // TODO: implement // message_poll_vote_remove: null = null,

        ready: ?*const fn (save: T, data: Discord.Ready) void = undefined,
        // TODO: implement // resumed: null = null,
        any: ?*const fn (save: T, data: []const u8) void = undefined,
    };
}
