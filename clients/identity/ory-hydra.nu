# Auto-generated client for Ory Hydra API v
# Source: https://raw.githubusercontent.com/ory/hydra/master/spec/api.json
# Auth: --token flag or $env.ORY_HYDRA_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ORY_HYDRA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["basic" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "well-known-jwksjson discoverJsonWebKeys" } } | get name | first)
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

# Discover Well-Known JSON Web Keys
#
# GET /.well-known/jwks.json
# operationId: discoverJsonWebKeys
export def "well-known-jwksjson discoverJsonWebKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<alg: string, crv: string, d: string, dp: string, dq: string, e: string, k: string, kid: string, kty: string, n: string, p: string, q: string, qi: string, use: string, x: string, x5c: list, y: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/jwks.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OpenID Connect Discovery
#
# GET /.well-known/openid-configuration
# operationId: discoverOidcConfiguration
export def "well-known-openid-configuration discoverOidcConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authorization_endpoint: string, backchannel_logout_session_supported: bool, backchannel_logout_supported: bool, claims_parameter_supported: bool, claims_supported: list<string>, code_challenge_methods_supported: list<string>, credentials_endpoint_draft_00: string, credentials_supported_draft_00: table<cryptographic_binding_methods_supported: list, cryptographic_suites_supported: list, format: string, types: list>, device_authorization_endpoint: string, end_session_endpoint: string, frontchannel_logout_session_supported: bool, frontchannel_logout_supported: bool, grant_types_supported: list<string>, id_token_signed_response_alg: list<string>, id_token_signing_alg_values_supported: list<string>, issuer: string, jwks_uri: string, registration_endpoint: string, request_object_signing_alg_values_supported: list<string>, request_parameter_supported: bool, request_uri_parameter_supported: bool, require_request_uri_registration: bool, response_modes_supported: list<string>, response_types_supported: list<string>, revocation_endpoint: string, scopes_supported: list<string>, subject_types_supported: list<string>, token_endpoint: string, token_endpoint_auth_methods_supported: list<string>, userinfo_endpoint: string, userinfo_signed_response_alg: list<string>, userinfo_signing_alg_values_supported: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/openid-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List OAuth 2.0 Clients
#
# GET /admin/clients
# operationId: listOAuth2Clients
export def "admin-clients listOAuth2Clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Items per Page  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --client-name: string # The name of the clients to filter by.
  --owner: string # The owner of the clients to filter by.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "client_name" $client_name "scalar") (serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create OAuth 2.0 Client
#
# POST /admin/clients
# operationId: createOAuth2Client
# --jwks shape: {keys?: list}
export def "admin-clients createOAuth2Client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token-strategy: string # OAuth 2.0 Access Token Strategy  AccessTokenStrategy is the strategy used to generate access tokens. Valid options are `jwt` and `opaque`. `jwt` is a bad idea, see https://www.ory.com/docs/oauth2-oidc/jwt-access-token Setting the strategy here overrides the global setting in `strategies.access_token`.
  --allowed-cors-origins: list # OAuth 2.0 Client Allowed CORS Origins  One or more URLs (scheme://host[:port]) which are allowed to make CORS requests to the /oauth/token endpoint. If this array is empty, the server's CORS origin configuration (`CORS_ALLOWED_ORIGINS`) will be used instead. If this array is set, the allowed origins are appended to the server's CORS origin configuration. Be aware that environment variable `CORS_ENABLED` MUST be set to `true` for this to work.
  --audience: list # OAuth 2.0 Client Audience  An allow-list defining the audiences this client is allowed to request tokens for. An audience limits the applicability of an OAuth 2.0 Access Token to, for example, certain API endpoints. The value is a list of URLs. URLs MUST NOT contain whitespaces. (e.g. https://mydomain.com/api/users, https://mydomain.com/api/posts)
  --authorization-code-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --backchannel-logout-session-required: string@bool-completer # OpenID Connect Back-Channel Logout Session Required  Boolean value specifying whether the RP requires that a sid (session ID) Claim be included in the Logout Token to identify the RP session with the OP when the backchannel_logout_uri is used. If omitted, the default value is false.
  --backchannel-logout-uri: string # OpenID Connect Back-Channel Logout URI  RP URL that will cause the RP to log itself out when sent a Logout Token by the OP.
  --client-credentials-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --client-id: string # OAuth 2.0 Client ID  The ID is immutable. If no ID is provided, a UUID4 will be generated.
  --client-name: string # OAuth 2.0 Client Name  The human-readable name of the client to be presented to the end-user during authorization.
  --client-secret: string # OAuth 2.0 Client Secret  The secret will be included in the create request as cleartext, and then never again. The secret is kept in hashed format and is not recoverable once lost.
  --client-secret-expires-at: int # OAuth 2.0 Client Secret Expires At  The field is currently not supported and its value is always 0. (format: int64)
  --client-uri: string # OAuth 2.0 Client URI  ClientURI is a URL string of a web page providing information about the client. If present, the server SHOULD display this URL to the end-user in a clickable fashion.
  --contacts: list # OAuth 2.0 Client Contact  An array of strings representing ways to contact people responsible for this client, typically email addresses. (e.g. help@example.org)
  --created-at: string # OAuth 2.0 Client Creation Date  CreatedAt returns the timestamp of the client's creation. (format: date-time)
  --device-authorization-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --frontchannel-logout-session-required: string@bool-completer # OpenID Connect Front-Channel Logout Session Required  Boolean value specifying whether the RP requires that iss (issuer) and sid (session ID) query parameters be included to identify the RP session with the OP when the frontchannel_logout_uri is used. If omitted, the default value is false.
  --frontchannel-logout-uri: string # OpenID Connect Front-Channel Logout URI  RP URL that will cause the RP to log itself out when rendered in an iframe by the OP. An iss (issuer) query parameter and a sid (session ID) query parameter MAY be included by the OP to enable the RP to validate the request and to determine which of the potentially multiple sessions is to be logged out; if either is included, both MUST be.
  --grant-types: list # OAuth 2.0 Client Grant Types  An array of OAuth 2.0 grant types the client is allowed to use. Can be one of:  Client Credentials Grant: `client_credentials` Authorization Code Grant: `authorization_code` OpenID Connect Implicit Grant (deprecated!): `implicit` Refresh Token Grant: `refresh_token` OAuth 2.0 Token Exchange: `urn:ietf:params:oauth:grant-type:jwt-bearer` OAuth 2.0 Device Code Grant: `urn:ietf:params:oauth:grant-type:device_code`
  --implicit-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --implicit-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --jwks: record # JSON Web Key Set — shape: {keys?: list}
  --jwks-uri: string # OAuth 2.0 Client JSON Web Key Set URL  URL for the Client's JSON Web Key Set [JWK] document. If the Client signs requests to the Server, it contains the signing key(s) the Server uses to validate signatures from the Client. The JWK Set MAY also contain the Client's encryption keys(s), which are used by the Server to encrypt responses to the Client. When both signing and encryption keys are made available, a use (Key Use) parameter value is REQUIRED for all keys in the referenced JWK Set to indicate each key's intended usage. Although some algorithms allow the same key to be used for both signatures and encryption, doing so is NOT RECOMMENDED, as it is less secure. The JWK x5c parameter MAY be used to provide X.509 representations of keys provided. When used, the bare key values MUST still be present and MUST match those in the certificate.
  --jwt-bearer-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --logo-uri: string # OAuth 2.0 Client Logo URI  A URL string referencing the client's logo.
  --metadata: any
  --owner: string # OAuth 2.0 Client Owner  Owner is a string identifying the owner of the OAuth 2.0 Client.
  --policy-uri: string # OAuth 2.0 Client Policy URI  PolicyURI is a URL string that points to a human-readable privacy policy document that describes how the deployment organization collects, uses, retains, and discloses personal data.
  --post-logout-redirect-uris: list # Allowed Post-Redirect Logout URIs  Array of URLs supplied by the RP to which it MAY request that the End-User's User Agent be redirected using the post_logout_redirect_uri parameter after a logout has been performed.
  --redirect-uris: list # OAuth 2.0 Client Redirect URIs  RedirectURIs is an array of allowed redirect urls for the client. (e.g. http://mydomain/oauth/callback)
  --refresh-token-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --registration-access-token: string # OpenID Connect Dynamic Client Registration Access Token  RegistrationAccessToken can be used to update, get, or delete the OAuth2 Client. It is sent when creating a client using Dynamic Client Registration.
  --registration-client-uri: string # OpenID Connect Dynamic Client Registration URL  RegistrationClientURI is the URL used to update, get, or delete the OAuth2 Client.
  --request-object-signing-alg: string # OpenID Connect Request Object Signing Algorithm  JWS [JWS] alg algorithm [JWA] that MUST be used for signing Request Objects sent to the OP. All Request Objects from this Client MUST be rejected, if not signed with this algorithm.
  --request-uris: list # OpenID Connect Request URIs  Array of request_uri values that are pre-registered by the RP for use at the OP. Servers MAY cache the contents of the files referenced by these URIs and not retrieve them at the time they are used in a request. OPs can require that request_uri values used be pre-registered with the require_request_uri_registration discovery parameter.
  --response-types: list # OAuth 2.0 Client Response Types  An array of the OAuth 2.0 response type strings that the client can use at the authorization endpoint. Can be one of:  Needed for OpenID Connect Implicit Grant: Returns ID Token to redirect URI: `id_token` Returns Access token redirect URI: `token` Needed for Authorization Code Grant: `code`
  --scope: string # OAuth 2.0 Client Scope  Scope is a string containing a space-separated list of scope values (as described in Section 3.3 of OAuth 2.0 [RFC6749]) that the client can use when requesting access tokens. (e.g. scope1 scope-2 scope.3 scope:4)
  --sector-identifier-uri: string # OpenID Connect Sector Identifier URI  URL using the https scheme to be used in calculating Pseudonymous Identifiers by the OP. The URL references a file with a single JSON array of redirect_uri values.
  --skip-consent: string@bool-completer # SkipConsent skips the consent screen for this client. This field can only be set from the admin API.
  --skip-logout-consent: string@bool-completer # SkipLogoutConsent skips the logout consent screen for this client. This field can only be set from the admin API.
  --subject-type: string # OpenID Connect Subject Type  The `subject_types_supported` Discovery parameter contains a list of the supported subject_type values for this server. Valid types include `pairwise` and `public`.
  --token-endpoint-auth-method: string # OAuth 2.0 Token Endpoint Authentication Method  Requested Client Authentication method for the Token Endpoint. The options are:  `client_secret_basic`: (default) Send `client_id` and `client_secret` as `application/x-www-form-urlencoded` encoded in the HTTP Authorization header. `client_secret_post`: Send `client_id` and `client_secret` as `application/x-www-form-urlencoded` in the HTTP body. `private_key_jwt`: Use JSON Web Tokens to authenticate the client. `none`: Used for public clients (native apps, mobile apps) which can not have secrets. (default: client_secret_basic)
  --token-endpoint-auth-signing-alg: string # OAuth 2.0 Token Endpoint Signing Algorithm  Requested Client Authentication signing algorithm for the Token Endpoint.
  --tos-uri: string # OAuth 2.0 Client Terms of Service URI  A URL string pointing to a human-readable terms of service document for the client that describes a contractual relationship between the end-user and the client that the end-user accepts when authorizing the client.
  --updated-at: string # OAuth 2.0 Client Last Update Date  UpdatedAt returns the timestamp of the last update. (format: date-time)
  --userinfo-signed-response-alg: string # OpenID Connect Request Userinfo Signed Response Algorithm  JWS alg algorithm [JWA] REQUIRED for signing UserInfo Responses. If this is specified, the response will be JWT [JWT] serialized, and signed using JWS. The default, if omitted, is for the UserInfo Response to return the Claims as a UTF-8 encoded JSON object using the application/json content-type.
]: any -> record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list<record>>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/clients")
  let body = {access_token_strategy: $access_token_strategy, allowed_cors_origins: $allowed_cors_origins, audience: $audience, authorization_code_grant_access_token_lifespan: $authorization_code_grant_access_token_lifespan, authorization_code_grant_id_token_lifespan: $authorization_code_grant_id_token_lifespan, authorization_code_grant_refresh_token_lifespan: $authorization_code_grant_refresh_token_lifespan, backchannel_logout_session_required: $backchannel_logout_session_required, backchannel_logout_uri: $backchannel_logout_uri, client_credentials_grant_access_token_lifespan: $client_credentials_grant_access_token_lifespan, client_id: $client_id, client_name: $client_name, client_secret: $client_secret, client_secret_expires_at: $client_secret_expires_at, client_uri: $client_uri, contacts: $contacts, created_at: $created_at, device_authorization_grant_access_token_lifespan: $device_authorization_grant_access_token_lifespan, device_authorization_grant_id_token_lifespan: $device_authorization_grant_id_token_lifespan, device_authorization_grant_refresh_token_lifespan: $device_authorization_grant_refresh_token_lifespan, frontchannel_logout_session_required: $frontchannel_logout_session_required, frontchannel_logout_uri: $frontchannel_logout_uri, grant_types: $grant_types, implicit_grant_access_token_lifespan: $implicit_grant_access_token_lifespan, implicit_grant_id_token_lifespan: $implicit_grant_id_token_lifespan, jwks: $jwks, jwks_uri: $jwks_uri, jwt_bearer_grant_access_token_lifespan: $jwt_bearer_grant_access_token_lifespan, logo_uri: $logo_uri, metadata: $metadata, owner: $owner, policy_uri: $policy_uri, post_logout_redirect_uris: $post_logout_redirect_uris, redirect_uris: $redirect_uris, refresh_token_grant_access_token_lifespan: $refresh_token_grant_access_token_lifespan, refresh_token_grant_id_token_lifespan: $refresh_token_grant_id_token_lifespan, refresh_token_grant_refresh_token_lifespan: $refresh_token_grant_refresh_token_lifespan, registration_access_token: $registration_access_token, registration_client_uri: $registration_client_uri, request_object_signing_alg: $request_object_signing_alg, request_uris: $request_uris, response_types: $response_types, scope: $scope, sector_identifier_uri: $sector_identifier_uri, skip_consent: $skip_consent, skip_logout_consent: $skip_logout_consent, subject_type: $subject_type, token_endpoint_auth_method: $token_endpoint_auth_method, token_endpoint_auth_signing_alg: $token_endpoint_auth_signing_alg, tos_uri: $tos_uri, updated_at: $updated_at, userinfo_signed_response_alg: $userinfo_signed_response_alg} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete OAuth 2.0 Client
