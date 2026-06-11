# Auto-generated client for Clerk Frontend API vv1
# Source: https://raw.githubusercontent.com/clerk/openapi-specs/main/fapi/2026-05-12.yml
# Auth: --token flag or $env.CLERK_FRONTEND_API_TOKEN

const BASE_URL = "https://example-destined-camel-13.clerk.accounts.dev"
const DEFAULT_AUTH = "cookie-__client"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLERK_FRONTEND_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "cookie-__client" => { {headers: {Cookie: $"__client=($token_val)"}, query: ""} }
    "query-__dev_session" => { {headers: {}, query: $"__dev_session=($token_val)"} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "query-_is_native" => { {headers: {}, query: $"_is_native=($token_val)"} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://example-destined-camel-13.clerk.accounts.dev"] }
def auth-scheme-completer [] { ["cookie-__client" "query-__dev_session" "bearer" "query-_is_native" "basic"] }

# Completers for enum parameters
def response-type-completer [] { ["code"] }
def code-challenge-method-completer [] { ["S256"] }
def response-mode-completer [] { ["form_post" "query"] }
def token-endpoint-auth-method-completer [] { ["client_secret_basic" "client_secret_post" "none"] }
def grant-type-completer [] { ["authorization_code" "refresh_token"] }
def token-type-hint-completer [] { ["access_token" "refresh_token"] }
def strategy-completer [] { ["email_code" "email_link" "phone_code"] }
def strategy-completer-1 [] { ["backup_code" "email_code" "phone_code" "totp"] }
def strategy-completer-2 [] { ["email_code" "email_link" "google_one_tap" "phone_code" "web3_base_signature" "web3_coinbase_wallet_signature" "web3_metamask_signature" "web3_okx_wallet_signature" "web3_solana_signature"] }
def format-completer [] { ["nonce" "token"] }
def intent-completer [] { ["focus" "select_org" "select_session"] }
def level-completer [] { ["first_factor" "multi_factor" "second_factor"] }
def strategy-completer-3 [] { ["email_code" "enterprise_sso" "passkey" "phone_code"] }
def strategy-completer-4 [] { ["email_code" "passkey" "password" "phone_code"] }
def strategy-completer-5 [] { ["phone_code"] }
def strategy-completer-6 [] { ["backup_code" "phone_code" "totp"] }
def strategy-completer-7 [] { ["email_code" "email_link" "enterprise_sso"] }
def strategy-completer-8 [] { ["passkey"] }
def plan-period-completer [] { ["annual" "month"] }
def gateway-completer [] { ["stripe"] }
def payer-type-completer [] { ["org" "user"] }
def status-completer [] { ["accepted" "completed" "expired" "invalid" "pending" "revoked"] }
def include-invalid-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "well-known-assetlinksjson get" } } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name not-in [$mod_name "commands"] | get decl_id)
  scope commands | where decl_id in $cmd_ids | each {|cmd|
    let sig = $cmd.signatures | values | first
    let params = $sig
      | where parameter_type not-in ["input" "output"]
      | where parameter_name not-in $builtin_flags
      | select parameter_name parameter_type syntax_shape is_optional description
    let return_type = ($sig | where parameter_type == "output" | get -o syntax_shape | first | default "any")
    {
      name: ($cmd.name | str replace $"($mod_name) " "")
      description: $cmd.description
      extra_description: $cmd.extra_description
      return_type: $return_type
      params: $params
    }
  }
}

# Get Android Asset Links
#
# GET /.well-known/assetlinks.json
# operationId: getAndroidAssetLinks
export def "well-known-assetlinksjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/assetlinks.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# JWKS
#
# GET /.well-known/jwks.json
# operationId: getJWKS
export def "well-known-jwksjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/jwks.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apple App Site Association
#
# GET /.well-known/apple-app-site-association
# operationId: getAppleAppSiteAssociation
export def "well-known-apple-app-site-association get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/apple-app-site-association")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Basic OpenID Configuration Payload
#
# GET /.well-known/openid-configuration
# operationId: getOpenIDConfiguration
export def "well-known-openid-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/openid-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth 2.0 Authorization Server Metadata
#
# GET /.well-known/oauth-authorization-server
# operationId: getOAuth2AuthorizationServerMetadata
export def "well-known-oauth-authorization-server get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/oauth-authorization-server")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request OAuth2 authorization
#
# GET /oauth/authorize
# operationId: requestOAuthAuthorize
export def "oauth-authorize requestOAuthAuthorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --response-type: string@response-type-completer # The authorization flow type. Must be `code` for authorization code flow.
  --client-id: string # The OAuth2 client ID of the OAuth application.
  --redirect-uri: string # The URI to redirect to after authorization. Must be registered for the OAuth application. (format: uri)
  --scope: list # Space-separated list of scopes being requested. Available scopes are `email`, `profile`, `openid`, `public_metadata`, `private_metadata`, and `user:org:read` (when Organizations are enabled). Defaults to `profile email` if not provided.
  --state: string # An opaque value used to maintain state between the request and callback (minimum 8 characters). Required to prevent CSRF attacks unless PKCE parameters (`code_challenge` and `code_challenge_method`) are provided.
  --prompt: list # Space-separated list of prompts. Supported values are `none` (no user interaction), `login` (force re-authentication), and `consent` (force consent screen).
  --code-challenge: string # The code challenge for PKCE (Proof Key for Code Exchange). Required for public clients.
  --code-challenge-method: string@code-challenge-method-completer # The method used to generate the code challenge. Must be `S256`.
  --response-mode: string@response-mode-completer # The method used to return authorization response parameters. Supported values are `query` (parameters in URL query string) and `form_post` (parameters in POST body).
  --nonce: string # String value used to associate a client session with an ID Token and to mitigate replay attacks. Used in OpenID Connect flows.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "response_type" $response_type "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "scope" $scope "ssv") (serialize-qp "state" $state "scalar") (serialize-qp "prompt" $prompt "ssv") (serialize-qp "code_challenge" $code_challenge "scalar") (serialize-qp "code_challenge_method" $code_challenge_method "scalar") (serialize-qp "response_mode" $response_mode "scalar") (serialize-qp "nonce" $nonce "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request OAuth2 authorization
#
# POST /oauth/authorize
# operationId: requestOAuthAuthorizePOST
export def "oauth-authorize requestOAuthAuthorizePOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  response_type: string@response-type-completer # The authorization flow type. Must be `code` for authorization code flow.
  client_id: string # The OAuth2 client ID of the OAuth application.
  --redirect-uri: string # The URI to redirect to after authorization. Must be registered for the OAuth application. (nullable, format: uri)
  --scope: string # Space-separated list of scopes being requested. Available scopes are `email`, `profile`, `openid`, `public_metadata`, `private_metadata`, and `user:org:read` (when Organizations are enabled). Defaults to `profile email` if not provided. Multiple values should be space-delimited (e.g., "email profile openid"). (nullable)
  --state: string # An opaque value used to maintain state between the request and callback (minimum 8 characters). Required to prevent CSRF attacks unless PKCE parameters (`code_challenge` and `code_challenge_method`) are provided. (nullable)
  --prompt: string # Space-separated list of prompts. Supported values are `none` (no user interaction), `login` (force re-authentication), and `consent` (force consent screen). Multiple values should be space-delimited (e.g., "login consent"). (nullable)
  --code-challenge: string # The code challenge for PKCE (Proof Key for Code Exchange). Required for public clients. (nullable)
  --code-challenge-method: string@code-challenge-method-completer # The method used to generate the code challenge. Must be `S256`. (nullable)
  --response-mode: string@response-mode-completer # The method used to return authorization response parameters. Supported values are `query` (parameters in URL query string) and `form_post` (parameters in POST body). (nullable)
  --nonce: string # String value used to associate a client session with an ID Token and to mitigate replay attacks. Used in OpenID Connect flows. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/authorize")
  let body = {response_type: $response_type, client_id: $client_id, redirect_uri: $redirect_uri, scope: $scope, state: $state, prompt: $prompt, code_challenge: $code_challenge, code_challenge_method: $code_challenge_method, response_mode: $response_mode, nonce: $nonce} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Register OAuth 2.0 Client
