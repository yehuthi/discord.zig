const std = @import("std");
const mem = std.mem;
const Deque = @import("deque");
const Discord = @import("types.zig");

pub const debug = std.log.scoped(.@"discord.zig");

pub const Log = union(enum) { yes, no };

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

fn lessthan(_: void, a: RequestWithPrio, b: RequestWithPrio) void {
    return std.math.order(a, b);
}

pub const Bucket = struct {
    /// The queue of requests to acquire an available request. Mapped by (shardId, RequestWithPrio)
    queue: std.PriorityQueue(RequestWithPrio, void, lessthan),

    limit: usize,
    refillInterval: u64,
    refillAmount: usize,

    /// The amount of requests that have been used up already.
    used: usize = 0,

    /// Whether or not the queue is already processing.
    processing: bool = false,

    /// Whether the timeout should be killed because there is already one running
    shouldStop: bool = false,

    /// The timestamp in milliseconds when the next refill is scheduled.
    refillsAt: ?u64,

    /// comes in handy
    m: std.Thread.Mutex = .{},
    c: std.Thread.Condition = .{},

    fn timeout(self: *Bucket) void {
        _ = self;
    }

    pub fn processQueue() !void {}
    pub fn refill() void {}

    pub fn acquire(self: *Bucket, rq: RequestWithPrio) !void {
        try self.queue.add(rq);
        try self.processQueue();
    }
};

pub const RequestWithPrio = struct {
    callback: *const fn () void,
    priority: u32,
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