#
# DELETE /admin/clients/{id}
# operationId: deleteOAuth2Client
export def "admin-clients delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: int, debug: string, details: any, id: string, message: string, reason: string, request: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/clients/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an OAuth 2.0 Client
#
# GET /admin/clients/{id}
# operationId: getOAuth2Client
export def "admin-clients get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list<record>>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/clients/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch OAuth 2.0 Client
#
# PATCH /admin/clients/{id}
# operationId: patchOAuth2Client
export def "admin-clients patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list<record>>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/clients/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set OAuth 2.0 Client
#
# PUT /admin/clients/{id}
# operationId: setOAuth2Client
# --jwks shape: {keys?: list}
export def "admin-clients setOAuth2Client" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token-strategy: string # OAuth 2.0 Access Token Strategy  AccessTokenStrategy is the strategy used to generate access tokens. Valid options are `jwt` and `opaque`. `jwt` is a bad idea, see https://www.ory.com/docs/oauth2-oidc/jwt-access-token Setting the strategy here overrides the global setting in `strategies.access_token`.
  --allowed-cors-origins: list # OAuth 2.0 Client Allowed CORS Origins  One or more URLs (scheme://host[:port]) which are allowed to make CORS requests to the /oauth/token endpoint. If this array is empty, the server's CORS origin configuration (`CORS_ALLOWED_ORIGINS`) will be used instead. If this array is set, the allowed origins are appended to the server's CORS origin configuration. Be aware that environment variable `CORS_ENABLED` MUST be set to `true` for this to work.
  --audience: list # OAuth 2.0 Client Audience  An allow-list defining the audiences this client is allowed to request tokens for. An audience limits the applicability of an OAuth 2.0 Access Token to, for example, certain API endpoints. The value is a list of URLs. URLs MUST NOT contain whitespaces. (e.g. https://mydomain.com/api/users, https://mydomain.com/api/posts)
  --authorization-code-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --backchannel-logout-session-required: string@bool-completer # OpenID Connect Back-Channel Logout Session Required  Boolean value specifying whether the RP requires that a sid (session ID) Claim be included in the Logout Token to identify the RP session with the OP when the backchannel_logout_uri is used. If omitted, the default value is false.
  --backchannel-logout-uri: string # OpenID Connect Back-Channel Logout URI  RP URL that will cause the RP to log itself out when sent a Logout Token by the OP.
  --client-credentials-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --client-id: string # OAuth 2.0 Client ID  The ID is immutable. If no ID is provided, a UUID4 will be generated.
  --client-name: string # OAuth 2.0 Client Name  The human-readable name of the client to be presented to the end-user during authorization.
  --client-secret: string # OAuth 2.0 Client Secret  The secret will be included in the create request as cleartext, and then never again. The secret is kept in hashed format and is not recoverable once lost.
  --client-secret-expires-at: int # OAuth 2.0 Client Secret Expires At  The field is currently not supported and its value is always 0. (format: int64)
  --client-uri: string # OAuth 2.0 Client URI  ClientURI is a URL string of a web page providing information about the client. If present, the server SHOULD display this URL to the end-user in a clickable fashion.
  --contacts: list # OAuth 2.0 Client Contact  An array of strings representing ways to contact people responsible for this client, typically email addresses. (e.g. help@example.org)
  --created-at: string # OAuth 2.0 Client Creation Date  CreatedAt returns the timestamp of the client's creation. (format: date-time)
  --device-authorization-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --frontchannel-logout-session-required: string@bool-completer # OpenID Connect Front-Channel Logout Session Required  Boolean value specifying whether the RP requires that iss (issuer) and sid (session ID) query parameters be included to identify the RP session with the OP when the frontchannel_logout_uri is used. If omitted, the default value is false.
  --frontchannel-logout-uri: string # OpenID Connect Front-Channel Logout URI  RP URL that will cause the RP to log itself out when rendered in an iframe by the OP. An iss (issuer) query parameter and a sid (session ID) query parameter MAY be included by the OP to enable the RP to validate the request and to determine which of the potentially multiple sessions is to be logged out; if either is included, both MUST be.
  --grant-types: list # OAuth 2.0 Client Grant Types  An array of OAuth 2.0 grant types the client is allowed to use. Can be one of:  Client Credentials Grant: `client_credentials` Authorization Code Grant: `authorization_code` OpenID Connect Implicit Grant (deprecated!): `implicit` Refresh Token Grant: `refresh_token` OAuth 2.0 Token Exchange: `urn:ietf:params:oauth:grant-type:jwt-bearer` OAuth 2.0 Device Code Grant: `urn:ietf:params:oauth:grant-type:device_code`
  --implicit-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --implicit-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --jwks: record # JSON Web Key Set — shape: {keys?: list}
  --jwks-uri: string # OAuth 2.0 Client JSON Web Key Set URL  URL for the Client's JSON Web Key Set [JWK] document. If the Client signs requests to the Server, it contains the signing key(s) the Server uses to validate signatures from the Client. The JWK Set MAY also contain the Client's encryption keys(s), which are used by the Server to encrypt responses to the Client. When both signing and encryption keys are made available, a use (Key Use) parameter value is REQUIRED for all keys in the referenced JWK Set to indicate each key's intended usage. Although some algorithms allow the same key to be used for both signatures and encryption, doing so is NOT RECOMMENDED, as it is less secure. The JWK x5c parameter MAY be used to provide X.509 representations of keys provided. When used, the bare key values MUST still be present and MUST match those in the certificate.
  --jwt-bearer-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --logo-uri: string # OAuth 2.0 Client Logo URI  A URL string referencing the client's logo.
  --metadata: any
  --owner: string # OAuth 2.0 Client Owner  Owner is a string identifying the owner of the OAuth 2.0 Client.
  --policy-uri: string # OAuth 2.0 Client Policy URI  PolicyURI is a URL string that points to a human-readable privacy policy document that describes how the deployment organization collects, uses, retains, and discloses personal data.
  --post-logout-redirect-uris: list # Allowed Post-Redirect Logout URIs  Array of URLs supplied by the RP to which it MAY request that the End-User's User Agent be redirected using the post_logout_redirect_uri parameter after a logout has been performed.
  --redirect-uris: list # OAuth 2.0 Client Redirect URIs  RedirectURIs is an array of allowed redirect urls for the client. (e.g. http://mydomain/oauth/callback)
  --refresh-token-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --registration-access-token: string # OpenID Connect Dynamic Client Registration Access Token  RegistrationAccessToken can be used to update, get, or delete the OAuth2 Client. It is sent when creating a client using Dynamic Client Registration.
  --registration-client-uri: string # OpenID Connect Dynamic Client Registration URL  RegistrationClientURI is the URL used to update, get, or delete the OAuth2 Client.
  --request-object-signing-alg: string # OpenID Connect Request Object Signing Algorithm  JWS [JWS] alg algorithm [JWA] that MUST be used for signing Request Objects sent to the OP. All Request Objects from this Client MUST be rejected, if not signed with this algorithm.
  --request-uris: list # OpenID Connect Request URIs  Array of request_uri values that are pre-registered by the RP for use at the OP. Servers MAY cache the contents of the files referenced by these URIs and not retrieve them at the time they are used in a request. OPs can require that request_uri values used be pre-registered with the require_request_uri_registration discovery parameter.
  --response-types: list # OAuth 2.0 Client Response Types  An array of the OAuth 2.0 response type strings that the client can use at the authorization endpoint. Can be one of:  Needed for OpenID Connect Implicit Grant: Returns ID Token to redirect URI: `id_token` Returns Access token redirect URI: `token` Needed for Authorization Code Grant: `code`
  --scope: string # OAuth 2.0 Client Scope  Scope is a string containing a space-separated list of scope values (as described in Section 3.3 of OAuth 2.0 [RFC6749]) that the client can use when requesting access tokens. (e.g. scope1 scope-2 scope.3 scope:4)
  --sector-identifier-uri: string # OpenID Connect Sector Identifier URI  URL using the https scheme to be used in calculating Pseudonymous Identifiers by the OP. The URL references a file with a single JSON array of redirect_uri values.
  --skip-consent: string@bool-completer # SkipConsent skips the consent screen for this client. This field can only be set from the admin API.
  --skip-logout-consent: string@bool-completer # SkipLogoutConsent skips the logout consent screen for this client. This field can only be set from the admin API.
  --subject-type: string # OpenID Connect Subject Type  The `subject_types_supported` Discovery parameter contains a list of the supported subject_type values for this server. Valid types include `pairwise` and `public`.
  --token-endpoint-auth-method: string # OAuth 2.0 Token Endpoint Authentication Method  Requested Client Authentication method for the Token Endpoint. The options are:  `client_secret_basic`: (default) Send `client_id` and `client_secret` as `application/x-www-form-urlencoded` encoded in the HTTP Authorization header. `client_secret_post`: Send `client_id` and `client_secret` as `application/x-www-form-urlencoded` in the HTTP body. `private_key_jwt`: Use JSON Web Tokens to authenticate the client. `none`: Used for public clients (native apps, mobile apps) which can not have secrets. (default: client_secret_basic)
  --token-endpoint-auth-signing-alg: string # OAuth 2.0 Token Endpoint Signing Algorithm  Requested Client Authentication signing algorithm for the Token Endpoint.
  --tos-uri: string # OAuth 2.0 Client Terms of Service URI  A URL string pointing to a human-readable terms of service document for the client that describes a contractual relationship between the end-user and the client that the end-user accepts when authorizing the client.
  --updated-at: string # OAuth 2.0 Client Last Update Date  UpdatedAt returns the timestamp of the last update. (format: date-time)
  --userinfo-signed-response-alg: string # OpenID Connect Request Userinfo Signed Response Algorithm  JWS alg algorithm [JWA] REQUIRED for signing UserInfo Responses. If this is specified, the response will be JWT [JWT] serialized, and signed using JWS. The default, if omitted, is for the UserInfo Response to return the Claims as a UTF-8 encoded JSON object using the application/json content-type.
]: any -> record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list<record>>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/clients/($id)")
  let body = {access_token_strategy: $access_token_strategy, allowed_cors_origins: $allowed_cors_origins, audience: $audience, authorization_code_grant_access_token_lifespan: $authorization_code_grant_access_token_lifespan, authorization_code_grant_id_token_lifespan: $authorization_code_grant_id_token_lifespan, authorization_code_grant_refresh_token_lifespan: $authorization_code_grant_refresh_token_lifespan, backchannel_logout_session_required: $backchannel_logout_session_required, backchannel_logout_uri: $backchannel_logout_uri, client_credentials_grant_access_token_lifespan: $client_credentials_grant_access_token_lifespan, client_id: $client_id, client_name: $client_name, client_secret: $client_secret, client_secret_expires_at: $client_secret_expires_at, client_uri: $client_uri, contacts: $contacts, created_at: $created_at, device_authorization_grant_access_token_lifespan: $device_authorization_grant_access_token_lifespan, device_authorization_grant_id_token_lifespan: $device_authorization_grant_id_token_lifespan, device_authorization_grant_refresh_token_lifespan: $device_authorization_grant_refresh_token_lifespan, frontchannel_logout_session_required: $frontchannel_logout_session_required, frontchannel_logout_uri: $frontchannel_logout_uri, grant_types: $grant_types, implicit_grant_access_token_lifespan: $implicit_grant_access_token_lifespan, implicit_grant_id_token_lifespan: $implicit_grant_id_token_lifespan, jwks: $jwks, jwks_uri: $jwks_uri, jwt_bearer_grant_access_token_lifespan: $jwt_bearer_grant_access_token_lifespan, logo_uri: $logo_uri, metadata: $metadata, owner: $owner, policy_uri: $policy_uri, post_logout_redirect_uris: $post_logout_redirect_uris, redirect_uris: $redirect_uris, refresh_token_grant_access_token_lifespan: $refresh_token_grant_access_token_lifespan, refresh_token_grant_id_token_lifespan: $refresh_token_grant_id_token_lifespan, refresh_token_grant_refresh_token_lifespan: $refresh_token_grant_refresh_token_lifespan, registration_access_token: $registration_access_token, registration_client_uri: $registration_client_uri, request_object_signing_alg: $request_object_signing_alg, request_uris: $request_uris, response_types: $response_types, scope: $scope, sector_identifier_uri: $sector_identifier_uri, skip_consent: $skip_consent, skip_logout_consent: $skip_logout_consent, subject_type: $subject_type, token_endpoint_auth_method: $token_endpoint_auth_method, token_endpoint_auth_signing_alg: $token_endpoint_auth_signing_alg, tos_uri: $tos_uri, updated_at: $updated_at, userinfo_signed_response_alg: $userinfo_signed_response_alg} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set OAuth2 Client Token Lifespans
