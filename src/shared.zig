const Intents = @import("types.zig").Intents;
const default_identify_properties = @import("internal.zig").default_identify_properties;
const std = @import("std");

pub const IdentifyProperties = struct {
    /// Operating system the shard runs on.
    os: []const u8,
    /// The "browser" where this shard is running on.
    browser: []const u8,
    /// The device on which the shard is running.
    device: []const u8,

    system_locale: ?[]const u8 = null, // TODO parse this
    browser_user_agent: ?[]const u8 = null,
    browser_version: ?[]const u8 = null,
    os_version: ?[]const u8 = null,
    referrer: ?[]const u8 = null,
    referring_domain: ?[]const u8 = null,
    referrer_current: ?[]const u8 = null,
    referring_domain_current: ?[]const u8 = null,
    release_channel: ?[]const u8 = null,
    client_build_number: ?u64 = null,
    client_event_source: ?[]const u8 = null,
};

/// https://discord.com/developers/docs/topics/gateway#get-gateway
pub const GatewayInfo = struct {
    /// The WSS URL that can be used for connecting to the gateway
    url: []const u8,
};

/// https://discord.com/developers/docs/events/gateway#session-start-limit-object
pub const GatewaySessionStartLimit = struct {
    /// Total number of session starts the current user is allowed
    total: u32,
    /// Remaining number of session starts the current user is allowed
    remaining: u32,
    /// Number of milliseconds after which the limit resets
    reset_after: u32,
    /// Number of identify requests allowed per 5 seconds
    max_concurrency: u32,
};

/// https://discord.com/developers/docs/topics/gateway#get-gateway-bot
pub const GatewayBotInfo = struct {
    url: []const u8,
    /// The recommended number of shards to use when connecting
    ///
    /// See https://discord.com/developers/docs/topics/gateway#sharding
    shards: u32,
    /// Information on the current session start limit
    ///
    /// See https://discord.com/developers/docs/topics/gateway#session-start-limit-object
    session_start_limit: ?GatewaySessionStartLimit,
};

pub const ShardDetails = struct {
    /// Bot token which is used to connect to Discord */
    token: []const u8,
    /// The URL of the gateway which should be connected to.
    url: []const u8 = "wss://gateway.discord.gg",
    /// The gateway version which should be used.
    version: ?usize = 10,
    /// The calculated intent value of the events which the shard should receive.
    intents: Intents,
    /// Identify properties to use
    properties: IdentifyProperties = default_identify_properties,
};

pub const Snowflake = struct {
    id: u64,

    pub fn fromMaybe(raw: ?[]const u8) !?Snowflake {
        if (raw) |id| {
            return .{
                .id = try std.fmt.parseInt(u64, id, 10),
            };
        } else return null;
    }

    pub fn fromRaw(raw: []const u8) !Snowflake {
        return .{
            .id = try std.fmt.parseInt(u64, raw, 10),
        };
    }

    pub fn fromMany(many: [][]const u8) ![]Snowflake {
        var array = try std.BoundedArray(Snowflake, 64).init(many.len);

        for (many) |id| {
            try array.append(try Snowflake.fromRaw(id));
        }

        return array.slice();
    }

    pub fn value(self: Snowflake) u64 {
        return self.id;
    }
};