#
# POST /oauth/register
# operationId: registerOAuthClient
export def "oauth-register registerOAuthClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  redirect_uris: list # Array of redirection URI strings for use in redirect-based flows such as the authorization code flow. As required by Section 2 of RFC 6749, clients using flows with redirection must register their redirection URI values.
  --token-endpoint-auth-method: string@token-endpoint-auth-method-completer # Indicator of the requested authentication method for the token endpoint. - `client_secret_basic`: HTTP Basic authentication scheme - `client_secret_post`: Client credentials in the request body - `none`: Public client (no authentication)  **Note:** In the current implementation, `client_secret_basic` and `client_secret_post` are treated equivalently. Both methods can be used interchangeably at the token endpoint regardless of which one was specified during registration. (default: client_secret_basic)
  --client-name: string # Human-readable string name of the client to be presented to the end-user during authorization. (nullable)
  --client-uri: string # URL string of a web page providing information about the client. (nullable, format: uri)
  --logo-uri: string # URL string that references a logo for the client. If present, the Clerk will display this image to the end-user during approval. (nullable, format: uri)
  --scope: string # Space-separated list of scope values that the client can use when requesting access tokens. If omitted, the client will be registered with the default set of scopes. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/register")
  let body = {redirect_uris: $redirect_uris, token_endpoint_auth_method: $token_endpoint_auth_method, client_name: $client_name, client_uri: $client_uri, logo_uri: $logo_uri, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get OAuth2 token
#
# POST /oauth/token
# operationId: getOAuthToken
export def "oauth-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  grant_type: string@grant-type-completer # The grant type being used. - `authorization_code`: Exchange an authorization code for tokens - `refresh_token`: Refresh an access token
  --code: string # The authorization code received from the authorization endpoint. **Required when `grant_type=authorization_code`**. (nullable)
  --redirect-uri: string # The redirect URI used in the authorization request. Must match exactly. **Required when `grant_type=authorization_code`**. (nullable)
  --code-verifier: string # The PKCE code verifier that corresponds to the `code_challenge` sent in the authorization request. **Required for public clients using PKCE with `grant_type=authorization_code`**. Confidential clients using `client_secret` should not include this parameter. (nullable)
  --client-id: string # The OAuth 2.0 client identifier. **Required for public clients** (those not using HTTP Basic Authentication). For confidential clients, can be provided here or via HTTP Basic Authentication. (nullable)
  --client-secret: string # The OAuth 2.0 client secret. **Required for confidential clients** (unless using HTTP Basic Authentication). Public clients using PKCE should not include this parameter. (nullable)
  --refresh-token: string # The refresh token issued to the client. **Required when `grant_type=refresh_token`**. (nullable)
  --scope: string # Space-separated list of scopes for the access token. **Optional when `grant_type=refresh_token`**. If provided, the requested scope must not exceed the scope originally granted. If omitted, the same scope as originally granted will be used. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token")
  let body = {grant_type: $grant_type, code: $code, redirect_uri: $redirect_uri, code_verifier: $code_verifier, client_id: $client_id, client_secret: $client_secret, refresh_token: $refresh_token, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get user info after OAuth2 flow
#
# GET /oauth/userinfo
# operationId: getOAuthUserInfo
export def "oauth-userinfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user info after OAuth2 flow
#
# POST /oauth/userinfo
# operationId: getOAuthUserInfoPOST
export def "oauth-userinfo post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information for an access or refresh token
#
# POST /oauth/token_info
# operationId: getOAuthTokenInfo
export def "oauth-token-info post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The value of the access or the refresh token
  --token-type-hint: string # A hint about the type of the token submitted for introspection. Can be one of the following `access_token` and `refresh_token` (nullable)
  --scope: string # The granted scopes for the token to check against (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token_info")
  let body = {token: $body_token, token_type_hint: $token_type_hint, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Revoke OAuth2 token
#
# POST /oauth/token/revoke
# operationId: revokeOAuthToken
export def "oauth-token-revoke revokeOAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The token to revoke.
  --token-type-hint: string@token-type-hint-completer # A hint about the type of the token to be revoked. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token/revoke")
  let body = {token: $body_token, token_type_hint: $token_type_hint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get consent information
#
# GET /v1/me/oauth/consent/{client_id}
# operationId: getOAuthConsent
export def "me-oauth-consent get" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # Optional space-separated list of scopes to restrict the response to only those requested.
  --redirect-uri: string # Optional redirect URI from the original OAuth authorize request. When provided and registered for the OAuth application, the response will include a `redirect_domain` field containing the PSL-resolved root domain for display on the consent screen. Unregistered or malformed URIs are silently ignored and `redirect_domain` will be null.  (format: uri)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/oauth/consent/($client_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit OAuth2 consent decision
#
# POST /v1/me/oauth/consent/{client_id}
# operationId: submitOAuthConsent
export def "me-oauth-consent submitOAuthConsent" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consented: string@bool-completer # The user's consent decision. `true` grants the requested scopes and continues the authorization flow; any other value is treated as a denial and returns an `access_denied` error in the redirect.
  --organization-id: string # Optional. The organization to scope the issued token to. The authenticated user must be a member of this organization. If omitted, the user's currently active organization is used.  (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/oauth/consent/($client_id)")
  let body = {consented: $consented, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get organization creation defaults
#
# GET /v1/me/organization_creation_defaults
# operationId: getOrganizationCreationDefaults
export def "me-organization-creation-defaults get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<response: record<form: record<name: string, logo: string>, advisory: record<type: string, message: string>>, client: record<object: string, id: string, sessions: list<record>, sign_in: record, sign_up: record, last_active_session_id: string, last_authentication_strategy: string, cookie_expires_at: int, captcha_bypass: bool, created_at: int, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/organization_creation_defaults")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account portal
#
# GET /v1/account_portal
# operationId: getAccountPortal
export def "account-portal get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/account_portal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get environment
#
# GET /v1/environment
# operationId: getEnvironment
export def "environment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update environment
#
# PATCH /v1/environment
# operationId: updateEnvironment
export def "environment updateEnvironment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # Origin of the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment")
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# SAML Metadata
#
# GET /v1/saml/metadata/{saml_connection_id}.xml
# operationId: samlMetadata
export def "saml-metadata samlMetadata" [
  saml_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saml/metadata/($saml_connection_id).xml")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# SAML ACS
#
# POST /v1/saml/acs/{saml_connection_id}
# operationId: acs
export def "saml-acs acs" [
  saml_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saml/acs/($saml_connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Health
#
# GET /v1/health
# operationId: getHealth
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Proxy Health
#
# GET /v1/proxy-health
# operationId: getProxyHealth
export def "proxy-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain-id: string # The ID of the domain
  --Clerk-Proxy-Url: string # The URL of the proxy
  --Clerk-Secret-Key: string # The secret key of the proxy
  --X-Forwarded-For: string # The IP address of the client
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain_id" $domain_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/proxy-health" $qp)
  let extra_headers = {"Clerk-Proxy-Url": $Clerk_Proxy_Url, "Clerk-Secret-Key": $Clerk_Secret_Key, "X-Forwarded-For": $X_Forwarded_For} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Current Client
#
# GET /v1/client
# operationId: getClient
export def "client get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create New Client
#
# PUT /v1/client
# operationId: putClient
export def "client put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create New Client
#
# POST /v1/client
# operationId: postClient
export def "client post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Client's Sessions
#
# DELETE /v1/client
# operationId: deleteClientSessions
export def "client delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Sign In or replace the current one.
#
# POST /v1/client/sign_ins
# operationId: createSignIn
export def "client-sign-ins createSignIn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  --strategy: string # Strategy used to sign in. Can be one of `phone_code`, `email_code`, `ticket`, `web3_[provider]_signature` `reset_password_code`, `reset_password_phone_code`, `email_link`, `oauth_[provider]`, `oauth_token_[provider]`, `saml`, `password`, `passkey`, `google_one_tap` (nullable)
  --identifier: string # The unique identifier of the user. This changes depending on the strategy. (nullable)
  --password: string # The password of the user. Only used with password strategy. (nullable)
  --ticket: string # Ticket to be used for signing in. (nullable)
  --redirect-url: string # nullable
  --action-complete-redirect-url: string # nullable
  --transfer: string@bool-completer # nullable
  --code: string # The authorization or grant code for an OAuth exchange. Only used with `oauth_token_[provider]` strategies. (nullable)
  --body-token: string # The ID token from an OpenID Connect flow. Only used with `oauth_token_[provider]` and `google_one_tap` strategies. (nullable)
  --oidc-login-hint: string # Used with `oauth_[provider]`. The given value will be forwarded to the OIDC `login_hint` parameter of the generated redirect URL. (nullable)
  --oidc-prompt: string # Used with `oauth_[provider]` or `enterprise_sso`. The given value will be forwarded to the OIDC `prompt` parameter of the generated redirect URL. When using shared credentials, this value might be adjusted for security reasons. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client/sign_ins")
  let body = {strategy: $strategy, identifier: $identifier, password: $password, ticket: $ticket, redirect_url: $redirect_url, action_complete_redirect_url: $action_complete_redirect_url, transfer: $transfer, code: $code, token: $body_token, oidc_login_hint: $oidc_login_hint, oidc_prompt: $oidc_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve sign-in
#
# GET /v1/client/sign_ins/{sign_in_id}
# operationId: getSignIn
export def "client-sign-ins get" [
  sign_in_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ins/($sign_in_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset password on sign-in
#
# POST /v1/client/sign_ins/{sign_in_id}/reset_password
# operationId: resetPassword
export def "client-sign-ins-reset-password resetPassword" [
  sign_in_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string
  --sign-out-of-other-sessions: string@bool-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ins/($sign_in_id)/reset_password")
  let body = {password: $password, sign_out_of_other_sessions: $sign_out_of_other_sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Prepare First Factor Verification
#
# POST /v1/client/sign_ins/{sign_in_id}/prepare_first_factor
# operationId: prepareSignInFactorOne
export def "client-sign-ins-prepare-first-factor prepareSignInFactorOne" [
  sign_in_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  strategy: string # The strategy to be prepared for first factor authentication.  Can be one of the following `email_code`, `email_link`, `phone_code`, `web3_metamask_signature`, `web3_base_signature`, `web3_coinbase_wallet_signature`, `web3_okx_wallet_signature`, `reset_password_phone_code`, `reset_password_email_code`, `oauth_[provider]`, `saml`, `passkey`, `enterprise_sso`
  --email-address-id: string # Used with the `email_code`, `reset_password_email_code` and `email_link` strategies. (nullable)
  --phone-number-id: string # Used with the `phone_code` and `reset_password_phone_code` strategies. (nullable)
  --web3-wallet-id: string # Used with the `web3_metamask_signature`, `web3_base_signature`, `web3_coinbase_wallet_signature` and `web3_okx_wallet_signature` strategies. (nullable)
  --passkey-id: string # Used with the `passkey` strategy. (nullable)
  --redirect-url: string # Used with `email_link`, `oauth_[provider]`, and `saml` strategies. (nullable)
  --action-complete-redirect-url: string # Used with `oauth_[provider]` and `saml` strategies. (nullable)
  --oidc-login-hint: string # Used with `oauth_[provider]`. The given value will be forwarded to the OIDC `login_hint` parameter of the generated redirect URL. (nullable)
  --oidc-prompt: string # Used with `oauth_[provider]` or `enterprise_sso`. The given value will be forwarded to the OIDC `prompt` parameter of the generated redirect URL. When using shared credentials this value might be adjusted for security reasons. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ins/($sign_in_id)/prepare_first_factor")
  let body = {strategy: $strategy, email_address_id: $email_address_id, phone_number_id: $phone_number_id, web3_wallet_id: $web3_wallet_id, passkey_id: $passkey_id, redirect_url: $redirect_url, action_complete_redirect_url: $action_complete_redirect_url, oidc_login_hint: $oidc_login_hint, oidc_prompt: $oidc_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt First Factor Verification
#
# POST /v1/client/sign_ins/{sign_in_id}/attempt_first_factor
# operationId: attemptSignInFactorOne
@deprecated --flag ticket
export def "client-sign-ins-attempt-first-factor attemptSignInFactorOne" [
  sign_in_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  strategy: string # The strategy to be used for first factor authentication.  Can be one of the following `email_code`, `email_link`, `password`, `phone_code`, `web3_metamask_signature`, `web3_base_signature`, `web3_coinbase_wallet_signature`, `web3_okx_wallet_signature`, `reset_password_phone_code`, `reset_password_email_code`, `passkey`, `google_one_tap`
  --code: string # The code that was sent to the email. Used with the `email_code`, `phone_code`, and `email_link` strategies. (nullable)
  --password: string # Used with the `password` and `reset_password_phone_code` strategies. (nullable)
  --signature: string # Used with the `web3_metamask_signature`, `web3_base_signature`, `web3_coinbase_wallet_signature` and `web3_okx_wallet_signature` strategies. (nullable)
  --body-token: string # The ID token from an OpenID Connect flow. Only used with `oauth_token_[provider]` and `google_one_tap` strategies. (nullable)
  --ticket: string # DEPRECATED, nullable
  --public-key-credential: string # Used with the `passkey` strategy. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ins/($sign_in_id)/attempt_first_factor")
  let body = {strategy: $strategy, code: $code, password: $password, signature: $signature, token: $body_token, ticket: $ticket, public_key_credential: $public_key_credential} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Prepare Second Factor Verification
#
# POST /v1/client/sign_ins/{sign_in_id}/prepare_second_factor
# operationId: prepareSignInFactorTwo
export def "client-sign-ins-prepare-second-factor prepareSignInFactorTwo" [
  sign_in_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strategy: string@strategy-completer # The strategy to be prepared for second factor authentication. (nullable)
  --phone-number-id: string # Used with the `phone_code` strategy. (nullable)
  --email-address-id: string # Used with the `email_code` and `email_link` strategies. (nullable)
  --redirect-url: string # Used with the `email_link` strategy. The redirect URL after email link verification. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ins/($sign_in_id)/prepare_second_factor")
  let body = {strategy: $strategy, phone_number_id: $phone_number_id, email_address_id: $email_address_id, redirect_url: $redirect_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt Second Factor Verification
#
# POST /v1/client/sign_ins/{sign_in_id}/attempt_second_factor
# operationId: attemptSignInFactorTwo
export def "client-sign-ins-attempt-second-factor attemptSignInFactorTwo" [
  sign_in_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strategy: string@strategy-completer-1 # The strategy to be attempted for second factor authentication.
  --code: string # Used with the `phone_code`, `totp` and `backup_code` strategies.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ins/($sign_in_id)/attempt_second_factor")
  let body = {strategy: $strategy, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Sign-up
#
# POST /v1/client/sign_ups
# operationId: createSignUps
export def "client-sign-ups createSignUps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  --transfer: string@bool-completer # nullable
  --password: string # nullable
  --first-name: string # nullable
  --last-name: string # nullable
  --username: string # nullable
  --email-address: string # nullable
  --phone-number: string # nullable
  --email-address-or-phone-number: string # nullable
  --unsafe-metadata: string # nullable
  --strategy: string # Strategy used to sign up. Can be one of `email_code`, `email_link`, `enterprise_sso`, `google_one_tap`, `oauth_[provider]`, `oauth_token_[provider]`, `phone_code`, `saml`, `ticket`, `web3_[provider]_signature` (nullable)
  --action-complete-redirect-url: string # nullable
  --redirect-url: string # nullable
  --ticket: string # nullable
  --web3-wallet: string # nullable
  --body-token: string # The ID token from an OpenID Connect flow. Only used with `oauth_token_[provider]` and `google_one_tap` strategies. (nullable)
  --code: string # The authorization or grant code for an OAuth exchange. Only used with `oauth_token_[provider]` strategies. (nullable)
  --captcha-token: string # nullable
  --captcha-error: string # nullable
  --captcha-widget-type: string # nullable
  --legal-accepted: string@bool-completer # Has the value `true` if the user has accepted the legal requirements. (nullable)
  --oidc-login-hint: string # Used with `oauth_[provider]`. The given value will be forwarded to the OIDC `login_hint` parameter of the generated redirect URL. (nullable)
  --oidc-prompt: string # Used with `oauth_[provider]` or `enterprise_sso`. The given value will be forwarded to the OIDC `prompt` parameter of the generated redirect URL. When using shared credentials this value might be adjusted for security reasons. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client/sign_ups")
  let body = {transfer: $transfer, password: $password, first_name: $first_name, last_name: $last_name, username: $username, email_address: $email_address, phone_number: $phone_number, email_address_or_phone_number: $email_address_or_phone_number, unsafe_metadata: $unsafe_metadata, strategy: $strategy, action_complete_redirect_url: $action_complete_redirect_url, redirect_url: $redirect_url, ticket: $ticket, web3_wallet: $web3_wallet, token: $body_token, code: $code, captcha_token: $captcha_token, captcha_error: $captcha_error, captcha_widget_type: $captcha_widget_type, legal_accepted: $legal_accepted, oidc_login_hint: $oidc_login_hint, oidc_prompt: $oidc_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Sign-up
#
# GET /v1/client/sign_ups/{sign_up_id}
# operationId: getSignUps
export def "client-sign-ups get" [
  sign_up_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ups/($sign_up_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Sign-up
#
# PATCH /v1/client/sign_ups/{sign_up_id}
# operationId: updateSignUps
export def "client-sign-ups updateSignUps" [
  sign_up_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  --password: string # nullable
  --first-name: string # nullable
  --last-name: string # nullable
  --username: string # nullable
  --email-address: string # nullable
  --phone-number: string # nullable
  --email-address-or-phone-number: string # nullable
  --unsafe-metadata: string # nullable
  --strategy: string # Strategy used to sign up. Can be one of `email_code`, `email_link`, `enterprise_sso`, `google_one_tap`, `oauth_[provider]`, `oauth_token_[provider]`, `phone_code`, `saml`, `ticket`, `web3_[provider]_signature` (nullable)
  --redirect-url: string # nullable
  --action-complete-redirect-url: string # nullable
  --ticket: string # nullable
  --web3-wallet: string # nullable
  --body-token: string # The ID token from an OpenID Connect flow. Only used with `oauth_token_[provider]` and `google_one_tap` strategies. (nullable)
  --code: string # The authorization or grant code for an OAuth exchange. Only used with `oauth_token_[provider]` strategies. (nullable)
  --legal-accepted: string@bool-completer # Has the value `true` if the user has accepted the legal requirements.  (nullable)
  --oidc-login-hint: string # Used with `oauth_[provider]`. The given value will be forwarded to the OIDC `login_hint` parameter of the generated redirect URL. (nullable)
  --oidc-prompt: string # Used with `oauth_[provider]` or `enterprise_sso`. The given value will be forwarded to the OIDC `prompt` parameter of the generated redirect URL. When using shared credentials this value might be adjusted for security reasons. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ups/($sign_up_id)")
  let body = {password: $password, first_name: $first_name, last_name: $last_name, username: $username, email_address: $email_address, phone_number: $phone_number, email_address_or_phone_number: $email_address_or_phone_number, unsafe_metadata: $unsafe_metadata, strategy: $strategy, redirect_url: $redirect_url, action_complete_redirect_url: $action_complete_redirect_url, ticket: $ticket, web3_wallet: $web3_wallet, token: $body_token, code: $code, legal_accepted: $legal_accepted, oidc_login_hint: $oidc_login_hint, oidc_prompt: $oidc_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Prepare Sign-up Identification Verification
#
# POST /v1/client/sign_ups/{sign_up_id}/prepare_verification
# operationId: prepareSignUpsVerification
export def "client-sign-ups-prepare-verification prepareSignUpsVerification" [
  sign_up_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  --strategy: string # The verification strategy  - email_code - email_link - phone_code - web3_metamask_signature - web3_base_signature - web3_coinbase_wallet_signature - web3_okx_wallet_signature - saml - oauth
  --redirect-url: string # nullable
  --action-complete-redirect-url: string # nullable
  --oidc-login-hint: string # Used with `oauth_[provider]`. The given value will be forwarded to the OIDC `login_hint` parameter of the generated redirect URL. (nullable)
  --oidc-prompt: string # Used with `oauth_[provider]` or `enterprise_sso`. The given value will be forwarded to the OIDC `prompt` parameter of the generated redirect URL. When using shared credentials this value might be adjusted for security reasons. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ups/($sign_up_id)/prepare_verification")
  let body = {strategy: $strategy, redirect_url: $redirect_url, action_complete_redirect_url: $action_complete_redirect_url, oidc_login_hint: $oidc_login_hint, oidc_prompt: $oidc_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt Sign-up Identification Verification
#
# POST /v1/client/sign_ups/{sign_up_id}/attempt_verification
# operationId: attemptSignUpsVerification
export def "client-sign-ups-attempt-verification attemptSignUpsVerification" [
  sign_up_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  --strategy: string@strategy-completer-2 # The verification strategy
  --code: string # The verification code (nullable)
  --signature: string # The verification web3 signature (nullable)
  --body-token: string # The ID token from an OpenID Connect flow. Only used with `oauth_token_[provider]` and `google_one_tap` strategies. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sign_ups/($sign_up_id)/attempt_verification")
  let body = {strategy: $strategy, code: $code, signature: $signature, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Sync clients across multiple domains
#
# GET /v1/client/sync
# operationId: syncClient
export def "client-sync syncClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --link-domain: string # The satellite domain which should be synced with its primary.
  --redirect-url: string # The URL to redirect to after the syncing process has been completed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "link_domain" $link_domain "scalar") (serialize-qp "redirect_url" $redirect_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/client/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link clients across multiple domains
#
# GET /v1/client/link
# operationId: linkClient
export def "client-link linkClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-token: string # The token generated from a sync request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "__clerk_token" $clerk_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/client/link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate and return a new session token for a given client.
#
# GET /v1/client/handshake
# operationId: handshakeClient
export def "client-handshake handshakeClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --redirect-url: string # The URL to redirect back to after the handshake
  --format: string@format-completer # The supported format of the handshake payload. (default: token)
  --organization-id: string # The organization ID or slug to attempt to set as active for the session. If this param is present but has no value, the personal account will be set as active. If the organization cannot be set as active (because it does not exist, or the user is not a member), the active organization for the session will not change.  (allows empty value)
  --satellite-fapi: string # The Frontend API of the satellite domain
  --Clerk-Proxy-Url: string # The URL of the proxy
  --Clerk-Secret-Key: string # The secret key of the proxy
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect_url" $redirect_url "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "satellite_fapi" $satellite_fapi "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/client/handshake" $qp)
  let extra_headers = {"Clerk-Proxy-Url": $Clerk_Proxy_Url, "Clerk-Secret-Key": $Clerk_Secret_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create session from agent task
#
# GET /v1/agents/tasks
# operationId: createAgentTask
export def "agents-tasks createAgentTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ticket: string # The agent task ticket value obtained from the Backend API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ticket" $ticket "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/agents/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Dev Browser token
#
# POST /v1/dev_browser
# operationId: createDevBrowser
export def "dev-browser createDevBrowser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dev_browser")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post Dev Browser init set cookie
#
# POST /v1/dev_browser/set_first_party_cookie
# operationId: postDevBrowserInitSetCookie
export def "dev-browser-set-first-party-cookie post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dev_browser/set_first_party_cookie")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initialize dev browser for development and staging instances
#
# GET /v1/dev_browser/init
# operationId: getDevBrowserInit
export def "dev-browser-init get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --origin: string # The origin of the request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "origin" $origin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dev_browser/init" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth Callback
#
# GET /v1/oauth_callback
# operationId: getOauthCallback
export def "oauth-callback get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # returned scopes from OAuth provider.
  --code: string # returned exchange code from OAuth provider.
  --state: string # returned state from OAuth provider.
  --qp-error: string # returned error state from OAuth provider, if applicable
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "error" $qp_error "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/oauth_callback" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth Post Callback
#
# POST /v1/oauth_callback
# operationId: postOauthCallback
export def "oauth-callback post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # returned exchange code from OAuth provider.
  --scope: string # returned scopes from OAuth provider. (nullable)
  --state: string # returned state from OAuth provider.
  --body-error: string # returned error state from OAuth provider, if applicable (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth_callback")
  let body = {code: $code, scope: $scope, state: $state, error: $body_error} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set the Clear-Site-Data header
#
# GET /v1/clear-site-data
# operationId: clearSiteData
export def "clear-site-data clearSiteData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/clear-site-data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove client's sessions
#
# DELETE /v1/client/sessions
# operationId: removeClientSessionsAndRetainCookie
export def "client-sessions removeClientSessionsAndRetainCookie" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Session
#
# GET /v1/client/sessions/{session_id}
# operationId: getSession
export def "client-sessions get" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Touch session
#
# POST /v1/client/sessions/{session_id}/touch
# operationId: touchSession
export def "client-sessions-touch touchSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active-organization-id: string # The ID or slug of the organization to activate.  When force organization selection is enabled and this value is sent as null or empty string, the session will keep the previous active organization and will not attempt to switch to a personal account. (nullable)
  --intent: string@intent-completer # Indicates why the touch request was triggered. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/touch")
  let body = {active_organization_id: $active_organization_id, intent: $intent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# End Session
#
# POST /v1/client/sessions/{session_id}/end
# operationId: endSession
export def "client-sessions-end endSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/end")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Session
#
# POST /v1/client/sessions/{session_id}/remove
# operationId: removeSession
export def "client-sessions-remove removeSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/remove")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Active Sessions
#
# GET /v1/me/sessions/active
# operationId: getSessions
export def "me-sessions-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/sessions/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke given session
#
# POST /v1/me/sessions/{session_id}/revoke
# operationId: revokeSession
export def "me-sessions-revoke revokeSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/sessions/($session_id)/revoke" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Session Token
#
# POST /v1/client/sessions/{session_id}/tokens
# operationId: createSessionToken
export def "client-sessions-tokens createSessionToken" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-id: string # The organization ID to associate with the token. The user must be a member of the organization. If present but empty, the personal account will be set as active. If absent, the previous active organization for the session will be used.  When force organization selection is enabled and this value is sent as null or empty string, the token will be created with the previous active organization and will not attempt to switch to a personal account. (nullable)
]: any -> record<jwt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/tokens")
  let body = {organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Session Token With JWT Template
#
# POST /v1/client/sessions/{session_id}/tokens/{template_name}
# operationId: createSessionTokenWithTemplate
export def "client-sessions-tokens createSessionTokenWithTemplate" [
  session_id: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jwt: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/tokens/($template_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a new session reverification
#
# POST /v1/client/sessions/{session_id}/verify
# operationId: startSessionReverification
export def "client-sessions-verify startSessionReverification" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  level: string@level-completer # The level of authentication that the user needs to go through
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/verify")
  let body = {level: $level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Prepare session reverification first factor
#
# POST /v1/client/sessions/{session_id}/verify/prepare_first_factor
# operationId: prepareSessionReverificationFirstFactor
export def "client-sessions-verify-prepare-first-factor prepareSessionReverificationFirstFactor" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  --strategy: string@strategy-completer-3 # The strategy to be prepared for first factor authentication.
  --email-address-id: string # Used with the `email_code` strategy. (nullable)
  --phone-number-id: string # Used with the `phone_code` strategy. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/verify/prepare_first_factor")
  let body = {strategy: $strategy, email_address_id: $email_address_id, phone_number_id: $phone_number_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt session reverification first factor
#
# POST /v1/client/sessions/{session_id}/verify/attempt_first_factor
# operationId: attemptSessionReverificationFirstFactor
export def "client-sessions-verify-attempt-first-factor attemptSessionReverificationFirstFactor" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request
  strategy: string@strategy-completer-4 # The strategy to be used for first factor authentication.
  --code: string # The code that was sent to the email. Used with the `email_code` and `phone_code` strategies. (nullable)
  --password: string # Used with the `password` strategy. (nullable)
  --public-key-credential: string # Used with the `passkey` strategy. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/verify/attempt_first_factor")
  let body = {strategy: $strategy, code: $code, password: $password, public_key_credential: $public_key_credential} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Prepare session reverification second factor
#
# POST /v1/client/sessions/{session_id}/verify/prepare_second_factor
# operationId: prepareSessionReverificationSecondFactor
export def "client-sessions-verify-prepare-second-factor prepareSessionReverificationSecondFactor" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strategy: string@strategy-completer-5 # The strategy to be prepared for second factor authentication. (nullable)
  --phone-number-id: string # Used with the `phone_code` strategy. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/verify/prepare_second_factor")
  let body = {strategy: $strategy, phone_number_id: $phone_number_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt session reverification second factor
#
# POST /v1/client/sessions/{session_id}/verify/attempt_second_factor
# operationId: attemptSessionReverificationSecondFactor
export def "client-sessions-verify-attempt-second-factor attemptSessionReverificationSecondFactor" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strategy: string@strategy-completer-6 # The strategy to be attempted for second factor authentication.
  --code: string # Used with the `phone_code`, `totp` and `backup_code` strategies.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client/sessions/($session_id)/verify/attempt_second_factor")
  let body = {strategy: $strategy, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Sessions
#
# GET /v1/me/sessions
# operationId: getUsersSessions
export def "me-sessions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Email Addresses
#
# GET /v1/me/email_addresses
# operationId: getEmailAddresses
export def "me-email-addresses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/email_addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Email Address
#
# POST /v1/me/email_addresses
# operationId: createEmailAddresses
export def "me-email-addresses createEmailAddresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  email_address: string # The email address to be added to the user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/email_addresses" $qp)
  let body = {email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt Email Address Verification
#
# POST /v1/me/email_addresses/{email_id}/attempt_verification
# operationId: verifyEmailAddress
export def "me-email-addresses-attempt-verification verifyEmailAddress" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  code: string # The code that was previously sent to the email address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/email_addresses/($email_id)/attempt_verification" $qp)
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Prepare Email Address Verification
#
# POST /v1/me/email_addresses/{email_id}/prepare_verification
# operationId: sendVerificationEmail
export def "me-email-addresses-prepare-verification sendVerificationEmail" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  strategy: string@strategy-completer-7 # The strategy to be prepared for email verification.
  --redirect-url: string # Used with the `email_link` strategy. (nullable)
  --action-complete-redirect-url: string # Used with `oauth_[provider]` and `saml` strategies. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/email_addresses/($email_id)/prepare_verification" $qp)
  let body = {strategy: $strategy, redirect_url: $redirect_url, action_complete_redirect_url: $action_complete_redirect_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Email Address
#
# GET /v1/me/email_addresses/{email_id}
# operationId: getEmailAddress
export def "me-email-addresses get" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/email_addresses/($email_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete email address
#
# DELETE /v1/me/email_addresses/{email_id}
# operationId: DeleteEmailAddress
export def "me-email-addresses DeleteEmailAddress" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/email_addresses/($email_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Phone Numbers
#
# GET /v1/me/phone_numbers
# operationId: getPhoneNumbers
export def "me-phone-numbers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/phone_numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Phone Number
#
# POST /v1/me/phone_numbers
# operationId: postPhoneNumbers
export def "me-phone-numbers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  phone_number: string # The phone number to be added to the user.
  --reserved-for-second-factor: string@bool-completer # Whether the phone number is reserved for multi-factor authentication. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/phone_numbers" $qp)
  let body = {phone_number: $phone_number, reserved_for_second_factor: $reserved_for_second_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt Phone Number Verification
#
# POST /v1/me/phone_numbers/{phone_number_id}/attempt_verification
# operationId: verifyPhoneNumber
export def "me-phone-numbers-attempt-verification verifyPhoneNumber" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  code: string # Strategy used to verify the phone number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/phone_numbers/($phone_number_id)/attempt_verification" $qp)
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Prepare Phone Number Verification
#
# POST /v1/me/phone_numbers/{phone_number_id}/prepare_verification
# operationId: sendVerificationSMS
export def "me-phone-numbers-prepare-verification sendVerificationSMS" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  strategy: string@strategy-completer-5 # Strategy used to verify the phone number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/phone_numbers/($phone_number_id)/prepare_verification" $qp)
  let body = {strategy: $strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve Phone Number
#
# GET /v1/me/phone_numbers/{phone_number_id}
# operationId: ReadPhoneNumber
export def "me-phone-numbers ReadPhoneNumber" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/phone_numbers/($phone_number_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Phone Number
#
# PATCH /v1/me/phone_numbers/{phone_number_id}
# operationId: UpdatePhoneNumber
export def "me-phone-numbers UpdatePhoneNumber" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  --reserved-for-second-factor: string@bool-completer # Whether the phone number is reserved for multi-factor authentication. (nullable)
  --default-second-factor: string@bool-completer # Marks the phone number as the default that will be used in multi-factor authentication. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/phone_numbers/($phone_number_id)" $qp)
  let body = {reserved_for_second_factor: $reserved_for_second_factor, default_second_factor: $default_second_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete Phone Number
#
# DELETE /v1/me/phone_numbers/{phone_number_id}
# operationId: DeletePhoneNumber
export def "me-phone-numbers DeletePhoneNumber" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/phone_numbers/($phone_number_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Web3 Wallets
#
# GET /v1/me/web3_wallets
# operationId: getWeb3Wallets
export def "me-web3-wallets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/web3_wallets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Web3 Wallet
#
# POST /v1/me/web3_wallets
# operationId: postWeb3Wallets
export def "me-web3-wallets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  web3_wallet: string # The web3 wallet to be added to the user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/web3_wallets" $qp)
  let body = {web3_wallet: $web3_wallet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Web3 Wallet
#
# GET /v1/me/web3_wallets/{web3_wallet_id}
# operationId: readWeb3Wallet
export def "me-web3-wallets readWeb3Wallet" [
  web3_wallet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/web3_wallets/($web3_wallet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Web3 Wallet
#
# DELETE /v1/me/web3_wallets/{web3_wallet_id}
# operationId: deleteWeb3Wallet
export def "me-web3-wallets delete" [
  web3_wallet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/web3_wallets/($web3_wallet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Prepare Web3 Wallet Verification
#
# POST /v1/me/web3_wallets/{web3_wallet_id}/prepare_verification
# operationId: prepareWeb3WalletVerification
export def "me-web3-wallets-prepare-verification prepareWeb3WalletVerification" [
  web3_wallet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request.
  strategy: string # The strategy used to verify the web3 wallet.
  --redirect-url: string # The redirect URL to redirect the user to after verification. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/web3_wallets/($web3_wallet_id)/prepare_verification")
  let body = {strategy: $strategy, redirect_url: $redirect_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt Web3 Wallet Verification
#
# POST /v1/me/web3_wallets/{web3_wallet_id}/attempt_verification
# operationId: attemptWeb3WalletVerification
export def "me-web3-wallets-attempt-verification attemptWeb3WalletVerification" [
  web3_wallet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request.
  signature: string # The signature that was generated from your Web3 Wallet to sign the message
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/web3_wallets/($web3_wallet_id)/attempt_verification")
  let body = {signature: $signature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Passkey
#
# POST /v1/me/passkeys
# operationId: postPasskey
export def "me-passkeys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  --Origin: string # The origin of the request.
  --X-Original-Host: string # The original host of the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/passkeys" $qp)
  let extra_headers = {"Origin": $Origin, "X-Original-Host": $X_Original_Host} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Passkey
#
# GET /v1/me/passkeys/{passkey_id}
# operationId: readPasskey
export def "me-passkeys readPasskey" [
  passkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/passkeys/($passkey_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Passkey
#
# PATCH /v1/me/passkeys/{passkey_id}
# operationId: patchPasskey
export def "me-passkeys patch" [
  passkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the passkey. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/passkeys/($passkey_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete Passkey
#
# DELETE /v1/me/passkeys/{passkey_id}
# operationId: deletePasskey
export def "me-passkeys delete" [
  passkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/passkeys/($passkey_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attempt Passkey Verification
#
# POST /v1/me/passkeys/{passkey_id}/attempt_verification
# operationId: attemptPasskeyVerification
export def "me-passkeys-attempt-verification attemptPasskeyVerification" [
  passkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request.
  --strategy: string@strategy-completer-8 # The strategy used to connect the external account. (nullable)
  --public-key-credential: string # The public key credential of the passkey. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/passkeys/($passkey_id)/attempt_verification")
  let body = {strategy: $strategy, public_key_credential: $public_key_credential} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Connect OAuth Accounts
#
# POST /v1/me/external_accounts
# operationId: postOAuthAccounts
export def "me-external-accounts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Origin: string # The origin of the request.
  --strategy: string # The OAuth strategy that the external account provider supports. Optional when `enterprise_connection_id` is provided. Can be one of `oauth_[provider]` or `oauth_token_[provider]`. The `oauth_[provider]` strategy can be used for regular OAuth flows with redirects and a `redirect_url` parameter is also required. The `oauth_token_[provider]` strategy can be used for native flows, along with a `token` or `code` parameter.
  --enterprise-connection-id: string # The ID of an enterprise connection to link. When provided, strategy is not required. (nullable)
  --redirect-url: string # nullable
  --action-complete-redirect-url: string # nullable
  --additional-scope: string # nullable
  --code: string # The authorization or grant code that an OAuth provider returns during authentication. Can be used with `oauth_token_[provider]` strategies. (nullable)
  --body-token: string # The ID token that an OpenID Connect provider returns during authentication. Can be used with `oauth_token_[provider]` strategies. (nullable)
  --oidc-login-hint: string # Used with `oauth_[provider]`. The given value will be forwarded to the OIDC `login_hint` parameter of the generated redirect URL. (nullable)
  --oidc-prompt: string # Used with `oauth_[provider]` or `enterprise_sso`. The given value will be forwarded to the OIDC `prompt` parameter of the generated redirect URL. When using shared credentials this value might be adjusted for security reasons. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/external_accounts")
  let body = {strategy: $strategy, enterprise_connection_id: $enterprise_connection_id, redirect_url: $redirect_url, action_complete_redirect_url: $action_complete_redirect_url, additional_scope: $additional_scope, code: $code, token: $body_token, oidc_login_hint: $oidc_login_hint, oidc_prompt: $oidc_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Reauthorize External Account
#
# PATCH /v1/me/external_accounts/{external_account_id}/reauthorize
# operationId: reauthorizeExternalAccount
export def "me-external-accounts-reauthorize reauthorizeExternalAccount" [
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-scope: list # nullable
  redirect_url: string
  --action-complete-redirect-url: string # nullable
  --oidc-login-hint: string # Used with `oauth_[provider]`. The given value will be forwarded to the OIDC `login_hint` parameter of the generated redirect URL. (nullable)
  --oidc-prompt: string # Used with `oauth_[provider]` or `enterprise_sso`. The given value will be forwarded to the OIDC `prompt` parameter of the generated redirect URL. When using shared credentials this value might be adjusted for security reasons. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/external_accounts/($external_account_id)/reauthorize")
  let body = {additional_scope: $additional_scope, redirect_url: $redirect_url, action_complete_redirect_url: $action_complete_redirect_url, oidc_login_hint: $oidc_login_hint, oidc_prompt: $oidc_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete External Account
#
# DELETE /v1/me/external_accounts/{external_account_id}
# operationId: deleteExternalAccount
export def "me-external-accounts delete" [
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/external_accounts/($external_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke OAuth tokens
#
# DELETE /v1/me/external_accounts/{external_account_id}/tokens
# operationId: revokeExternalAccountTokens
export def "me-external-accounts-tokens revokeExternalAccountTokens" [
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/external_accounts/($external_account_id)/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create TOTP
#
# POST /v1/me/totp
# operationId: postTOTP
export def "me-totp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/totp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete TOTP
#
# DELETE /v1/me/totp
# operationId: deleteTOTP
export def "me-totp delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/totp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attempt TOTP Verification
#
# POST /v1/me/totp/attempt_verification
# operationId: verifyTOTP
export def "me-totp-attempt-verification verifyTOTP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/totp/attempt_verification")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create Backup Codes
#
# POST /v1/me/backup_codes
# operationId: createBackupCodes
export def "me-backup-codes createBackupCodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/backup_codes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User
#
# GET /v1/me
# operationId: getUser
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User
#
# PATCH /v1/me
# operationId: patchUser
export def "me patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # nullable
  --first-name: string # nullable
  --last-name: string # nullable
  --primary-email-address-id: string # nullable
  --primary-phone-number-id: string # nullable
  --primary-web3-wallet-id: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let body = {username: $username, first_name: $first_name, last_name: $last_name, primary_email_address_id: $primary_email_address_id, primary_phone_number_id: $primary_phone_number_id, primary_web3_wallet_id: $primary_web3_wallet_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete User
#
# DELETE /v1/me
# operationId: deleteUser
export def "me delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge and update the current user's metadata
#
# PATCH /v1/me/metadata
# operationId: patchUserMetadata
export def "me-metadata patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  unsafe_metadata: string # A stringified JSON object containing the unsafe metadata patch to merge into the current user's `unsafe_metadata`. Existing keys are deep-merged; keys at any level with `null` values are removed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/metadata")
  let body = {unsafe_metadata: $unsafe_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a JWT for the requested user.
#
# POST /v1/me/tokens
# operationId: createServiceToken
export def "me-tokens createServiceToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clerk-session-id: string # The session_id associated with the requesting user.
  service: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_clerk_session_id" $clerk_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/tokens" $qp)
  let body = {service: $service} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update Profile Image
#
# POST /v1/me/profile_image
# operationId: updateProfileImage
export def "me-profile-image updateProfileImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/profile_image")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete Profile Image
#
# DELETE /v1/me/profile_image
# operationId: deleteProfileImage
export def "me-profile-image delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/profile_image")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Password
#
# POST /v1/me/change_password
# operationId: changePassword
export def "me-change-password changePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-password: string # nullable
  --new-password: string
  --sign-out-of-other-sessions: string@bool-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/change_password")
  let body = {current_password: $current_password, new_password: $new_password, sign_out_of_other_sessions: $sign_out_of_other_sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete Password
#
# POST /v1/me/remove_password
# operationId: removePassword
export def "me-remove-password removePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current-password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/remove_password")
  let body = {current_password: $current_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get user's main billing subscription
#
# GET /v1/me/billing/subscription
# operationId: GetUserMainBillingSubscription
export def "me-billing-subscription GetUserMainBillingSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/billing/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user's subscription items
#
# GET /v1/me/billing/subscription_items
# operationId: GetUserBillingSubscriptionItems
export def "me-billing-subscription-items GetUserBillingSubscriptionItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --paginated: string@bool-completer # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "paginated" $paginated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/billing/subscription_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel user's subscription item
#
# DELETE /v1/me/billing/subscription_items/{subscriptionItemID}
# operationId: DeleteUserBillingSubscriptionItem
export def "me-billing-subscription-items DeleteUserBillingSubscriptionItem" [
  subscriptionItemID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/billing/subscription_items/($subscriptionItemID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user payment methods
#
# GET /v1/me/billing/payment_methods
# operationId: GetUserPaymentMethods
export def "me-billing-payment-methods GetUserPaymentMethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --paginated: string@bool-completer # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "paginated" $paginated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/billing/payment_methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create user payment method
#
# POST /v1/me/billing/payment_methods
# operationId: CreateUserPaymentMethod
export def "me-billing-payment-methods CreateUserPaymentMethod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  gateway: string # Payment gateway to use
  --payment-token: string # Payment token for the method (nullable)
  --org-id: string # Organization ID (optional) (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/billing/payment_methods")
  let body = {gateway: $gateway, payment_token: $payment_token, org_id: $org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Initialize user payment method
#
# POST /v1/me/billing/payment_methods/initialize
# operationId: InitializeUserPaymentMethod
export def "me-billing-payment-methods-initialize InitializeUserPaymentMethod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/billing/payment_methods/initialize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user payment method
#
# DELETE /v1/me/billing/payment_methods/{paymentMethodID}
# operationId: DeleteUserPaymentMethod
export def "me-billing-payment-methods DeleteUserPaymentMethod" [
  paymentMethodID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/billing/payment_methods/($paymentMethodID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create billing checkout
#
# POST /v1/me/billing/checkouts
# operationId: CreateUserBillingCheckout
export def "me-billing-checkouts CreateUserBillingCheckout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  plan_id: string # The ID of the plan to checkout
  plan_period: string@plan-period-completer # The billing period for the plan (default: month)
  --org-id: string # Organization ID (if creating org checkout) (nullable)
  --payment-method-id: string # Payment method ID to use (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/billing/checkouts")
  let body = {plan_id: $plan_id, plan_period: $plan_period, org_id: $org_id, payment_method_id: $payment_method_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get billing checkout
#
# GET /v1/me/billing/checkouts/{checkoutID}
# operationId: GetUserBillingCheckout
export def "me-billing-checkouts GetUserBillingCheckout" [
  checkoutID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/billing/checkouts/($checkoutID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirm billing checkout
#
# PATCH /v1/me/billing/checkouts/{checkoutID}/confirm
# operationId: ConfirmUserBillingCheckout
export def "me-billing-checkouts-confirm ConfirmUserBillingCheckout" [
  checkoutID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment-method-id: string # The ID of the payment method to use for this checkout (nullable)
  --gateway: string # The payment gateway to use (e.g., stripe) (nullable)
  --payment-token: string # A payment token for processing the payment (nullable)
  --use-test-card: string@bool-completer # Whether to use a test card for payment processing (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/billing/checkouts/($checkoutID)/confirm")
  let body = {payment_method_id: $payment_method_id, gateway: $gateway, payment_token: $payment_token, use_test_card: $use_test_card} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List user payment attempts
#
# GET /v1/me/billing/payment_attempts
# operationId: GetUserPaymentAttempts
export def "me-billing-payment-attempts GetUserPaymentAttempts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --paginated: string@bool-completer # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "paginated" $paginated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/billing/payment_attempts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user payment attempt
#
# GET /v1/me/billing/payment_attempts/{paymentAttemptID}
# operationId: GetUserPaymentAttempt
export def "me-billing-payment-attempts GetUserPaymentAttempt" [
  paymentAttemptID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/billing/payment_attempts/($paymentAttemptID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set user default payment method
#
# PUT /v1/me/billing/payers/default_payment_method
# operationId: SetUserDefaultPaymentMethod
export def "me-billing-payers-default-payment-method SetUserDefaultPaymentMethod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me/billing/payers/default_payment_method")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user statements
#
# GET /v1/me/billing/statements
# operationId: GetUserStatements
export def "me-billing-statements GetUserStatements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --paginated: string@bool-completer # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "paginated" $paginated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/billing/statements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user statement
#
# GET /v1/me/billing/statements/{statementID}
# operationId: GetUserStatement
export def "me-billing-statements GetUserStatement" [
  statementID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/billing/statements/($statementID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organization billing checkout
#
# POST /v1/organizations/{organizationID}/billing/checkouts
# operationId: CreateOrganizationBillingCheckout
export def "organizations-billing-checkouts CreateOrganizationBillingCheckout" [
  organizationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  plan_id: string # The ID of the plan to checkout
  plan_period: string@plan-period-completer # The billing period for the plan (default: month)
  --payment-method-id: string # Payment method ID to use (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/checkouts")
  let body = {plan_id: $plan_id, plan_period: $plan_period, payment_method_id: $payment_method_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get organization billing checkout
#
# GET /v1/organizations/{organizationID}/billing/checkouts/{checkoutID}
# operationId: GetOrganizationBillingCheckout
export def "organizations-billing-checkouts GetOrganizationBillingCheckout" [
  organizationID: string
  checkoutID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/checkouts/($checkoutID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirm organization billing checkout
#
# PATCH /v1/organizations/{organizationID}/billing/checkouts/{checkoutID}/confirm
# operationId: ConfirmOrganizationBillingCheckout
export def "organizations-billing-checkouts-confirm ConfirmOrganizationBillingCheckout" [
  organizationID: string
  checkoutID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payment-method-id: string # The ID of the payment method to use for this checkout (nullable)
  --gateway: string # The payment gateway to use (e.g., stripe) (nullable)
  --payment-token: string # A payment token for processing the payment (nullable)
  --use-test-card: string@bool-completer # Whether to use a test card for payment processing (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/checkouts/($checkoutID)/confirm")
  let body = {payment_method_id: $payment_method_id, gateway: $gateway, payment_token: $payment_token, use_test_card: $use_test_card} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List organization payment methods
#
# GET /v1/organizations/{organizationID}/billing/payment_methods
# operationId: GetOrganizationPaymentMethods
export def "organizations-billing-payment-methods GetOrganizationPaymentMethods" [
  organizationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/payment_methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organization payment method
#
# POST /v1/organizations/{organizationID}/billing/payment_methods
# operationId: CreateOrganizationPaymentMethod
export def "organizations-billing-payment-methods CreateOrganizationPaymentMethod" [
  organizationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_token: string # The payment token for the payment method
  gateway: string@gateway-completer # The payment gateway to use
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/payment_methods")
  let body = {payment_token: $payment_token, gateway: $gateway} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initialize organization payment method
#
# POST /v1/organizations/{organizationID}/billing/payment_methods/initialize
# operationId: InitializeOrganizationPaymentMethod
export def "organizations-billing-payment-methods-initialize InitializeOrganizationPaymentMethod" [
  organizationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/payment_methods/initialize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete organization payment method
#
# DELETE /v1/organizations/{organizationID}/billing/payment_methods/{paymentMethodID}
# operationId: DeleteOrganizationPaymentMethod
export def "organizations-billing-payment-methods DeleteOrganizationPaymentMethod" [
  organizationID: string
  paymentMethodID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/payment_methods/($paymentMethodID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization statements
#
# GET /v1/organizations/{organizationID}/billing/statements
# operationId: GetOrganizationStatements
export def "organizations-billing-statements GetOrganizationStatements" [
  organizationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/statements")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization statement
#
# GET /v1/organizations/{organizationID}/billing/statements/{statementID}
# operationId: GetOrganizationStatement
export def "organizations-billing-statements GetOrganizationStatement" [
  organizationID: string
  statementID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/statements/($statementID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set organization default payment method
#
# PUT /v1/organizations/{organizationID}/billing/payers/default_payment_method
# operationId: SetOrganizationDefaultPaymentMethod
export def "organizations-billing-payers-default-payment-method SetOrganizationDefaultPaymentMethod" [
  organizationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  payment_method_id: string # The ID of the payment method to set as default
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/payers/default_payment_method")
  let body = {payment_method_id: $payment_method_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organization's billing subscription
#
# GET /v1/organizations/{organizationID}/billing/subscription
# operationId: GetOrganizationBillingSubscription
export def "organizations-billing-subscription GetOrganizationBillingSubscription" [
  organizationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization's subscription items
#
# GET /v1/organizations/{organizationID}/billing/subscription_items
# operationId: GetOrganizationBillingSubscriptionItems
export def "organizations-billing-subscription-items GetOrganizationBillingSubscriptionItems" [
  organizationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/subscription_items")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel organization's subscription item
#
# DELETE /v1/organizations/{organizationID}/billing/subscription_items/{subscriptionItemID}
# operationId: DeleteOrganizationBillingSubscriptionItem
export def "organizations-billing-subscription-items DeleteOrganizationBillingSubscriptionItem" [
  organizationID: string
  subscriptionItemID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationID)/billing/subscription_items/($subscriptionItemID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List billing plans
#
# GET /v1/billing/plans
# operationId: GetBillingPlanList
export def "billing-plans GetBillingPlanList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --payer-type: string@payer-type-completer # Filter plans by payer type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payer_type" $payer_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/billing/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a billing plan
#
# GET /v1/billing/plans/{planIdOrSlug}
# operationId: GetBillingPlan
export def "billing-plans GetBillingPlan" [
  planIdOrSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/billing/plans/($planIdOrSlug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Organization Memberships
#
# GET /v1/me/organization_memberships
# operationId: getOrganizationMemberships
export def "me-organization-memberships get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --paginated: string@bool-completer # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "paginated" $paginated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/organization_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Organization Membership
#
# DELETE /v1/me/organization_memberships/{organization_id}
# operationId: deleteOrganizationMemberships
export def "me-organization-memberships delete" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/organization_memberships/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Current User's Organization Invitations
#
# GET /v1/me/organization_invitations
# operationId: getUsersOrganizationInvitations
export def "me-organization-invitations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --status: string # The status of the organization invitations to filter by
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/organization_invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept Organization invitation
#
# POST /v1/me/organization_invitations/{invitation_id}/accept
# operationId: acceptOrganizationInvitation
export def "me-organization-invitations-accept acceptOrganizationInvitation" [
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/organization_invitations/($invitation_id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Organization Suggestions
#
# GET /v1/me/organization_suggestions
# operationId: getOrganizationSuggestions
export def "me-organization-suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --status: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/organization_suggestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept Organization Suggestion
#
# POST /v1/me/organization_suggestions/{suggestion_id}/accept
# operationId: acceptOrganizationSuggestion
export def "me-organization-suggestions-accept acceptOrganizationSuggestion" [
  suggestion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/me/organization_suggestions/($suggestion_id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization
#
# POST /v1/organizations
# operationId: createOrganization
export def "organizations createOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The organization name. May not contain URLs or HTML.
  --slug: string # The organization slug (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations")
  let body = {name: $name, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Organization
#
# GET /v1/organizations/{organization_id}
# operationId: getOrganization
export def "organizations get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Organization
#
# PATCH /v1/organizations/{organization_id}
# operationId: updateOrganization
export def "organizations updateOrganization" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The organization name. May not contain URLs or HTML. (nullable)
  --slug: string # The organization slug (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)")
  let body = {name: $name, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete Organization
#
# DELETE /v1/organizations/{organization_id}
# operationId: deleteOrganization
export def "organizations delete" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Organization Logo
#
# PUT /v1/organizations/{organization_id}/logo
# operationId: updateOrganizationLogo
export def "organizations-logo updateOrganizationLogo" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/logo")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete Organization Logo
#
# DELETE /v1/organizations/{organization_id}/logo
# operationId: deleteOrganizationLogo
export def "organizations-logo delete" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/logo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization Invitation
#
# POST /v1/organizations/{organization_id}/invitations
# operationId: createOrganizationInvitations
export def "organizations-invitations createOrganizationInvitations" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address the invitation will be sent to.
  role: string # The role that will be assigned to the user after joining. This can be one of the predefined roles (`org:admin`, `org:basic_member`) or a custom role.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/invitations")
  let body = {email_address: $email_address, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get All Organization Invitations
#
# GET /v1/organizations/{organization_id}/invitations
# operationId: getOrganizationInvitations
export def "organizations-invitations get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --status: string@status-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Create Organization Invitations
#
# POST /v1/organizations/{organization_id}/invitations/bulk
# operationId: bulkCreateOrganizationInvitations
export def "organizations-invitations-bulk bulkCreateOrganizationInvitations" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: list # An array of email addresses the invitations will be sent to.
  role: string # The role that will be assigned to each of the users after joining. This can be one of the predefined roles (`org:admin`, `org:basic_member`) or a custom role.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/invitations/bulk")
  let body = {email_address: $email_address, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get All Pending Organization Invitations
#
# GET /v1/organizations/{organization_id}/invitations/pending
# DEPRECATED
# operationId: getAllPendingOrganizationInvitations
@deprecated
export def "organizations-invitations-pending get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/invitations/pending")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke Pending Organization Invitation
#
# POST /v1/organizations/{organization_id}/invitations/{invitation_id}/revoke
# operationId: revokePendingOrganizationInvitation
export def "organizations-invitations-revoke revokePendingOrganizationInvitation" [
  organization_id: string
  invitation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/invitations/($invitation_id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization Membership
#
# POST /v1/organizations/{organization_id}/memberships
# operationId: CreateOrganizationMembership
export def "organizations-memberships CreateOrganizationMembership" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # The ID of the user to be added as a member. (nullable)
  --role: string # The role that will be assigned to the user after joining. This can be one of the predefined roles (`org:admin`, `org:basic_member`) or a custom role defined. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/memberships")
  let body = {user_id: $user_id, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get All Organization Members
#
# GET /v1/organizations/{organization_id}/memberships
# operationId: ListOrganizationMemberships
export def "organizations-memberships ListOrganizationMemberships" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --paginated: string@bool-completer # Whether to paginate the results. If true, the results will be paginated. If false, the results will not be paginated.
  --qp-query: string # Returns members that match the given query. For possible matches, we check for any of the user's identifier, usernames, user IDs, first and last names. The query value doesn't need to match the exact value you are looking for, it is capable of partial matches as well.
  --role: string # Filter by roles. This can be one of the predefined roles (`org:admin`, `org:basic_member`) or a custom role defined.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "paginated" $paginated "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Organization Membership
#
# PATCH /v1/organizations/{organization_id}/memberships/{user_id}
# operationId: UpdateOrganizationMembership
export def "organizations-memberships UpdateOrganizationMembership" [
  organization_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string # The new role that will be assigned to the member. This can be one of the predefined roles (`org:admin`, `org:basic_member`) or a custom role defined.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/memberships/($user_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove Organization Member
#
# DELETE /v1/organizations/{organization_id}/memberships/{user_id}
# operationId: removeOrganizationMember
export def "organizations-memberships removeOrganizationMember" [
  organization_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/memberships/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization Domain
#
# POST /v1/organizations/{organization_id}/domains
# operationId: CreateOrganizationDomain
export def "organizations-domains CreateOrganizationDomain" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the new domain
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/domains")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get All Organization Domains
#
# GET /v1/organizations/{organization_id}/domains
# operationId: ListOrganizationDomains
export def "organizations-domains ListOrganizationDomains" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --verified: string@bool-completer # Filter by whether a domain is verified
  --enrollment-mode: string # Filter by enrollment mode
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "verified" $verified "scalar") (serialize-qp "enrollment_mode" $enrollment_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Organization Domain
#
# GET /v1/organizations/{organization_id}/domains/{domain_id}
# operationId: GetOrganizationDomain
export def "organizations-domains GetOrganizationDomain" [
  organization_id: string
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/domains/($domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Organization Domain
#
# DELETE /v1/organizations/{organization_id}/domains/{domain_id}
# operationId: deleteOrganizationDomain
export def "organizations-domains delete" [
  organization_id: string
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/domains/($domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Organization Enrollment Mode
#
# POST /v1/organizations/{organization_id}/domains/{domain_id}/update_enrollment_mode
# operationId: UpdateOrganizationDomainEnrollmentMode
export def "organizations-domains-update-enrollment-mode UpdateOrganizationDomainEnrollmentMode" [
  organization_id: string
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  enrollment_mode: string
  --delete-pending: string@bool-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/domains/($domain_id)/update_enrollment_mode")
  let body = {enrollment_mode: $enrollment_mode, delete_pending: $delete_pending} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Prepare Organization Domain Affiliation Verification
#
# POST /v1/organizations/{organization_id}/domains/{domain_id}/prepare_affiliation_verification
# operationId: prepareOrganizationDomainVerification
export def "organizations-domains-prepare-affiliation-verification prepareOrganizationDomainVerification" [
  organization_id: string
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  affiliation_email_address: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/domains/($domain_id)/prepare_affiliation_verification")
  let body = {affiliation_email_address: $affiliation_email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Attempt Organization Domain Affiliation Verification
#
# POST /v1/organizations/{organization_id}/domains/{domain_id}/attempt_affiliation_verification
# operationId: attemptOrganizationDomainVerification
export def "organizations-domains-attempt-affiliation-verification attemptOrganizationDomainVerification" [
  organization_id: string
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # The code that was sent to the email address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/domains/($domain_id)/attempt_affiliation_verification")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Organization Membership Requests
#
# GET /v1/organizations/{organization_id}/membership_requests
# operationId: listOrganizationMembershipRequests
export def "organizations-membership-requests listOrganizationMembershipRequests" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
  --status: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/membership_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept Organization Membership Request
#
# POST /v1/organizations/{organization_id}/membership_requests/{request_id}/accept
# operationId: acceptOrganizationMembershipRequest
export def "organizations-membership-requests-accept acceptOrganizationMembershipRequest" [
  organization_id: string
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/membership_requests/($request_id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reject Organization Membership Request
#
# POST /v1/organizations/{organization_id}/membership_requests/{request_id}/reject
# operationId: rejectOrganizationMembershipRequest
export def "organizations-membership-requests-reject rejectOrganizationMembershipRequest" [
  organization_id: string
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/membership_requests/($request_id)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Organization Roles
#
# GET /v1/organizations/{organization_id}/roles
# operationId: ListOrganizationRoles
export def "organizations-roles ListOrganizationRoles" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Applies a limit to the number of results returned. Can be used for paginating the results together with `offset`. (default: 10)
  --offset: int # Skip the first `offset` results when paginating. Needs to be an integer greater or equal to zero. To be used in conjunction with `limit`. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/organizations/($organization_id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redirect to a validated URL
#
# GET /v1/redirect
# operationId: redirectToUrl
export def "redirect redirectToUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --redirect-url: string # The URL to redirect to (optional). If empty or not provided, redirects to the default URL. (allows empty value)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect_url" $redirect_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/redirect" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept ticket
#
# GET /v1/tickets/accept
# operationId: acceptTicket
export def "tickets-accept acceptTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ticket: string # The JWT with verification information
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ticket" $ticket "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tickets/accept" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attempt Email Link Verification
#
# GET /v1/verify
# operationId: verify
export def "verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # The JWT with verification information
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/verify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Join Waitlist
#
# POST /v1/waitlist
# operationId: joinWaitlist
export def "waitlist joinWaitlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/waitlist")
  let body = {email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get API Keys
#
# GET /api_keys
# operationId: getApiKeys
export def "api-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # default: api_key
  --subject: string
  --include-invalid: string@include-invalid-completer # default: false
  --limit: float # default: 10
  --offset: float # nullable, default: 0
  --qp-query: string
]: nothing -> record<data: table<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float>, total_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "include_invalid" $include_invalid "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API Key
#
# POST /api_keys
# operationId: createApiKey
export def "api-keys createApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # default: api_key
  name: string
  --description: string # nullable
  subject: string
  --seconds-until-expiration: float # nullable
]: any -> record<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list<string>, secret: string, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_keys")
  let body = {type: $type, name: $name, description: $description, subject: $subject, seconds_until_expiration: $seconds_until_expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an API Key
#
# PATCH /api_keys/{apiKeyID}
# operationId: updateApiKey
export def "api-keys updateApiKey" [
  apiKeyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # nullable
]: any -> record<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($apiKeyID)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke an API Key
#
# POST /api_keys/{apiKeyID}/revoke
# operationId: revokeApiKey
export def "api-keys-revoke revokeApiKey" [
  apiKeyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --revocation-reason: string # nullable
]: any -> record<object: string, id: string, type: string, subject: string, name: string, description: string, claims: any, scopes: list<string>, revoked: bool, revocation_reason: string, expired: bool, expiration: float, created_by: string, last_used_at: float, created_at: float, updated_at: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-__client"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($apiKeyID)/revoke")
  let body = {revocation_reason: $revocation_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
