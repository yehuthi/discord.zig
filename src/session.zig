const ConnectQueue = @import("internal.zig").ConnectQueue;
const Intents = @import("types.zig").Intents;
const GatewayBotInfo = @import("shared.zig").GatewayBotInfo;
const IdentifyProperties = @import("shared.zig").IdentifyProperties;

pub const ShardDetails = struct {
    /// Bot token which is used to connect to Discord */
    token: []const u8,
    ///
    /// The URL of the gateway which should be connected to.
    ///
    url: []const u8 = "wss://gateway.discord.gg",
    ///
    /// The gateway version which should be used.
    /// @default 10
    ///
    version: ?usize = 10,
    ///
    /// The calculated intent value of the events which the shard should receive.
    ///
    intents: Intents,
    ///
    /// Identify properties to use
    ///
    properties: ?IdentifyProperties,
};

pub const SessionOptions = struct {
    /// Important data which is used by the manager to connect shards to the gateway. */
    info: GatewayBotInfo,
    /// Delay in milliseconds to wait before spawning next shard. OPTIMAL IS ABOVE 5100. YOU DON'T WANT TO HIT THE RATE LIMIT!!!
    spawnShardDelay: ?u64 = 5300,
    /// Total amount of shards your bot uses. Useful for zero-downtime updates or resharding.
    totalShards: ?usize = 1,
    shardStart: ?usize,
    shardEnd: ?usize,
    ///
    /// The payload handlers for messages on the shard.
    /// TODO:
    /// handlePayload: (shardId: number, packet: GatewayDispatchPayload): unknown;
    ///
    resharding: ?struct {
        interval: u64,
        percentage: usize,
    },
};