#
# PUT /admin/clients/{id}/lifespans
# operationId: setOAuth2ClientLifespans
export def "admin-clients-lifespans setOAuth2ClientLifespans" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorization-code-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --client-credentials-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --implicit-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --implicit-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --jwt-bearer-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
]: any -> record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list<record>>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/clients/($id)/lifespans")
  let body = {authorization_code_grant_access_token_lifespan: $authorization_code_grant_access_token_lifespan, authorization_code_grant_id_token_lifespan: $authorization_code_grant_id_token_lifespan, authorization_code_grant_refresh_token_lifespan: $authorization_code_grant_refresh_token_lifespan, client_credentials_grant_access_token_lifespan: $client_credentials_grant_access_token_lifespan, device_authorization_grant_access_token_lifespan: $device_authorization_grant_access_token_lifespan, device_authorization_grant_id_token_lifespan: $device_authorization_grant_id_token_lifespan, device_authorization_grant_refresh_token_lifespan: $device_authorization_grant_refresh_token_lifespan, implicit_grant_access_token_lifespan: $implicit_grant_access_token_lifespan, implicit_grant_id_token_lifespan: $implicit_grant_id_token_lifespan, jwt_bearer_grant_access_token_lifespan: $jwt_bearer_grant_access_token_lifespan, refresh_token_grant_access_token_lifespan: $refresh_token_grant_access_token_lifespan, refresh_token_grant_id_token_lifespan: $refresh_token_grant_id_token_lifespan, refresh_token_grant_refresh_token_lifespan: $refresh_token_grant_refresh_token_lifespan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete JSON Web Key Set
#
# DELETE /admin/keys/{set}
# operationId: deleteJsonWebKeySet
export def "admin-keys delete-by-set" [
  set: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/keys/($set)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a JSON Web Key Set
#
# GET /admin/keys/{set}
# operationId: getJsonWebKeySet
export def "admin-keys list" [
  set: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<alg: string, crv: string, d: string, dp: string, dq: string, e: string, k: string, kid: string, kty: string, n: string, p: string, q: string, qi: string, use: string, x: string, x5c: list, y: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/keys/($set)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create JSON Web Key
#
# POST /admin/keys/{set}
# operationId: createJsonWebKeySet
export def "admin-keys createJsonWebKeySet" [
  set: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alg: string # JSON Web Key Algorithm  The algorithm to be used for creating the key. Supports `RS256`, `ES256`, `ES512`, `HS512`, and `HS256`.
  kid: string # JSON Web Key ID  The Key ID of the key to be created.
  --body-use: string # JSON Web Key Use  The "use" (public key use) parameter identifies the intended use of the public key. The "use" parameter is employed to indicate whether a public key is used for encrypting data or verifying the signature on data. Valid values are "enc" and "sig".
]: any -> record<keys: table<alg: string, crv: string, d: string, dp: string, dq: string, e: string, k: string, kid: string, kty: string, n: string, p: string, q: string, qi: string, use: string, x: string, x5c: list, y: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/keys/($set)")
  let body = {alg: $alg, kid: $kid, use: $body_use} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a JSON Web Key Set
#
# PUT /admin/keys/{set}
# operationId: setJsonWebKeySet
# --keys item shape: {alg: string, crv?: string, d?: string, dp?: string, dq?: string, e?: string, k?: string, kid: string, kty: string, n?: string, p?: string, q?: string, qi?: string, use: string, x?: string, x5c?: list, y?: string}
export def "admin-keys setJsonWebKeySet" [
  set: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keys: list # List of JSON Web Keys  The value of the "keys" parameter is an array of JSON Web Key (JWK) values. By default, the order of the JWK values within the array does not imply an order of preference among them, although applications of JWK Sets can choose to assign a meaning to the order for their purposes, if desired. — item shape: {alg: string, crv?: string, d?: string, dp?: string, dq?: string, e?: string, k?: string, kid: string, kty: string, n?: string, p?: string, q?: string, qi?: string, use: string, x?: string, x5c?: list, y?: string}
]: any -> record<keys: table<alg: string, crv: string, d: string, dp: string, dq: string, e: string, k: string, kid: string, kty: string, n: string, p: string, q: string, qi: string, use: string, x: string, x5c: list, y: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/keys/($set)")
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete JSON Web Key
#
# DELETE /admin/keys/{set}/{kid}
# operationId: deleteJsonWebKey
export def "admin-keys delete-by-set-kid" [
  set: string
  kid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/keys/($set)/($kid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get JSON Web Key
#
# GET /admin/keys/{set}/{kid}
# operationId: getJsonWebKey
export def "admin-keys get" [
  set: string
  kid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<alg: string, crv: string, d: string, dp: string, dq: string, e: string, k: string, kid: string, kty: string, n: string, p: string, q: string, qi: string, use: string, x: string, x5c: list, y: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/keys/($set)/($kid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set JSON Web Key
#
# PUT /admin/keys/{set}/{kid}
# operationId: setJsonWebKey
export def "admin-keys setJsonWebKey" [
  set: string
  kid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alg: string # The "alg" (algorithm) parameter identifies the algorithm intended for use with the key.  The values used should either be registered in the IANA "JSON Web Signature and Encryption Algorithms" registry established by [JWA] or be a value that contains a Collision- Resistant Name. (e.g. RS256)
  --crv: string # e.g. P-256
  --d: string # e.g. T_N8I-6He3M8a7X1vWt6TGIx4xB_GP3Mb4SsZSA4v-orvJzzRiQhLlRR81naWYxfQAYt5isDI6_C2L9bdWo4FFPjGQFvNoRX-_sBJyBI_rl-TBgsZYoUlAj3J92WmY2inbA-PwyJfsaIIDceYBC-eX-xiCu6qMqkZi3MwQAFL6bMdPEM0z4JBcwFT3VdiWAIRUuACWQwrXMq672x7fMuaIaHi7XDGgt1ith23CLfaREmJku9PQcchbt_uEY-hqrFY6ntTtS4paWWQj86xLL94S-Tf6v6xkL918PfLSOTq6XCzxvlFwzBJqApnAhbwqLjpPhgUG04EDRrqrSBc5Y1BLevn6Ip5h1AhessBp3wLkQgz_roeckt-ybvzKTjESMuagnpqLvOT7Y9veIug2MwPJZI2VjczRc1vzMs25XrFQ8DpUy-bNdp89TmvAXwctUMiJdgHloJw23Cv03gIUAkDnsTqZmkpbIf-crpgNKFmQP_EDKoe8p_PXZZgfbRri3NoEVGP7Mk6yEu8LjJhClhZaBNjuWw2-KlBfOA3g79mhfBnkInee5KO9mGR50qPk1V-MorUYNTFMZIm0kFE6eYVWFBwJHLKYhHU34DoiK1VP-svZpC2uAMFNA_UJEwM9CQ2b8qe4-5e9aywMvwcuArRkAB5mBIfOaOJao3mfukKAE
  --dp: string # e.g. G4sPXkc6Ya9y8oJW9_ILj4xuppu0lzi_H7VTkS8xj5SdX3coE0oimYwxIi2emTAue0UOa5dpgFGyBJ4c8tQ2VF402XRugKDTP8akYhFo5tAA77Qe_NmtuYZc3C3m3I24G2GvR5sSDxUyAN2zq8Lfn9EUms6rY3Ob8YeiKkTiBj0
  --dq: string # e.g. s9lAH9fggBsoFR8Oac2R_E2gw282rT2kGOAhvIllETE1efrA6huUUvMfBcMpn8lqeW6vzznYY5SSQF7pMdC_agI3nG8Ibp1BUb0JUiraRNqUfLhcQb_d9GF4Dh7e74WbRsobRonujTYN1xCaP6TO61jvWrX-L18txXw494Q_cgk
  --e: string # e.g. AQAB
  --k: string # e.g. GawgguFyGrWKav7AX4VKUg
  --body-kid: string # The "kid" (key ID) parameter is used to match a specific key.  This is used, for instance, to choose among a set of keys within a JWK Set during key rollover.  The structure of the "kid" value is unspecified.  When "kid" values are used within a JWK Set, different keys within the JWK Set SHOULD use distinct "kid" values.  (One example in which different keys might use the same "kid" value is if they have different "kty" (key type) values but are considered to be equivalent alternatives by the application using them.)  The "kid" value is a case-sensitive string. (e.g. 1603dfe0af8f4596)
  kty: string # The "kty" (key type) parameter identifies the cryptographic algorithm family used with the key, such as "RSA" or "EC". "kty" values should either be registered in the IANA "JSON Web Key Types" registry established by [JWA] or be a value that contains a Collision- Resistant Name.  The "kty" value is a case-sensitive string. (e.g. RSA)
  --n: string # e.g. vTqrxUyQPl_20aqf5kXHwDZrel-KovIp8s7ewJod2EXHl8tWlRB3_Rem34KwBfqlKQGp1nqah-51H4Jzruqe0cFP58hPEIt6WqrvnmJCXxnNuIB53iX_uUUXXHDHBeaPCSRoNJzNysjoJ30TIUsKBiirhBa7f235PXbKiHducLevV6PcKxJ5cY8zO286qJLBWSPm-OIevwqsIsSIH44Qtm9sioFikhkbLwoqwWORGAY0nl6XvVOlhADdLjBSqSAeT1FPuCDCnXwzCDR8N9IFB_IjdStFkC-rVt2K5BYfPd0c3yFp_vHR15eRd0zJ8XQ7woBC8Vnsac6Et1pKS59pX6256DPWu8UDdEOolKAPgcd_g2NpA76cAaF_jcT80j9KrEzw8Tv0nJBGesuCjPNjGs_KzdkWTUXt23Hn9QJsdc1MZuaW0iqXBepHYfYoqNelzVte117t4BwVp0kUM6we0IqyXClaZgOI8S-WDBw2_Ovdm8e5NmhYAblEVoygcX8Y46oH6bKiaCQfKCFDMcRgChme7AoE1yZZYsPbaG_3IjPrC4LBMHQw8rM9dWjJ8ImjicvZ1pAm0dx-KHCP3y5PVKrxBDf1zSOsBRkOSjB8TPODnJMz6-jd5hTtZxpZPwPoIdCanTZ3ZD6uRBpTmDwtpRGm63UQs1m5FWPwb0T2IF0
  --p: string # e.g. 6NbkXwDWUhi-eR55Cgbf27FkQDDWIamOaDr0rj1q0f1fFEz1W5A_09YvG09Fiv1AO2-D8Rl8gS1Vkz2i0zCSqnyy8A025XOcRviOMK7nIxE4OH_PEsko8dtIrb3TmE2hUXvCkmzw9EsTF1LQBOGC6iusLTXepIC1x9ukCKFZQvdgtEObQ5kzd9Nhq-cdqmSeMVLoxPLd1blviVT9Vm8-y12CtYpeJHOaIDtVPLlBhJiBoPKWg3vxSm4XxIliNOefqegIlsmTIa3MpS6WWlCK3yHhat0Q-rRxDxdyiVdG_wzJvp0Iw_2wms7pe-PgNPYvUWH9JphWP5K38YqEBiJFXQ
  --q: string # e.g. 0A1FmpOWR91_RAWpqreWSavNaZb9nXeKiBo0DQGBz32DbqKqQ8S4aBJmbRhJcctjCLjain-ivut477tAUMmzJwVJDDq2MZFwC9Q-4VYZmFU4HJityQuSzHYe64RjN-E_NQ02TWhG3QGW6roq6c57c99rrUsETwJJiwS8M5p15Miuz53DaOjv-uqqFAFfywN5WkxHbraBcjHtMiQuyQbQqkCFh-oanHkwYNeytsNhTu2mQmwR5DR2roZ2nPiFjC6nsdk-A7E3S3wMzYYFw7jvbWWoYWo9vB40_MY2Y0FYQSqcDzcBIcq_0tnnasf3VW4Fdx6m80RzOb2Fsnln7vKXAQ
  --qi: string # e.g. GyM_p6JrXySiz1toFgKbWV-JdI3jQ4ypu9rbMWx3rQJBfmt0FoYzgUIZEVFEcOqwemRN81zoDAaa-Bk0KWNGDjJHZDdDmFhW3AN7lI-puxk_mHZGJ11rxyR8O55XLSe3SPmRfKwZI6yU24ZxvQKFYItdldUKGzO6Ia6zTKhAVRU
  --body-use: string # Use ("public key use") identifies the intended use of the public key. The "use" parameter is employed to indicate whether a public key is used for encrypting data or verifying the signature on data. Values are commonly "sig" (signature) or "enc" (encryption). (e.g. sig)
  --x: string # e.g. f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU
  --x5c: list # The "x5c" (X.509 certificate chain) parameter contains a chain of one or more PKIX certificates [RFC5280].  The certificate chain is represented as a JSON array of certificate value strings.  Each string in the array is a base64-encoded (Section 4 of [RFC4648] -- not base64url-encoded) DER [ITU.X690.1994] PKIX certificate value. The PKIX certificate containing the key value MUST be the first certificate.
  --y: string # e.g. x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0
]: any -> record<alg: string, crv: string, d: string, dp: string, dq: string, e: string, k: string, kid: string, kty: string, n: string, p: string, q: string, qi: string, use: string, x: string, x5c: list<string>, y: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/keys/($set)/($kid)")
  let body = {alg: $alg, crv: $crv, d: $d, dp: $dp, dq: $dq, e: $e, k: $k, kid: $body_kid, kty: $kty, n: $n, p: $p, q: $q, qi: $qi, use: $body_use, x: $x, x5c: $x5c, y: $y} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get OAuth 2.0 Consent Request
#
# GET /admin/oauth2/auth/requests/consent
# operationId: getOAuth2ConsentRequest
export def "admin-oauth2-auth-requests-consent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consent-challenge: string # OAuth 2.0 Consent Request Challenge
]: nothing -> record<acr: string, amr: list<string>, challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, consent_request_id: string, context: any, login_challenge: string, login_session_id: string, oidc_context: record<acr_values: list<string>, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list<string>>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, skip: bool, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consent_challenge" $consent_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/consent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept OAuth 2.0 Consent Request
#
# PUT /admin/oauth2/auth/requests/consent/accept
# operationId: acceptOAuth2ConsentRequest
# --session shape: {access_token?: any, id_token?: any}
export def "admin-oauth2-auth-requests-consent-accept acceptOAuth2ConsentRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consent-challenge: string # OAuth 2.0 Consent Request Challenge
  --context: any
  --grant-access-token-audience: list # GrantedAudience sets the audience the user authorized the client to use. Should be a subset of `requested_access_token_audience`.
  --grant-scope: list # GrantScope sets the scope the user authorized the client to use. Should be a subset of `requested_scope`.
  --remember: string@bool-completer # Remember, if set to true, tells ORY Hydra to remember this consent authorization and reuse it if the same client asks the same user for the same, or a subset of, scope.
  --remember-for: int # RememberFor sets how long the consent authorization should be remembered for in seconds. If set to `0`, the authorization will be remembered indefinitely. (format: int64)
  --session: record # shape: {access_token?: any, id_token?: any}
]: any -> record<redirect_to: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consent_challenge" $consent_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/consent/accept" $qp)
  let body = {context: $context, grant_access_token_audience: $grant_access_token_audience, grant_scope: $grant_scope, remember: $remember, remember_for: $remember_for, session: $session} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reject OAuth 2.0 Consent Request
#
# PUT /admin/oauth2/auth/requests/consent/reject
# operationId: rejectOAuth2ConsentRequest
export def "admin-oauth2-auth-requests-consent-reject rejectOAuth2ConsentRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consent-challenge: string # OAuth 2.0 Consent Request Challenge
  --body-error: string # The error should follow the OAuth2 error format (e.g. `invalid_request`, `login_required`).  Defaults to `request_denied`.
  --error-debug: string # Debug contains information to help resolve the problem as a developer. Usually not exposed to the public but only in the server logs.
  --error-description: string # Description of the error in a human readable format.
  --error-hint: string # Hint to help resolve the error.
  --status-code: int # Represents the HTTP status code of the error (e.g. 401 or 403)  Defaults to 400 (format: int64)
]: any -> record<redirect_to: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consent_challenge" $consent_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/consent/reject" $qp)
  let body = {error: $body_error, error_debug: $error_debug, error_description: $error_description, error_hint: $error_hint, status_code: $status_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Accepts a device grant user_code request
#
# PUT /admin/oauth2/auth/requests/device/accept
# operationId: acceptUserCodeRequest
export def "admin-oauth2-auth-requests-device-accept acceptUserCodeRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --device-challenge: string
  --user-code: string
]: any -> record<redirect_to: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_challenge" $device_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/device/accept" $qp)
  let body = {user_code: $user_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get OAuth 2.0 Login Request
#
# GET /admin/oauth2/auth/requests/login
# operationId: getOAuth2LoginRequest
export def "admin-oauth2-auth-requests-login get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --login-challenge: string # OAuth 2.0 Login Request Challenge
]: nothing -> record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, oidc_context: record<acr_values: list<string>, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list<string>>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, session_id: string, skip: bool, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login_challenge" $login_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept OAuth 2.0 Login Request
#
# PUT /admin/oauth2/auth/requests/login/accept
# operationId: acceptOAuth2LoginRequest
export def "admin-oauth2-auth-requests-login-accept acceptOAuth2LoginRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --login-challenge: string # OAuth 2.0 Login Request Challenge
  --acr: string # ACR sets the Authentication AuthorizationContext Class Reference value for this authentication session. You can use it to express that, for example, a user authenticated using two-factor authentication.
  --amr: list # AMR sets the Authentication Methods References value for this authentication session. You can use it to specify the method a user used to authenticate. For example, if the acr indicates a user used two-factor authentication, the amr can express they used a software-secured key.
  --context: any
  --extend-session-lifespan: string@bool-completer # Extend OAuth2 authentication session lifespan  If set to `true`, the OAuth2 authentication cookie lifespan is extended. This is for example useful if you want the user to be able to use `prompt=none` continuously.  This value can only be set to `true` if the user has an authentication, which is the case if the `skip` value is `true`.
  --force-subject-identifier: string # ForceSubjectIdentifier forces the "pairwise" user ID of the end-user that authenticated. The "pairwise" user ID refers to the (Pairwise Identifier Algorithm)[http://openid.net/specs/openid-connect-core-1_0.html#PairwiseAlg] of the OpenID Connect specification. It allows you to set an obfuscated subject ("user") identifier that is unique to the client.  Please note that this changes the user ID on endpoint /userinfo and sub claim of the ID Token. It does not change the sub claim in the OAuth 2.0 Introspection.  Per default, ORY Hydra handles this value with its own algorithm. In case you want to set this yourself you can use this field. Please note that setting this field has no effect if `pairwise` is not configured in ORY Hydra or the OAuth 2.0 Client does not expect a pairwise identifier (set via `subject_type` key in the client's configuration).  Please also be aware that ORY Hydra is unable to properly compute this value during authentication. This implies that you have to compute this value on every authentication process (probably depending on the client ID or some other unique value).  If you fail to compute the proper value, then authentication processes which have id_token_hint set might fail.
  --identity-provider-session-id: string # IdentityProviderSessionID is the session ID of the end-user that authenticated. If specified, we will use this value to propagate the logout.
  --remember: string@bool-completer # Remember, if set to true, tells Ory Hydra to remember this user by telling the user agent (browser) to store a cookie with authentication data. If the same user performs another OAuth 2.0 Authorization Request, they will not be asked to log in again.
  --remember-for: int # RememberFor sets how long the authentication should be remembered for in seconds. If set to `0`, the authorization will be remembered for the duration of the browser session (using a session cookie). (format: int64)
  subject: string # Subject is the user ID of the end-user that authenticated.
]: any -> record<redirect_to: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login_challenge" $login_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/login/accept" $qp)
  let body = {acr: $acr, amr: $amr, context: $context, extend_session_lifespan: $extend_session_lifespan, force_subject_identifier: $force_subject_identifier, identity_provider_session_id: $identity_provider_session_id, remember: $remember, remember_for: $remember_for, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reject OAuth 2.0 Login Request
#
# PUT /admin/oauth2/auth/requests/login/reject
# operationId: rejectOAuth2LoginRequest
export def "admin-oauth2-auth-requests-login-reject rejectOAuth2LoginRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --login-challenge: string # OAuth 2.0 Login Request Challenge
  --body-error: string # The error should follow the OAuth2 error format (e.g. `invalid_request`, `login_required`).  Defaults to `request_denied`.
  --error-debug: string # Debug contains information to help resolve the problem as a developer. Usually not exposed to the public but only in the server logs.
  --error-description: string # Description of the error in a human readable format.
  --error-hint: string # Hint to help resolve the error.
  --status-code: int # Represents the HTTP status code of the error (e.g. 401 or 403)  Defaults to 400 (format: int64)
]: any -> record<redirect_to: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login_challenge" $login_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/login/reject" $qp)
  let body = {error: $body_error, error_debug: $error_debug, error_description: $error_description, error_hint: $error_hint, status_code: $status_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get OAuth 2.0 Session Logout Request
#
# GET /admin/oauth2/auth/requests/logout
# operationId: getOAuth2LogoutRequest
export def "admin-oauth2-auth-requests-logout get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logout-challenge: string
]: nothing -> record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, expires_at: string, request_url: string, requested_at: string, rp_initiated: bool, sid: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "logout_challenge" $logout_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/logout" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept OAuth 2.0 Session Logout Request
#
# PUT /admin/oauth2/auth/requests/logout/accept
# operationId: acceptOAuth2LogoutRequest
export def "admin-oauth2-auth-requests-logout-accept acceptOAuth2LogoutRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logout-challenge: string # OAuth 2.0 Logout Request Challenge
]: nothing -> record<redirect_to: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "logout_challenge" $logout_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/logout/accept" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reject OAuth 2.0 Session Logout Request
#
# PUT /admin/oauth2/auth/requests/logout/reject
# operationId: rejectOAuth2LogoutRequest
export def "admin-oauth2-auth-requests-logout-reject rejectOAuth2LogoutRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logout-challenge: string
]: nothing -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "logout_challenge" $logout_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/requests/logout/reject" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke OAuth 2.0 Consent Sessions of a Subject
#
# DELETE /admin/oauth2/auth/sessions/consent
# operationId: revokeOAuth2ConsentSessions
export def "admin-oauth2-auth-sessions-consent revokeOAuth2ConsentSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subject: string # OAuth 2.0 Consent Subject  The subject whose consent sessions should be deleted.
  --client: string # OAuth 2.0 Client ID  If set, deletes only those consent sessions that have been granted to the specified OAuth 2.0 Client ID.
  --consent-request-id: string # Consent Request ID  If set, revoke all token chains derived from this particular consent request ID.
  --all: string@bool-completer # Revoke All Consent Sessions  If set to `true` deletes all consent sessions by the Subject that have been granted.
]: nothing -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "scalar") (serialize-qp "client" $client "scalar") (serialize-qp "consent_request_id" $consent_request_id "scalar") (serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/sessions/consent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List OAuth 2.0 Consent Sessions of a Subject
#
# GET /admin/oauth2/auth/sessions/consent
# operationId: listOAuth2ConsentSessions
export def "admin-oauth2-auth-sessions-consent listOAuth2ConsentSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Items per Page  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --subject: string # The subject to list the consent sessions for.
  --login-session-id: string # The login session id to list the consent sessions for.
]: nothing -> table<consent_request: record<acr: string, amr: list, challenge: string, client: record, consent_request_id: string, context: any, login_challenge: string, login_session_id: string, oidc_context: record, request_url: string, requested_access_token_audience: list, requested_scope: list, skip: bool, subject: string>, consent_request_id: string, context: any, grant_access_token_audience: list<string>, grant_scope: list<string>, handled_at: string, remember: bool, remember_for: int, session: record<access_token: any, id_token: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "login_session_id" $login_session_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/sessions/consent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revokes OAuth 2.0 Login Sessions by either a Subject or a SessionID
#
# DELETE /admin/oauth2/auth/sessions/login
# operationId: revokeOAuth2LoginSessions
export def "admin-oauth2-auth-sessions-login revokeOAuth2LoginSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subject: string # OAuth 2.0 Subject  The subject to revoke authentication sessions for.
  --sid: string # Login Session ID  The login session to revoke.
]: nothing -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subject" $subject "scalar") (serialize-qp "sid" $sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/auth/sessions/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Introspect OAuth2 Access and Refresh Tokens
#
# POST /admin/oauth2/introspect
# operationId: introspectOAuth2Token
export def "admin-oauth2-introspect introspectOAuth2Token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string # An optional, space separated list of required scopes. If the access token was not granted one of the scopes, the result of active will be false.
  --body-token: string # The string value of the token. For access tokens, this is the "access_token" value returned from the token endpoint defined in OAuth 2.0. For refresh tokens, this is the "refresh_token" value returned.
]: any -> record<active: bool, aud: list<string>, client_id: string, exp: int, ext: record, iat: int, iss: string, nbf: int, obfuscated_subject: string, scope: string, sub: string, token_type: string, token_use: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/oauth2/introspect")
  let body = {scope: $scope, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete OAuth 2.0 Access Tokens from specific OAuth 2.0 Client
#
# DELETE /admin/oauth2/tokens
# operationId: deleteOAuth2Token
export def "admin-oauth2-tokens delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # OAuth 2.0 Client ID
]: nothing -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/oauth2/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Trusted OAuth2 JWT Bearer Grant Type Issuers
#
# GET /admin/trust/grants/jwt-bearer/issuers
# operationId: listTrustedOAuth2JwtGrantIssuers
export def "admin-trust-grants-jwt-bearer-issuers listTrustedOAuth2JwtGrantIssuers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Items per Page  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --issuer: string # If optional "issuer" is supplied, only jwt-bearer grants with this issuer will be returned.
]: nothing -> table<allow_any_subject: bool, created_at: string, expires_at: string, id: string, issuer: string, public_key: record<kid: string, set: string>, scope: list<string>, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "issuer" $issuer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/trust/grants/jwt-bearer/issuers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trust OAuth2 JWT Bearer Grant Type Issuer
#
# POST /admin/trust/grants/jwt-bearer/issuers
# operationId: trustOAuth2JwtGrantIssuer
# --jwk shape: {alg: string, crv?: string, d?: string, dp?: string, dq?: string, e?: string, k?: string, kid: string, kty: string, n?: string, p?: string, q?: string, qi?: string, use: string, x?: string, x5c?: list, y?: string}
export def "admin-trust-grants-jwt-bearer-issuers trustOAuth2JwtGrantIssuer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-any-subject: string@bool-completer # The "allow_any_subject" indicates that the issuer is allowed to have any principal as the subject of the JWT.
  expires_at: string # The "expires_at" indicates, when grant will expire, so we will reject assertion from "issuer" targeting "subject". (format: date-time)
  issuer: string # The "issuer" identifies the principal that issued the JWT assertion (same as "iss" claim in JWT). (e.g. https://jwt-idp.example.com)
  jwk: record # shape: {alg: string, crv?: string, d?: string, dp?: string, dq?: string, e?: string, k?: string, kid: string, kty: string, n?: string, p?: string, q?: string, qi?: string, use: string, x?: string, x5c?: list, y?: string}
  scope: list # The "scope" contains list of scope values (as described in Section 3.3 of OAuth 2.0 [RFC6749]) (e.g. [openid, offline])
  --subject: string # The "subject" identifies the principal that is the subject of the JWT. (e.g. mike@example.com)
]: any -> record<allow_any_subject: bool, created_at: string, expires_at: string, id: string, issuer: string, public_key: record<kid: string, set: string>, scope: list<string>, subject: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/trust/grants/jwt-bearer/issuers")
  let body = {allow_any_subject: $allow_any_subject, expires_at: $expires_at, issuer: $issuer, jwk: $jwk, scope: $scope, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Trusted OAuth2 JWT Bearer Grant Type Issuer
#
# DELETE /admin/trust/grants/jwt-bearer/issuers/{id}
# operationId: deleteTrustedOAuth2JwtGrantIssuer
export def "admin-trust-grants-jwt-bearer-issuers delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: int, debug: string, details: any, id: string, message: string, reason: string, request: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/trust/grants/jwt-bearer/issuers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Trusted OAuth2 JWT Bearer Grant Type Issuer
#
# GET /admin/trust/grants/jwt-bearer/issuers/{id}
# operationId: getTrustedOAuth2JwtGrantIssuer
export def "admin-trust-grants-jwt-bearer-issuers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allow_any_subject: bool, created_at: string, expires_at: string, id: string, issuer: string, public_key: record<kid: string, set: string>, scope: list<string>, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/trust/grants/jwt-bearer/issuers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issues a Verifiable Credential
#
# POST /credentials
# operationId: createVerifiableCredential
# --proof shape: {jwt?: string, proof_type?: string}
export def "credentials createVerifiableCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string
  --proof: record # shape: {jwt?: string, proof_type?: string}
  --types: list
]: any -> record<credential_draft_00: string, format: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credentials")
  let body = {format: $format, proof: $proof, types: $types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check HTTP Server Status
#
# GET /health/alive
# operationId: isAlive
export def "health-alive isAlive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/alive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check HTTP Server and Database Status
#
# GET /health/ready
# operationId: isReady
export def "health-ready isReady" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/ready")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth 2.0 Authorize Endpoint
#
# GET /oauth2/auth
# operationId: oAuth2Authorize
export def "oauth2-auth oAuth2Authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The OAuth 2.0 Device Authorize Endpoint
#
# POST /oauth2/device/auth
# operationId: oAuth2DeviceFlow
export def "oauth2-device-auth oAuth2DeviceFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<device_code: string, expires_in: int, interval: int, user_code: string, verification_uri: string, verification_uri_complete: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/device/auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth 2.0 Device Verification Endpoint
#
# GET /oauth2/device/verify
# operationId: performOAuth2DeviceVerificationFlow
export def "oauth2-device-verify performOAuth2DeviceVerificationFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/device/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register OAuth2 Client using OpenID Dynamic Client Registration
#
# POST /oauth2/register
# operationId: createOidcDynamicClient
# --jwks shape: {keys?: list}
export def "oauth2-register createOidcDynamicClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token-strategy: string # OAuth 2.0 Access Token Strategy  AccessTokenStrategy is the strategy used to generate access tokens. Valid options are `jwt` and `opaque`. `jwt` is a bad idea, see https://www.ory.com/docs/oauth2-oidc/jwt-access-token Setting the strategy here overrides the global setting in `strategies.access_token`.
  --allowed-cors-origins: list # OAuth 2.0 Client Allowed CORS Origins  One or more URLs (scheme://host[:port]) which are allowed to make CORS requests to the /oauth/token endpoint. If this array is empty, the server's CORS origin configuration (`CORS_ALLOWED_ORIGINS`) will be used instead. If this array is set, the allowed origins are appended to the server's CORS origin configuration. Be aware that environment variable `CORS_ENABLED` MUST be set to `true` for this to work.
  --audience: list # OAuth 2.0 Client Audience  An allow-list defining the audiences this client is allowed to request tokens for. An audience limits the applicability of an OAuth 2.0 Access Token to, for example, certain API endpoints. The value is a list of URLs. URLs MUST NOT contain whitespaces. (e.g. https://mydomain.com/api/users, https://mydomain.com/api/posts)
  --authorization-code-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --backchannel-logout-session-required: string@bool-completer # OpenID Connect Back-Channel Logout Session Required  Boolean value specifying whether the RP requires that a sid (session ID) Claim be included in the Logout Token to identify the RP session with the OP when the backchannel_logout_uri is used. If omitted, the default value is false.
  --backchannel-logout-uri: string # OpenID Connect Back-Channel Logout URI  RP URL that will cause the RP to log itself out when sent a Logout Token by the OP.
  --client-credentials-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --client-id: string # OAuth 2.0 Client ID  The ID is immutable. If no ID is provided, a UUID4 will be generated.
  --client-name: string # OAuth 2.0 Client Name  The human-readable name of the client to be presented to the end-user during authorization.
  --client-secret: string # OAuth 2.0 Client Secret  The secret will be included in the create request as cleartext, and then never again. The secret is kept in hashed format and is not recoverable once lost.
  --client-secret-expires-at: int # OAuth 2.0 Client Secret Expires At  The field is currently not supported and its value is always 0. (format: int64)
  --client-uri: string # OAuth 2.0 Client URI  ClientURI is a URL string of a web page providing information about the client. If present, the server SHOULD display this URL to the end-user in a clickable fashion.
  --contacts: list # OAuth 2.0 Client Contact  An array of strings representing ways to contact people responsible for this client, typically email addresses. (e.g. help@example.org)
  --created-at: string # OAuth 2.0 Client Creation Date  CreatedAt returns the timestamp of the client's creation. (format: date-time)
  --device-authorization-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --frontchannel-logout-session-required: string@bool-completer # OpenID Connect Front-Channel Logout Session Required  Boolean value specifying whether the RP requires that iss (issuer) and sid (session ID) query parameters be included to identify the RP session with the OP when the frontchannel_logout_uri is used. If omitted, the default value is false.
  --frontchannel-logout-uri: string # OpenID Connect Front-Channel Logout URI  RP URL that will cause the RP to log itself out when rendered in an iframe by the OP. An iss (issuer) query parameter and a sid (session ID) query parameter MAY be included by the OP to enable the RP to validate the request and to determine which of the potentially multiple sessions is to be logged out; if either is included, both MUST be.
  --grant-types: list # OAuth 2.0 Client Grant Types  An array of OAuth 2.0 grant types the client is allowed to use. Can be one of:  Client Credentials Grant: `client_credentials` Authorization Code Grant: `authorization_code` OpenID Connect Implicit Grant (deprecated!): `implicit` Refresh Token Grant: `refresh_token` OAuth 2.0 Token Exchange: `urn:ietf:params:oauth:grant-type:jwt-bearer` OAuth 2.0 Device Code Grant: `urn:ietf:params:oauth:grant-type:device_code`
  --implicit-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --implicit-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --jwks: record # JSON Web Key Set — shape: {keys?: list}
  --jwks-uri: string # OAuth 2.0 Client JSON Web Key Set URL  URL for the Client's JSON Web Key Set [JWK] document. If the Client signs requests to the Server, it contains the signing key(s) the Server uses to validate signatures from the Client. The JWK Set MAY also contain the Client's encryption keys(s), which are used by the Server to encrypt responses to the Client. When both signing and encryption keys are made available, a use (Key Use) parameter value is REQUIRED for all keys in the referenced JWK Set to indicate each key's intended usage. Although some algorithms allow the same key to be used for both signatures and encryption, doing so is NOT RECOMMENDED, as it is less secure. The JWK x5c parameter MAY be used to provide X.509 representations of keys provided. When used, the bare key values MUST still be present and MUST match those in the certificate.
  --jwt-bearer-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --logo-uri: string # OAuth 2.0 Client Logo URI  A URL string referencing the client's logo.
  --metadata: any
  --owner: string # OAuth 2.0 Client Owner  Owner is a string identifying the owner of the OAuth 2.0 Client.
  --policy-uri: string # OAuth 2.0 Client Policy URI  PolicyURI is a URL string that points to a human-readable privacy policy document that describes how the deployment organization collects, uses, retains, and discloses personal data.
  --post-logout-redirect-uris: list # Allowed Post-Redirect Logout URIs  Array of URLs supplied by the RP to which it MAY request that the End-User's User Agent be redirected using the post_logout_redirect_uri parameter after a logout has been performed.
  --redirect-uris: list # OAuth 2.0 Client Redirect URIs  RedirectURIs is an array of allowed redirect urls for the client. (e.g. http://mydomain/oauth/callback)
  --refresh-token-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --registration-access-token: string # OpenID Connect Dynamic Client Registration Access Token  RegistrationAccessToken can be used to update, get, or delete the OAuth2 Client. It is sent when creating a client using Dynamic Client Registration.
  --registration-client-uri: string # OpenID Connect Dynamic Client Registration URL  RegistrationClientURI is the URL used to update, get, or delete the OAuth2 Client.
  --request-object-signing-alg: string # OpenID Connect Request Object Signing Algorithm  JWS [JWS] alg algorithm [JWA] that MUST be used for signing Request Objects sent to the OP. All Request Objects from this Client MUST be rejected, if not signed with this algorithm.
  --request-uris: list # OpenID Connect Request URIs  Array of request_uri values that are pre-registered by the RP for use at the OP. Servers MAY cache the contents of the files referenced by these URIs and not retrieve them at the time they are used in a request. OPs can require that request_uri values used be pre-registered with the require_request_uri_registration discovery parameter.
  --response-types: list # OAuth 2.0 Client Response Types  An array of the OAuth 2.0 response type strings that the client can use at the authorization endpoint. Can be one of:  Needed for OpenID Connect Implicit Grant: Returns ID Token to redirect URI: `id_token` Returns Access token redirect URI: `token` Needed for Authorization Code Grant: `code`
  --scope: string # OAuth 2.0 Client Scope  Scope is a string containing a space-separated list of scope values (as described in Section 3.3 of OAuth 2.0 [RFC6749]) that the client can use when requesting access tokens. (e.g. scope1 scope-2 scope.3 scope:4)
  --sector-identifier-uri: string # OpenID Connect Sector Identifier URI  URL using the https scheme to be used in calculating Pseudonymous Identifiers by the OP. The URL references a file with a single JSON array of redirect_uri values.
  --skip-consent: string@bool-completer # SkipConsent skips the consent screen for this client. This field can only be set from the admin API.
  --skip-logout-consent: string@bool-completer # SkipLogoutConsent skips the logout consent screen for this client. This field can only be set from the admin API.
  --subject-type: string # OpenID Connect Subject Type  The `subject_types_supported` Discovery parameter contains a list of the supported subject_type values for this server. Valid types include `pairwise` and `public`.
  --token-endpoint-auth-method: string # OAuth 2.0 Token Endpoint Authentication Method  Requested Client Authentication method for the Token Endpoint. The options are:  `client_secret_basic`: (default) Send `client_id` and `client_secret` as `application/x-www-form-urlencoded` encoded in the HTTP Authorization header. `client_secret_post`: Send `client_id` and `client_secret` as `application/x-www-form-urlencoded` in the HTTP body. `private_key_jwt`: Use JSON Web Tokens to authenticate the client. `none`: Used for public clients (native apps, mobile apps) which can not have secrets. (default: client_secret_basic)
  --token-endpoint-auth-signing-alg: string # OAuth 2.0 Token Endpoint Signing Algorithm  Requested Client Authentication signing algorithm for the Token Endpoint.
  --tos-uri: string # OAuth 2.0 Client Terms of Service URI  A URL string pointing to a human-readable terms of service document for the client that describes a contractual relationship between the end-user and the client that the end-user accepts when authorizing the client.
  --updated-at: string # OAuth 2.0 Client Last Update Date  UpdatedAt returns the timestamp of the last update. (format: date-time)
  --userinfo-signed-response-alg: string # OpenID Connect Request Userinfo Signed Response Algorithm  JWS alg algorithm [JWA] REQUIRED for signing UserInfo Responses. If this is specified, the response will be JWT [JWT] serialized, and signed using JWS. The default, if omitted, is for the UserInfo Response to return the Claims as a UTF-8 encoded JSON object using the application/json content-type.
]: any -> record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list<record>>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/register")
  let body = {access_token_strategy: $access_token_strategy, allowed_cors_origins: $allowed_cors_origins, audience: $audience, authorization_code_grant_access_token_lifespan: $authorization_code_grant_access_token_lifespan, authorization_code_grant_id_token_lifespan: $authorization_code_grant_id_token_lifespan, authorization_code_grant_refresh_token_lifespan: $authorization_code_grant_refresh_token_lifespan, backchannel_logout_session_required: $backchannel_logout_session_required, backchannel_logout_uri: $backchannel_logout_uri, client_credentials_grant_access_token_lifespan: $client_credentials_grant_access_token_lifespan, client_id: $client_id, client_name: $client_name, client_secret: $client_secret, client_secret_expires_at: $client_secret_expires_at, client_uri: $client_uri, contacts: $contacts, created_at: $created_at, device_authorization_grant_access_token_lifespan: $device_authorization_grant_access_token_lifespan, device_authorization_grant_id_token_lifespan: $device_authorization_grant_id_token_lifespan, device_authorization_grant_refresh_token_lifespan: $device_authorization_grant_refresh_token_lifespan, frontchannel_logout_session_required: $frontchannel_logout_session_required, frontchannel_logout_uri: $frontchannel_logout_uri, grant_types: $grant_types, implicit_grant_access_token_lifespan: $implicit_grant_access_token_lifespan, implicit_grant_id_token_lifespan: $implicit_grant_id_token_lifespan, jwks: $jwks, jwks_uri: $jwks_uri, jwt_bearer_grant_access_token_lifespan: $jwt_bearer_grant_access_token_lifespan, logo_uri: $logo_uri, metadata: $metadata, owner: $owner, policy_uri: $policy_uri, post_logout_redirect_uris: $post_logout_redirect_uris, redirect_uris: $redirect_uris, refresh_token_grant_access_token_lifespan: $refresh_token_grant_access_token_lifespan, refresh_token_grant_id_token_lifespan: $refresh_token_grant_id_token_lifespan, refresh_token_grant_refresh_token_lifespan: $refresh_token_grant_refresh_token_lifespan, registration_access_token: $registration_access_token, registration_client_uri: $registration_client_uri, request_object_signing_alg: $request_object_signing_alg, request_uris: $request_uris, response_types: $response_types, scope: $scope, sector_identifier_uri: $sector_identifier_uri, skip_consent: $skip_consent, skip_logout_consent: $skip_logout_consent, subject_type: $subject_type, token_endpoint_auth_method: $token_endpoint_auth_method, token_endpoint_auth_signing_alg: $token_endpoint_auth_signing_alg, tos_uri: $tos_uri, updated_at: $updated_at, userinfo_signed_response_alg: $userinfo_signed_response_alg} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete OAuth 2.0 Client using the OpenID Dynamic Client Registration Management Protocol
