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

const Snowflake = @import("snowflake.zig").Snowflake;
const ApplicationFlags = @import("shared.zig").ApplicationFlags;
const OAuth2Scope = @import("shared.zig").OAuth2Scope;
const Partial = @import("partial.zig").Partial;
const User = @import("user.zig").User;
const Team = @import("team.zig").Team;
const Guild = @import("guild.zig").Guild;

/// https://discord.com/developers/docs/resources/application#application-object
pub const Application = struct {
    /// The name of the app
    name: []const u8,
    /// The description of the app
    description: []const u8,
    /// An array of rpc origin urls, if rpc is enabled
    rpc_origins: ?[][]const u8,
    /// The url of the app's terms of service
    terms_of_service_url: ?[]const u8,
    /// The url of the app's privacy policy
    privacy_policy_url: ?[]const u8,
    /// The hex encoded key for verification in interactions and the GameSDK's GetTicket
    verify_key: []const u8,
    ///If this application is a game sold on , this field will be the id of the "Game SKU" that is created, if exists
    primary_sku_id: ?Snowflake,
    ///If this application is a game sold on , this field will be the URL slug that links to the store page
    slug: ?[]const u8,
    /// The application's public flags
    flags: ?ApplicationFlags,
    /// The id of the app
    id: Snowflake,
    /// The icon hash of the app
    icon: ?[]const u8,
    /// When false only app owner can join the app's bot to guilds
    bot_public: bool,
    /// When true the app's bot will only join upon completion of the full oauth2 code grant flow
    bot_require_code_grant: bool,
    /// Partial user object containing info on the owner of the application
    owner: ?Partial(User),
    /// If the application belongs to a team, this will be a list of the members of that team
    team: ?Team,
    /// Guild associated with the app. For example, a developer support server.
    guild_id: ?Snowflake,
    /// A partial object of the associated guild
    guild: ?Partial(Guild),
    ///If this application is a game sold on , this field will be the hash of the image on store embeds
    cover_image: ?[]const u8,
    /// up to 5 tags describing the content and functionality of the application
    tags: ?[][]const u8,
    /// settings for the application's default in-app authorization link, if enabled
    install_params: ?InstallParams,
    // Default scopes and permissions for each supported installation context.
    // partial?
    // integration_types_config: ?Record(ApplicationIntegrationType, ApplicationIntegrationTypeConfiguration),

    /// the application's default custom authorization link, if enabled
    custom_install_url: ?[]const u8,
    /// the application's role connection verification entry point, which when configured will render the app as a verification method in the guild role verification configuration
    role_connections_verification_url: ?[]const u8,
    /// An approximate count of the app's guild membership.
    approximate_guild_count: ?isize,
    /// Approximate count of users that have installed the app.
    approximate_user_install_count: ?isize,
    /// Partial user object for the bot user associated with the app
    bot: ?Partial(User),
    /// Array of redirect URIs for the app
    redirect_uris: ?[][]const u8,
    /// Interactions endpoint URL for the app
    interactions_endpoint_url: ?[]const u8,
};

/// https://discord.com/developers/docs/resources/application#application-object-application-integration-type-configuration-object
pub const ApplicationIntegrationTypeConfiguration = struct {
    ///
    /// Install params for each installation context's default in-app authorization link
    ///
    /// https://discord.com/developers/docs/resources/application#install-params-object-install-params-structure
    ///
    oauth2_install_params: ?InstallParams,
};

pub const ApplicationIntegrationType = enum(u4) {
    /// App is installable to servers
    GuildInstall = 0,
    /// App is installable to users
    UserInstall = 1,
};

pub const InstallParams = struct {
    /// Scopes to add the application to the server with
    scopes: []OAuth2Scope,
    /// Permissions to request for the bot role
    permissions: []const u8,
};
