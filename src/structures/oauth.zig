const OAuth2Scope = @import("shared.zig").OAuth2Scope;
const Guild = @import("guild.zig").Guild;
const IncomingWebhook = @import("webhook.zig").IncomingWebhook;

pub const TokenExchangeAuthorizationCode = struct {
    grant_type: []const u8, //"authorization_code",
    /// The code for the token exchange
    code: []const u8,
    /// The redirect_uri associated with this authorization
    redirect_uri: []const u8,
};

/// https://discord.com/developers/docs/topics/oauth2#client-credentials-grant
pub const TokenExchangeRefreshToken = struct {
    grant_type: "refresh_token",
    /// the user's refresh token
    refresh_token: []const u8,
};

/// https://discord.com/developers/docs/topics/oauth2#client-credentials-grant
pub const TokenExchangeClientCredentials = struct {
    grant_type: "client_credentials",
    /// The scope(s) for the access token
    scope: []OAuth2Scope,
};

pub const AccessTokenResponse = struct {
    /// The access token of the user
    access_token: []const u8,
    /// The type of token
    token_type: []const u8,
    /// The isize of seconds after that the access token is expired
    expires_in: isize,
    ///
    /// The refresh token to refresh the access token
    ///
    /// @remarks
    /// When the token exchange is a client credentials type grant this value is not defined.
    ///
    refresh_token: []const u8,
    /// The scopes for the access token
    scope: []const u8,
    /// The webhook the user created for the application. Requires the `webhook.incoming` scope
    webhook: ?IncomingWebhook,
    /// The guild the bot has been added. Requires the `bot` scope
    guild: ?Guild,
};