#
# DELETE /oauth2/register/{id}
# operationId: deleteOidcDynamicClient
export def "oauth2-register delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: int, debug: string, details: any, id: string, message: string, reason: string, request: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth2/register/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OAuth2 Client using OpenID Dynamic Client Registration
#
# GET /oauth2/register/{id}
# operationId: getOidcDynamicClient
export def "oauth2-register get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list<record>>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth2/register/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set OAuth2 Client using OpenID Dynamic Client Registration
#
# PUT /oauth2/register/{id}
# operationId: setOidcDynamicClient
# --jwks shape: {keys?: list}
export def "oauth2-register setOidcDynamicClient" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token-strategy: string # OAuth 2.0 Access Token Strategy  AccessTokenStrategy is the strategy used to generate access tokens. Valid options are `jwt` and `opaque`. `jwt` is a bad idea, see https://www.ory.com/docs/oauth2-oidc/jwt-access-token Setting the strategy here overrides the global setting in `strategies.access_token`.
  --allowed-cors-origins: list # OAuth 2.0 Client Allowed CORS Origins  One or more URLs (scheme://host[:port]) which are allowed to make CORS requests to the /oauth/token endpoint. If this array is empty, the server's CORS origin configuration (`CORS_ALLOWED_ORIGINS`) will be used instead. If this array is set, the allowed origins are appended to the server's CORS origin configuration. Be aware that environment variable `CORS_ENABLED` MUST be set to `true` for this to work.
  --audience: list # OAuth 2.0 Client Audience  An allow-list defining the audiences this client is allowed to request tokens for. An audience limits the applicability of an OAuth 2.0 Access Token to, for example, certain API endpoints. The value is a list of URLs. URLs MUST NOT contain whitespaces. (e.g. https://mydomain.com/api/users, https://mydomain.com/api/posts)
  --authorization-code-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --authorization-code-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --backchannel-logout-session-required: string@bool-completer # OpenID Connect Back-Channel Logout Session Required  Boolean value specifying whether the RP requires that a sid (session ID) Claim be included in the Logout Token to identify the RP session with the OP when the backchannel_logout_uri is used. If omitted, the default value is false.
  --backchannel-logout-uri: string # OpenID Connect Back-Channel Logout URI  RP URL that will cause the RP to log itself out when sent a Logout Token by the OP.
  --client-credentials-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --client-id: string # OAuth 2.0 Client ID  The ID is immutable. If no ID is provided, a UUID4 will be generated.
  --client-name: string # OAuth 2.0 Client Name  The human-readable name of the client to be presented to the end-user during authorization.
  --client-secret: string # OAuth 2.0 Client Secret  The secret will be included in the create request as cleartext, and then never again. The secret is kept in hashed format and is not recoverable once lost.
  --client-secret-expires-at: int # OAuth 2.0 Client Secret Expires At  The field is currently not supported and its value is always 0. (format: int64)
  --client-uri: string # OAuth 2.0 Client URI  ClientURI is a URL string of a web page providing information about the client. If present, the server SHOULD display this URL to the end-user in a clickable fashion.
  --contacts: list # OAuth 2.0 Client Contact  An array of strings representing ways to contact people responsible for this client, typically email addresses. (e.g. help@example.org)
  --created-at: string # OAuth 2.0 Client Creation Date  CreatedAt returns the timestamp of the client's creation. (format: date-time)
  --device-authorization-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --device-authorization-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --frontchannel-logout-session-required: string@bool-completer # OpenID Connect Front-Channel Logout Session Required  Boolean value specifying whether the RP requires that iss (issuer) and sid (session ID) query parameters be included to identify the RP session with the OP when the frontchannel_logout_uri is used. If omitted, the default value is false.
  --frontchannel-logout-uri: string # OpenID Connect Front-Channel Logout URI  RP URL that will cause the RP to log itself out when rendered in an iframe by the OP. An iss (issuer) query parameter and a sid (session ID) query parameter MAY be included by the OP to enable the RP to validate the request and to determine which of the potentially multiple sessions is to be logged out; if either is included, both MUST be.
  --grant-types: list # OAuth 2.0 Client Grant Types  An array of OAuth 2.0 grant types the client is allowed to use. Can be one of:  Client Credentials Grant: `client_credentials` Authorization Code Grant: `authorization_code` OpenID Connect Implicit Grant (deprecated!): `implicit` Refresh Token Grant: `refresh_token` OAuth 2.0 Token Exchange: `urn:ietf:params:oauth:grant-type:jwt-bearer` OAuth 2.0 Device Code Grant: `urn:ietf:params:oauth:grant-type:device_code`
  --implicit-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --implicit-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --jwks: record # JSON Web Key Set — shape: {keys?: list}
  --jwks-uri: string # OAuth 2.0 Client JSON Web Key Set URL  URL for the Client's JSON Web Key Set [JWK] document. If the Client signs requests to the Server, it contains the signing key(s) the Server uses to validate signatures from the Client. The JWK Set MAY also contain the Client's encryption keys(s), which are used by the Server to encrypt responses to the Client. When both signing and encryption keys are made available, a use (Key Use) parameter value is REQUIRED for all keys in the referenced JWK Set to indicate each key's intended usage. Although some algorithms allow the same key to be used for both signatures and encryption, doing so is NOT RECOMMENDED, as it is less secure. The JWK x5c parameter MAY be used to provide X.509 representations of keys provided. When used, the bare key values MUST still be present and MUST match those in the certificate.
  --jwt-bearer-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --logo-uri: string # OAuth 2.0 Client Logo URI  A URL string referencing the client's logo.
  --metadata: any
  --owner: string # OAuth 2.0 Client Owner  Owner is a string identifying the owner of the OAuth 2.0 Client.
  --policy-uri: string # OAuth 2.0 Client Policy URI  PolicyURI is a URL string that points to a human-readable privacy policy document that describes how the deployment organization collects, uses, retains, and discloses personal data.
  --post-logout-redirect-uris: list # Allowed Post-Redirect Logout URIs  Array of URLs supplied by the RP to which it MAY request that the End-User's User Agent be redirected using the post_logout_redirect_uri parameter after a logout has been performed.
  --redirect-uris: list # OAuth 2.0 Client Redirect URIs  RedirectURIs is an array of allowed redirect urls for the client. (e.g. http://mydomain/oauth/callback)
  --refresh-token-grant-access-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-id-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --refresh-token-grant-refresh-token-lifespan: string # Specify a time duration in milliseconds, seconds, minutes, hours.
  --registration-access-token: string # OpenID Connect Dynamic Client Registration Access Token  RegistrationAccessToken can be used to update, get, or delete the OAuth2 Client. It is sent when creating a client using Dynamic Client Registration.
  --registration-client-uri: string # OpenID Connect Dynamic Client Registration URL  RegistrationClientURI is the URL used to update, get, or delete the OAuth2 Client.
  --request-object-signing-alg: string # OpenID Connect Request Object Signing Algorithm  JWS [JWS] alg algorithm [JWA] that MUST be used for signing Request Objects sent to the OP. All Request Objects from this Client MUST be rejected, if not signed with this algorithm.
  --request-uris: list # OpenID Connect Request URIs  Array of request_uri values that are pre-registered by the RP for use at the OP. Servers MAY cache the contents of the files referenced by these URIs and not retrieve them at the time they are used in a request. OPs can require that request_uri values used be pre-registered with the require_request_uri_registration discovery parameter.
  --response-types: list # OAuth 2.0 Client Response Types  An array of the OAuth 2.0 response type strings that the client can use at the authorization endpoint. Can be one of:  Needed for OpenID Connect Implicit Grant: Returns ID Token to redirect URI: `id_token` Returns Access token redirect URI: `token` Needed for Authorization Code Grant: `code`
  --scope: string # OAuth 2.0 Client Scope  Scope is a string containing a space-separated list of scope values (as described in Section 3.3 of OAuth 2.0 [RFC6749]) that the client can use when requesting access tokens. (e.g. scope1 scope-2 scope.3 scope:4)
  --sector-identifier-uri: string # OpenID Connect Sector Identifier URI  URL using the https scheme to be used in calculating Pseudonymous Identifiers by the OP. The URL references a file with a single JSON array of redirect_uri values.
  --skip-consent: string@bool-completer # SkipConsent skips the consent screen for this client. This field can only be set from the admin API.
  --skip-logout-consent: string@bool-completer # SkipLogoutConsent skips the logout consent screen for this client. This field can only be set from the admin API.
  --subject-type: string # OpenID Connect Subject Type  The `subject_types_supported` Discovery parameter contains a list of the supported subject_type values for this server. Valid types include `pairwise` and `public`.
  --token-endpoint-auth-method: string # OAuth 2.0 Token Endpoint Authentication Method  Requested Client Authentication method for the Token Endpoint. The options are:  `client_secret_basic`: (default) Send `client_id` and `client_secret` as `application/x-www-form-urlencoded` encoded in the HTTP Authorization header. `client_secret_post`: Send `client_id` and `client_secret` as `application/x-www-form-urlencoded` in the HTTP body. `private_key_jwt`: Use JSON Web Tokens to authenticate the client. `none`: Used for public clients (native apps, mobile apps) which can not have secrets. (default: client_secret_basic)
  --token-endpoint-auth-signing-alg: string # OAuth 2.0 Token Endpoint Signing Algorithm  Requested Client Authentication signing algorithm for the Token Endpoint.
  --tos-uri: string # OAuth 2.0 Client Terms of Service URI  A URL string pointing to a human-readable terms of service document for the client that describes a contractual relationship between the end-user and the client that the end-user accepts when authorizing the client.
  --updated-at: string # OAuth 2.0 Client Last Update Date  UpdatedAt returns the timestamp of the last update. (format: date-time)
  --userinfo-signed-response-alg: string # OpenID Connect Request Userinfo Signed Response Algorithm  JWS alg algorithm [JWA] REQUIRED for signing UserInfo Responses. If this is specified, the response will be JWT [JWT] serialized, and signed using JWS. The default, if omitted, is for the UserInfo Response to return the Claims as a UTF-8 encoded JSON object using the application/json content-type.
]: any -> record<access_token_strategy: string, allowed_cors_origins: list<string>, audience: list<string>, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list<string>, created_at: string, device_authorization_grant_access_token_lifespan: string, device_authorization_grant_id_token_lifespan: string, device_authorization_grant_refresh_token_lifespan: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list<string>, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: record<keys: list<record>>, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list<string>, redirect_uris: list<string>, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list<string>, response_types: list<string>, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth2/register/($id)")
  let body = {access_token_strategy: $access_token_strategy, allowed_cors_origins: $allowed_cors_origins, audience: $audience, authorization_code_grant_access_token_lifespan: $authorization_code_grant_access_token_lifespan, authorization_code_grant_id_token_lifespan: $authorization_code_grant_id_token_lifespan, authorization_code_grant_refresh_token_lifespan: $authorization_code_grant_refresh_token_lifespan, backchannel_logout_session_required: $backchannel_logout_session_required, backchannel_logout_uri: $backchannel_logout_uri, client_credentials_grant_access_token_lifespan: $client_credentials_grant_access_token_lifespan, client_id: $client_id, client_name: $client_name, client_secret: $client_secret, client_secret_expires_at: $client_secret_expires_at, client_uri: $client_uri, contacts: $contacts, created_at: $created_at, device_authorization_grant_access_token_lifespan: $device_authorization_grant_access_token_lifespan, device_authorization_grant_id_token_lifespan: $device_authorization_grant_id_token_lifespan, device_authorization_grant_refresh_token_lifespan: $device_authorization_grant_refresh_token_lifespan, frontchannel_logout_session_required: $frontchannel_logout_session_required, frontchannel_logout_uri: $frontchannel_logout_uri, grant_types: $grant_types, implicit_grant_access_token_lifespan: $implicit_grant_access_token_lifespan, implicit_grant_id_token_lifespan: $implicit_grant_id_token_lifespan, jwks: $jwks, jwks_uri: $jwks_uri, jwt_bearer_grant_access_token_lifespan: $jwt_bearer_grant_access_token_lifespan, logo_uri: $logo_uri, metadata: $metadata, owner: $owner, policy_uri: $policy_uri, post_logout_redirect_uris: $post_logout_redirect_uris, redirect_uris: $redirect_uris, refresh_token_grant_access_token_lifespan: $refresh_token_grant_access_token_lifespan, refresh_token_grant_id_token_lifespan: $refresh_token_grant_id_token_lifespan, refresh_token_grant_refresh_token_lifespan: $refresh_token_grant_refresh_token_lifespan, registration_access_token: $registration_access_token, registration_client_uri: $registration_client_uri, request_object_signing_alg: $request_object_signing_alg, request_uris: $request_uris, response_types: $response_types, scope: $scope, sector_identifier_uri: $sector_identifier_uri, skip_consent: $skip_consent, skip_logout_consent: $skip_logout_consent, subject_type: $subject_type, token_endpoint_auth_method: $token_endpoint_auth_method, token_endpoint_auth_signing_alg: $token_endpoint_auth_signing_alg, tos_uri: $tos_uri, updated_at: $updated_at, userinfo_signed_response_alg: $userinfo_signed_response_alg} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke OAuth 2.0 Access or Refresh Token
#
# POST /oauth2/revoke
# operationId: revokeOAuth2Token
export def "oauth2-revoke revokeOAuth2Token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string
  --client-secret: string
  --body-token: string
]: any -> record<error: string, error_debug: string, error_description: string, error_hint: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/revoke")
  let body = {client_id: $client_id, client_secret: $client_secret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# OpenID Connect Front- and Back-channel Enabled Logout
#
# GET /oauth2/sessions/logout
# operationId: revokeOidcSession
export def "oauth2-sessions-logout revokeOidcSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/sessions/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The OAuth 2.0 Token Endpoint
#
# POST /oauth2/token
# operationId: oauth2TokenExchange
export def "oauth2-token oauth2TokenExchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string
  --code: string
  grant_type: string
  --redirect-uri: string
  --refresh-token: string
]: any -> record<access_token: string, expires_in: int, id_token: string, refresh_token: string, scope: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/token")
  let body = {client_id: $client_id, code: $code, grant_type: $grant_type, redirect_uri: $redirect_uri, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# OpenID Connect Userinfo
#
# GET /userinfo
# operationId: getOidcUserInfo
export def "userinfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<birthdate: string, email: string, email_verified: bool, family_name: string, gender: string, given_name: string, locale: string, middle_name: string, name: string, nickname: string, phone_number: string, phone_number_verified: bool, picture: string, preferred_username: string, profile: string, sub: string, updated_at: int, website: string, zoneinfo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return Running Software Version.
#
# GET /version
# operationId: getVersion
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
