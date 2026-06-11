# Auto-generated client for GitGuardian API v1.1.0
# Source: https://api.gitguardian.com/v1/openapi.json
# Auth: --token flag or $env.GITGUARDIAN_API_TOKEN

const BASE_URL = "https://api.gitguardian.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GITGUARDIAN_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def base-url-completer [] { ["https://api.gitguardian.com" "https://api.eu1.gitguardian.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ordering-completer [] { ["-created_at" "-expire_at" "-last_used_at" "-revoked_at" "created_at" "expire_at" "last_used_at" "revoked_at"] }
def grant-type-completer [] { ["authorization_code"] }
def token-endpoint-auth-method-completer [] { ["client_secret_post" "none"] }
def ordering-completer-1 [] { ["-date" "-ignored_at" "-resolved_at" "-risk_score" "date" "ignored_at" "resolved_at" "risk_score"] }
def ordering-completer-2 [] { ["-created_at" "-updated_at" "created_at" "updated_at"] }
def ordering-completer-3 [] { ["-created_at" "-last_login" "created_at" "last_login"] }
def ordering-completer-4 [] { ["-date" "date"] }
def X-Privacy-Mode-completer [] { ["false" "true"] }
def ordering-completer-5 [] { ["-date" "-id" "date" "id"] }
def severity-completer [] { ["critical" "high" "info" "low" "medium"] }
def ordering-completer-6 [] { ["-date" "-ignored_at" "-resolved_at" "date" "ignored_at" "resolved_at"] }
def ordering-completer-7 [] { ["-name" "name"] }
def ordering-completer-8 [] { ["-last_scan_date" "last_scan_date"] }
def visibility-completer [] { ["internal" "private" "public"] }
def source-criticality-completer [] { ["critical" "high" "low" "medium" "unknown"] }
def ordering-completer-9 [] { ["-id" "-name" "id" "name"] }
def ordering-completer-10 [] { ["-emails" "-github_login" "-is_active" "-name" "emails" "github_login" "is_active" "name"] }
def type-completer [] { ["aws-ecr-installation" "aws-honeytoken-organization" "aws-s3-installation" "azure-cr-installation" "azure-devops-installation" "bitbucket-cloud-workspace" "bitbucket-installation" "confluence-cloud-installation" "confluence-data-center-installation" "docker-hub-installation" "gerrit-installation" "github-installation" "gitlab-installation" "google-artifact-installation" "jfrog-artifact-installation" "jfrog-package-installation" "jira-cloud-installation" "jira-data-center-installation" "microsoft-onedrive-installation" "microsoft-teams-installation" "red-hat-quay-installation" "servicenow-installation" "servicenow-issue-tracking-config" "sharepoint-online-drive-installation" "slack-workspace"] }
def status-completer [] { ["fail" "pass" "warn"] }
def ordering-completer-11 [] { ["-started_at" "id" "started_at"] }
def status-completer-1 [] { ["active" "revoked" "triggered"] }
def type-completer-1 [] { ["AWS"] }
def ordering-completer-12 [] { ["-created_at" "-name" "-revoked_at" "-triggered_at" "created_at" "name" "revoked_at" "triggered_at"] }
def type-completer-2 [] { ["aws"] }
def method-completer [] { ["aws_config_profile" "aws_credentials"] }
def status-completer-2 [] { ["failed" "planted" "removed"] }
def ordering-completer-13 [] { ["-source_id" "source_id"] }
def ordering-completer-14 [] { ["-triggered_at" "triggered_at"] }
def status-completer-3 [] { ["allowed" "archived" "open"] }
def ordering-completer-15 [] { ["-created_at" "-tag" "created_at" "tag"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-tokens-self self-retrieve-api-token" } } | get name | first)
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

# Retrieve details of the current API token.
#
# GET /v1/api_tokens/self
# operationId: self-retrieve-api-token
export def "api-tokens-self self-retrieve-api-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, workspace_id: int, type: record, status: record, created_at: string, last_used_at: string, expire_at: string, revoked_at: string, member_id: int, creator_id: int, scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/api_tokens/self")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke the current API token.
#
# DELETE /v1/api_tokens/self
# operationId: self-delete-api-token
export def "api-tokens-self self-delete-api-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/api_tokens/self")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List API tokens.
#
# GET /v1/api_tokens
# operationId: list-api-tokens
export def "api-tokens list-api-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --status: string
  --member-id: int # Filter by member id. (e.g. 1)
  --creator-id: int # Filter by creator id. (e.g. 1)
  --scopes: string # e.g. incidents:read,api_tokens:read
  --search: string
  --ordering: string@ordering-completer # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<id: string, name: string, workspace_id: int, type: record, status: record, created_at: string, last_used_at: string, expire_at: string, revoked_at: string, member_id: int, creator_id: int, scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "creator_id" $creator_id "scalar") (serialize-qp "scopes" $scopes "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/api_tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve details of an API token.
#
# GET /v1/api_tokens/{token_id}
# operationId: retrieve-api-token
export def "api-tokens retrieve-api-token" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, workspace_id: int, type: record, status: record, created_at: string, last_used_at: string, expire_at: string, revoked_at: string, member_id: int, creator_id: int, scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/api_tokens/($token_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke an API token.
#
# DELETE /v1/api_tokens/{token_id}
# operationId: delete-api-token
export def "api-tokens delete-api-token" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/api_tokens/($token_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a JSON Web Token.
#
# POST /v1/auth/jwt
# operationId: public-jwt-create
export def "auth-jwt public-jwt-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  audience: string # Audience of the JWT. (e.g. https://api.hasmysecretleaked.com)
  --audience-type: string # Type of audience. (e.g. hmsl)
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/jwt")
  let body = {audience: $audience, audience_type: $audience_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exchange an authorization code for an access token.
#
# POST /v1/oauth/token
# operationId: public-oauth-token
export def "oauth-token public-oauth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  grant_type: string@grant-type-completer # Must be `authorization_code`. (e.g. authorization_code)
  code: string # The authorization code received from the authorization endpoint. (e.g. 4/0Adeu5BWqv9oS...)
  redirect_uri: string # Must match the `redirect_uri` used when requesting the authorization code.  (format: uri, e.g. https://app.example.com/callback)
  client_id: string # The OAuth client identifier. (e.g. gg_client_AbCdEf123456)
  --client-secret: string # The OAuth client secret. Required only for confidential clients (those registered with `token_endpoint_auth_method=client_secret_post`).  (e.g. gg_secret_AbCdEf123456)
  code_verifier: string # PKCE code verifier ([RFC 7636](https://www.rfc-editor.org/rfc/rfc7636)) whose hash matches the `code_challenge` sent to the authorization endpoint.  (e.g. dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk)
  --name: string # Optional name for the resulting personal access token. (e.g. My MCP client)
  --lifetime: int # Optional lifetime of the resulting personal access token, in days. `0` means it never expires.  (e.g. 30)
]: any -> record<access_token: string, token_type: string, expires_in: int, type: string, name: string, account_id: int, expire_at: string, scope: list<string>, key: string, expire_at_downsized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/token")
  let body = {grant_type: $grant_type, code: $code, redirect_uri: $redirect_uri, client_id: $client_id, client_secret: $client_secret, code_verifier: $code_verifier, name: $name, lifetime: $lifetime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Dynamically register an OAuth 2.0 client.
#
# POST /v1/oauth/register
# operationId: public-oauth-register
export def "oauth-register public-oauth-register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-name: string # Human-readable client name displayed on the consent screen. (nullable, e.g. My MCP client)
  redirect_uris: list # Allowed redirect URIs. At least one is required; each must be 2048 characters or fewer.  (e.g. [https://app.example.com/oauth/callback])
  --token-endpoint-auth-method: string@token-endpoint-auth-method-completer # Authentication method the client uses at the token endpoint. `none` is for public (PKCE-only) clients; `client_secret_post` is for confidential clients that send their secret in the token request body.  (default: none)
  --grant-types: list # Grant types the client may use. Only `authorization_code` is supported; omit to use the default.  (nullable, e.g. [authorization_code])
  --response-types: list # Response types the client may use at the authorization endpoint. Only `code` is supported; omit to use the default.  (nullable, e.g. [code])
  --scope: string # Space-separated list of scopes the client may request. Defaults to all scopes the workspace allows if omitted.  (nullable, e.g. scan incidents:read)
]: any -> record<client_id: string, client_name: string, redirect_uris: list<string>, grant_types: list<string>, response_types: list<string>, token_endpoint_auth_method: string, scope: string, client_id_issued_at: int, client_secret: string, client_secret_expires_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/register")
  let body = {client_name: $client_name, redirect_uris: $redirect_uris, token_endpoint_auth_method: $token_endpoint_auth_method, grant_types: $grant_types, response_types: $response_types, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List public keys used to sign JWTs.
#
# GET /v1/auth/jwks
# operationId: public-jwks
export def "auth-jwks public-jwks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<kid: string, n: string, e: string, kty: string, alg: string, use: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/jwks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OpenID Connect discovery document.
#
# GET /.well-known/openid-configuration
# operationId: public-oidc-well-known-configuration
export def "well-known-openid-configuration public-oidc-well-known-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<issuer: string, jwks_uri: string, subject_types_supported: list<string>, response_types_supported: list<string>, claims_supported: list<string>, id_token_signing_alg_values_supported: list<string>, scopes_supported: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/openid-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth 2.0 Authorization Server Metadata.
#
# GET /.well-known/oauth-authorization-server
# operationId: public-oauth-authorization-server-metadata
export def "well-known-oauth-authorization-server public-oauth-authorization-server-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<issuer: string, authorization_endpoint: string, token_endpoint: string, registration_endpoint: string, code_challenge_methods_supported: list<string>, grant_types_supported: list<string>, response_types_supported: list<string>, scopes_supported: list<string>, token_endpoint_auth_methods_supported: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/oauth-authorization-server")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List secret incidents
#
# GET /v1/incidents/secrets
# operationId: list-incidents
@deprecated --flag page
export def "incidents-secrets list-incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --triggered-at-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --triggered-at-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --assignee-email: string # e.g. eric@gitguardian.com
  --assignee-id: int # e.g. 4932
  --status: string
  --severity: string
  --validity: string
  --tags: string # e.g. FROM_HISTORICAL_SCAN,SENSITIVE_FILE
  --exclude-tags: string # e.g. TEST_FILE,FALSE_POSITIVE
  --custom-tags: string # e.g. d45a123f-b15d-4fea-abf6-ff2a8479de5b,55b349d7-8c3a-40c9-957c-e58f5c3a7391
  --custom-tag-key: string
  --custom-tag-value: string
  --ordering: string@ordering-completer-1 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --detector-group-name: string # e.g. slackbot_token
  --ignorer-id: int # e.g. 4932
  --ignorer-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --resolver-id: int # e.g. 4932
  --resolver-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --feedback: string@bool-completer
  --only-on-provider-archived-sources: string@bool-completer
  --risk-score-min: int # e.g. 80
  --risk-score-max: int # e.g. 30
]: nothing -> table<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: list<record>, feedback_list: list<record>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: list<record>, occurrences: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "triggered_at_before" $triggered_at_before "scalar") (serialize-qp "triggered_at_after" $triggered_at_after "scalar") (serialize-qp "assignee_email" $assignee_email "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "exclude_tags" $exclude_tags "scalar") (serialize-qp "custom_tags" $custom_tags "scalar") (serialize-qp "custom_tag_key" $custom_tag_key "scalar") (serialize-qp "custom_tag_value" $custom_tag_value "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "detector_group_name" $detector_group_name "scalar") (serialize-qp "ignorer_id" $ignorer_id "scalar") (serialize-qp "ignorer_api_token_id" $ignorer_api_token_id "scalar") (serialize-qp "resolver_id" $resolver_id "scalar") (serialize-qp "resolver_api_token_id" $resolver_api_token_id "scalar") (serialize-qp "feedback" $feedback "scalar") (serialize-qp "only_on_provider_archived_sources" $only_on_provider_archived_sources "scalar") (serialize-qp "risk_score_min" $risk_score_min "scalar") (serialize-qp "risk_score_max" $risk_score_max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/incidents/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a secret incident
#
# GET /v1/incidents/secrets/{incident_id}
# operationId: retrieve-incidents
export def "incidents-secrets retrieve-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-occurrences: int # Retrieve a number of occurrences of this incident. (default: 20)
]: nothing -> record<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: table<id: string, type: string, link: string>, occurrences: table<id: int, incident_id: int, kind: record, source: record, author_name: string, author_info: string, date: string, url: string, matches: list, tags: list, incident_name: string, sha: string, presence: string, filepath: string, change_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_occurrences" $with_occurrences "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a secret incident
#
# PATCH /v1/incidents/secrets/{incident_id}
# operationId: update-secret-incident
# --custom_tags item shape: {key?: string, value?: string}
# --public_exposure shape: {source_publicly_visible?: bool, public_incident_linked?: bool, leaked_outside_perimeter?: bool}
# --occurrences item shape: {matches?: list, tags?: list, presence?: string}
export def "incidents-secrets update-secret-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --severity: string # e.g. high
  --custom-tags: list # item shape: {key?: string, value?: string}
]: any -> record<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: table<id: string, type: string, link: string>, occurrences: table<id: int, incident_id: int, kind: record, source: record, author_name: string, author_info: string, date: string, url: string, matches: list, tags: list, incident_name: string, sha: string, presence: string, filepath: string, change_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)")
  let body = {severity: $severity, custom_tags: $custom_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve where a secret has been publicly leaked
#
# GET /v1/incidents/secrets/{incident_id}/leaks
# operationId: retrieve-incidents-leaks
export def "incidents-secrets-leaks retrieve-incidents-leaks" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<source: string, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/leaks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/assign
# operationId: assign-incident
export def "incidents-secrets-assign assign-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the assignee. (default: true)
  --email: string # email of the member to assign. This parameter is mutually exclusive with `member_id`.  (e.g. eric@gitguardian.com)
  --member-id: float # id of the member to assign. This parameter is mutually exclusive with `email`.  (e.g. 4295)
]: any -> record<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: table<id: string, type: string, link: string>, occurrences: table<id: int, incident_id: int, kind: record, source: record, author_name: string, author_info: string, date: string, url: string, matches: list, tags: list, incident_name: string, sha: string, presence: string, filepath: string, change_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/assign" $qp)
  let body = {email: $email, member_id: $member_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/unassign
# operationId: unassign-incident
export def "incidents-secrets-unassign unassign-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: table<id: string, type: string, link: string>, occurrences: table<id: int, incident_id: int, kind: record, source: record, author_name: string, author_info: string, date: string, url: string, matches: list, tags: list, incident_name: string, sha: string, presence: string, filepath: string, change_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/unassign")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/resolve
# operationId: resolve-incident
export def "incidents-secrets-resolve resolve-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret-revoked: string@bool-completer # e.g. true
]: any -> record<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: table<id: string, type: string, link: string>, occurrences: table<id: int, incident_id: int, kind: record, source: record, author_name: string, author_info: string, date: string, url: string, matches: list, tags: list, incident_name: string, sha: string, presence: string, filepath: string, change_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/resolve")
  let body = {secret_revoked: $secret_revoked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ignore a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/ignore
# operationId: ignore-incident
export def "incidents-secrets-ignore ignore-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ignore_reason: any # e.g. low_risk
]: any -> record<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: table<id: string, type: string, link: string>, occurrences: table<id: int, incident_id: int, kind: record, source: record, author_name: string, author_info: string, date: string, url: string, matches: list, tags: list, incident_name: string, sha: string, presence: string, filepath: string, change_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/ignore")
  let body = {ignore_reason: $ignore_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reopen a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/reopen
# operationId: reopen-incident
export def "incidents-secrets-reopen reopen-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: table<id: string, type: string, link: string>, occurrences: table<id: int, incident_id: int, kind: record, source: record, author_name: string, author_info: string, date: string, url: string, matches: list, tags: list, incident_name: string, sha: string, presence: string, filepath: string, change_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/reopen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Share a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/share
# operationId: share-incident
export def "incidents-secrets-share share-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-healing: string@bool-completer # Allow the developer to resolve or ignore through the share link (default: false, e.g. true)
  --feedback-collection: string@bool-completer # Allow the developer to submit their feedback through the share link (default: true, e.g. true)
  --lifespan: int # Lifespan, in hours, of the share link. If 0 or unset, a default value will be applied based on the workspace settings. (default: 0, e.g. 720)
]: any -> record<share_url: string, incident_id: int, feedback_collection: bool, auto_healing: bool, token: string, expire_at: string, revoked_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/share")
  let body = {auto_healing: $auto_healing, feedback_collection: $feedback_collection, lifespan: $lifespan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unshare a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/unshare
# operationId: unshare-incident
export def "incidents-secrets-unshare unshare-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/unshare")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Grant access to a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/grant_access
# DEPRECATED
# operationId: grant-access-incident
@deprecated
export def "incidents-secrets-grant-access grant-access-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Email address of a user or invitee. This parameter is mutually exclusive with `member_id`, `invitation_id` and `team_id`.
  --member-id: float # Id of a member. This parameter is mutually exclusive with `email`, `invitation_id` and `team_id`.
  --invitation-id: float # Id of an invitation. This parameter is mutually exclusive with `email`, `member_id` and `team_id`.
  --team-id: float # Id of a team, except for the global team. This parameter is mutually exclusive with `email`, `member_id` and `invitation_id`.
  --incident-permission: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/grant_access")
  let body = {email: $email, member_id: $member_id, invitation_id: $invitation_id, team_id: $team_id, incident_permission: $incident_permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke access to a secret incident
#
# POST /v1/incidents/secrets/{incident_id}/revoke_access
# DEPRECATED
# operationId: revoke-access-incident
@deprecated
export def "incidents-secrets-revoke-access revoke-access-incident" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Email address of a user or invitee. This parameter is mutually exclusive with `member_id`, `invitation_id` and `team_id`.
  --member-id: float # Id of a member. This parameter is mutually exclusive with `email`, `invitation_id` and `team_id`.
  --invitation-id: float # Id of an invitation. This parameter is mutually exclusive with `email`, `member_id` and `team_id`.
  --team-id: float # Id of a team, except for the global team. This parameter is mutually exclusive with `email`, `member_id` and `invitation_id`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/revoke_access")
  let body = {email: $email, member_id: $member_id, invitation_id: $invitation_id, team_id: $team_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List notes on a secret incident
#
# GET /v1/incidents/secrets/{incident_id}/notes
# operationId: list-incident-notes
@deprecated --flag page
export def "incidents-secrets-notes list-incident-notes" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --ordering: string@ordering-completer-2 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --member-id: int # Filter by member id. (e.g. 1)
  --search: string # e.g. I revoked this
]: nothing -> table<id: int, incident_id: int, member_id: int, api_token: string, api_token_id: string, created_at: string, updated_at: string, comment: string, issue_id: int, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a secret incident note
#
# POST /v1/incidents/secrets/{incident_id}/notes
# operationId: create-incident-note
export def "incidents-secrets-notes create-incident-note" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment: string # Content of the incident note (e.g. I revoked this secret)
]: any -> record<id: int, incident_id: int, member_id: int, api_token: string, api_token_id: string, created_at: string, updated_at: string, comment: string, issue_id: int, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/notes")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a secret incident note
#
# PATCH /v1/incidents/secrets/{incident_id}/notes/{note_id}
# operationId: update-incident-note
export def "incidents-secrets-notes update-incident-note" [
  incident_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment: string # Content of the incident note (e.g. I revoked this secret)
]: any -> record<id: int, incident_id: int, member_id: int, api_token: string, api_token_id: string, created_at: string, updated_at: string, comment: string, issue_id: int, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/notes/($note_id)")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a secret incident note
#
# DELETE /v1/incidents/secrets/{incident_id}/notes/{note_id}
# operationId: delete-incident-note
export def "incidents-secrets-notes delete-incident-note" [
  incident_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List members having access to a secret incident
#
# GET /v1/incidents/secrets/{incident_id}/members
# DEPRECATED
# operationId: list-incident-members
@deprecated
@deprecated --flag page
export def "incidents-secrets-members list-incident-members" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --member-id: float # e.g. 1234
  --incident-permission: string # e.g. can_view
  --role: string
  --search: string
]: nothing -> table<member_id: int, incident_id: int, incident_permission: string, id: int, name: string, email: string, role: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "incident_permission" $incident_permission "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List teams having access to a secret incident
#
# GET /v1/incidents/secrets/{incident_id}/teams
# DEPRECATED
# operationId: list-incident-teams
@deprecated
export def "incidents-secrets-teams list-incident-teams" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --team-id: float # e.g. 1234
  --incident-permission: string # e.g. can_view
]: nothing -> table<team_id: int, incident_id: int, incident_permission: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "incident_permission" $incident_permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List invitations having access to a Secret Incident
#
# GET /v1/incidents/secrets/{incident_id}/invitations
# DEPRECATED
# operationId: list-incident-invitations
@deprecated
export def "incidents-secrets-invitations list-incident-invitations" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --invitation-id: float # e.g. 1234
  --incident-permission: string # filter accesses with a specific permission. (e.g. can_view)
]: nothing -> table<invitation_id: int, incident_id: int, incident_permission: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "invitation_id" $invitation_id "scalar") (serialize-qp "incident_permission" $incident_permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the impacted perimeter of a secret incident
#
# GET /v1/incidents/secrets/{incident_id}/impacted_perimeter
# operationId: retrieve-incident-impacted-perimeter
export def "incidents-secrets-impacted-perimeter retrieve-incident-impacted-perimeter" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: record, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, sources: table<id: int, url: string, type: string, full_name: string, files: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/impacted_perimeter")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get vault information for a secret incident
#
# GET /v1/incidents/secrets/{incident_id}/vaults
# operationId: get-secret-incident-vaults
export def "incidents-secrets-vaults get-secret-incident-vaults" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<vault_type: string, vault_name: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/secrets/($incident_id)/vaults")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List members with access to a secret incident
#
# GET /v1/secret-incidents/{incident_id}/members
# operationId: list-secret-incident-member-access
export def "secret-incidents-members list-secret-incident-member-access" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --role: string
  --access-level: string
  --search: string
  --ordering: string@ordering-completer-3 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --direct-access: string@bool-completer # Filter on direct or indirect accesses.
]: nothing -> table<id: int, name: string, email: string, role: record, access_level: record, active: bool, created_at: string, last_login: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "access_level" $access_level "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "direct_access" $direct_access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/secret-incidents/($incident_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List teams with access to a secret incident
#
# GET /v1/secret-incidents/{incident_id}/teams
# operationId: list-secret-incident-team-access
export def "secret-incidents-teams list-secret-incident-team-access" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --search: string
  --direct-access: string@bool-completer # Filter on direct or indirect accesses.
]: nothing -> table<id: int, name: string, description: string, is_global: bool, gitguardian_url: string, external_provider_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "direct_access" $direct_access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/secret-incidents/($incident_id)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List invitations with access to a secret incident
#
# GET /v1/secret-incidents/{incident_id}/invitations
# operationId: list-secret-incident-invitation-access
export def "secret-incidents-invitations list-secret-incident-invitation-access" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --search: string
  --ordering: string@ordering-completer-4 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --direct-access: string@bool-completer # Filter on direct or indirect accesses.
]: nothing -> table<id: int, email: string, role: record, access_level: record, date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "direct_access" $direct_access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/secret-incidents/($incident_id)/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List secret occurrences
#
# GET /v1/occurrences/secrets
# operationId: list-occs
@deprecated --flag page
export def "occurrences-secrets list-occs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --source-id: int # Filter on the source ID. (e.g. 5523)
  --source-name: string # e.g. gitguardian/test-repository
  --source-type: string # e.g. github
  --incident-id: int # Filter by incident ID.
  --incident-assignee-id: int # Filter by incident assignee member ID.
  --presence: string
  --author-name: string # e.g. John Doe
  --author-info: string # e.g. john.doe@gitguardian.com
  --sha: string # e.g. fccebf0562698ab99dc10dcb2e864fc563b25ac4
  --filepath: string # e.g. myfile.txt
  --severity: string # e.g. critical,high
  --status: string # e.g. TRIGGERED,ASSIGNED
  --validity: string # e.g. valid,invalid
  --tags: string # e.g. FROM_HISTORICAL_SCAN,SENSITIVE_FILE
  --exclude-tags: string # e.g. TEST_FILE,FALSE_POSITIVE
  --ordering: string@ordering-completer-4 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<id: int, incident_id: int, kind: record, source: record<id: int, url: string, type: string, full_name: string, health: record, default_branch: string, default_branch_head: string, open_incidents_count: int, closed_incidents_count: int, secret_incidents_breakdown: record, visibility: string, external_id: string, source_criticality: string, last_scan: record, monitored: bool, provider_metadata: record, deleted: bool>, author_name: string, author_info: string, date: string, url: string, matches: list<record>, tags: list<string>, incident_name: string, sha: string, presence: string, filepath: string, change_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "source_id" $source_id "scalar") (serialize-qp "source_name" $source_name "scalar") (serialize-qp "source_type" $source_type "scalar") (serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "incident_assignee_id" $incident_assignee_id "scalar") (serialize-qp "presence" $presence "scalar") (serialize-qp "author_name" $author_name "scalar") (serialize-qp "author_info" $author_info "scalar") (serialize-qp "sha" $sha "scalar") (serialize-qp "filepath" $filepath "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "exclude_tags" $exclude_tags "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/occurrences/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List severity rules
#
# GET /v1/severity-rules
# operationId: list-severity-rules
export def "severity-rules list-severity-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, description: string, severity: string, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/severity-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create code fix requests
#
# POST /v1/code-fix-requests
# operationId: create-code-fix-request
# --locations item shape: {issue_id: int, location_ids: list}
export def "code-fix-requests create-code-fix-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  locations: list # List of issues with their location IDs to fix — item shape: {issue_id: int, location_ids: list}
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/code-fix-requests")
  let body = {locations: $locations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List public secret incidents
#
# GET /v1/public-incidents/secrets
# operationId: list-public-incidents
export def "public-incidents-secrets list-public-incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --triggered-at-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --triggered-at-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --assignee-email: string # e.g. eric@gitguardian.com
  --assignee-id: int # e.g. 4932
  --status: string
  --severity: string
  --validity: string
  --tags: string # e.g. FROM_HISTORICAL_SCAN,INTERNALLY_LEAKED
  --custom-tags: string # e.g. d45a123f-b15d-4fea-abf6-ff2a8479de5b,55b349d7-8c3a-40c9-957c-e58f5c3a7391
  --custom-tag-key: string
  --custom-tag-value: string
  --ordering: string@ordering-completer-1 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --detector-group-name: string # e.g. slackbot_token
  --ignorer-id: int # e.g. 4932
  --ignorer-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --resolver-id: int # e.g. 4932
  --resolver-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --feedback: string@bool-completer
  --declarative-secret-status: string
  --risk-score-min: int # e.g. 80
  --risk-score-max: int # e.g. 30
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
]: nothing -> table<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: list<record>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: list<record>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "triggered_at_before" $triggered_at_before "scalar") (serialize-qp "triggered_at_after" $triggered_at_after "scalar") (serialize-qp "assignee_email" $assignee_email "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "custom_tags" $custom_tags "scalar") (serialize-qp "custom_tag_key" $custom_tag_key "scalar") (serialize-qp "custom_tag_value" $custom_tag_value "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "detector_group_name" $detector_group_name "scalar") (serialize-qp "ignorer_id" $ignorer_id "scalar") (serialize-qp "ignorer_api_token_id" $ignorer_api_token_id "scalar") (serialize-qp "resolver_id" $resolver_id "scalar") (serialize-qp "resolver_api_token_id" $resolver_api_token_id "scalar") (serialize-qp "feedback" $feedback "scalar") (serialize-qp "declarative_secret_status" $declarative_secret_status "scalar") (serialize-qp "risk_score_min" $risk_score_min "scalar") (serialize-qp "risk_score_max" $risk_score_max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/public-incidents/secrets" $qp)
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a public secret incident
#
# GET /v1/public-incidents/secrets/{incident_id}
# operationId: retrieve-public-incidents
export def "public-incidents-secrets retrieve-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
]: nothing -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)")
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List public secret occurrences
#
# GET /v1/public-incidents/secrets/{incident_id}/occurrences
# operationId: list-public-secret-occurrences
export def "public-incidents-secrets-occurrences list-public-secret-occurrences" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --source-id: int # Filter on the source ID. (e.g. 5523)
  --presence: string
  --sha: string # e.g. fccebf0562
  --filepath: string # e.g. myfile.txt
  --attachment-reason: string # e.g. by_dev_from_perimeter,on_github_org_in_perimeter
  --severity: string # e.g. critical,high
  --status: string # e.g. TRIGGERED,ASSIGNED
  --validity: string # e.g. valid,invalid,no_checker
  --tags: string # e.g. FROM_HISTORICAL_SCAN,INTERNALLY_LEAKED
  --ordering: string@ordering-completer-5 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<id: int, incident_id: int, date: string, filepath: string, kind: string, presence: string, matches: list<record>, tags: list<string>, sha: string, url: string, source: record<id: int, url: string, type: string, full_name: string, health: record, default_branch: string, default_branch_head: string, open_incidents_count: int, closed_incidents_count: int, secret_incidents_breakdown: record, visibility: string, external_id: string, source_criticality: string, last_scan: record, monitored: bool, provider_metadata: record, deleted: bool>, actor: record<id: int, type: string, name: string, email: string, url: string>, attachment_reasons: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "source_id" $source_id "scalar") (serialize-qp "presence" $presence "scalar") (serialize-qp "sha" $sha "scalar") (serialize-qp "filepath" $filepath "scalar") (serialize-qp "attachment_reason" $attachment_reason "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/occurrences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a public secret occurrence
#
# GET /v1/public-incidents/secrets/{incident_id}/occurrences/{occurrence_id}
# operationId: retrieve-public-secret-occurrence
export def "public-incidents-secrets-occurrences retrieve-public-secret-occurrence" [
  incident_id: int
  occurrence_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, incident_id: int, date: string, filepath: string, kind: string, presence: string, matches: table<name: string, indice_start: int, indice_end: int, pre_line_start: int, pre_line_end: int, post_line_start: int, post_line_end: int>, tags: list<string>, sha: string, url: string, source: record<id: int, url: string, type: string, full_name: string, health: record, default_branch: string, default_branch_head: string, open_incidents_count: int, closed_incidents_count: int, secret_incidents_breakdown: record<open_secret_incidents: record, closed_secret_incidents: record>, visibility: string, external_id: string, source_criticality: string, last_scan: record, monitored: bool, provider_metadata: record<archived: bool>, deleted: bool>, actor: record<id: int, type: string, name: string, email: string, url: string>, attachment_reasons: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/occurrences/($occurrence_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/resolve
# operationId: resolve-public-incidents
export def "public-incidents-secrets-resolve resolve-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resolve_reason: string # Comma-separated list of reasons for resolving the incident (e.g. revoked)
]: any -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/resolve")
  let body = {resolve_reason: $resolve_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ignore a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/ignore
# operationId: ignore-public-incidents
export def "public-incidents-secrets-ignore ignore-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ignore_reason: string # Comma-separated list of reasons for ignoring the incident (e.g. test_credential,ignore_actor)
]: any -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/ignore")
  let body = {ignore_reason: $ignore_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reopen a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/reopen
# operationId: reopen-public-incidents
export def "public-incidents-secrets-reopen reopen-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/reopen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/assign
# operationId: assign-public-incidents
export def "public-incidents-secrets-assign assign-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the assignee. (default: true)
  --email: string # email of the member to assign. This parameter is mutually exclusive with `member_id`.  (e.g. eric@gitguardian.com)
  --member-id: float # id of the member to assign. This parameter is mutually exclusive with `email`.  (e.g. 4295)
]: any -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/assign" $qp)
  let body = {email: $email, member_id: $member_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/unassign
# operationId: unassign-public-incidents
export def "public-incidents-secrets-unassign unassign-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/unassign")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Share a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/share
# operationId: share-public-incidents
export def "public-incidents-secrets-share share-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feedback-collection: string@bool-completer # Whether to allow feedback collection on the shared incident. (default: false)
  --auto-healing: string@bool-completer # Whether to allow auto-healing actions on the shared incident. (default: false)
  --lifespan: float # The lifespan of the share link in hours. (e.g. 24)
]: any -> record<share_url: string, incident_id: int, feedback_collection: bool, auto_healing: bool, token: string, expire_at: string, revoked_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/share")
  let body = {feedback_collection: $feedback_collection, auto_healing: $auto_healing, lifespan: $lifespan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unshare a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/unshare
# operationId: unshare-public-incidents
export def "public-incidents-secrets-unshare unshare-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/unshare")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set severity of a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/set_severity
# operationId: set-severity-public-incidents
export def "public-incidents-secrets-set-severity set-severity-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  severity: string@severity-completer # The severity level to set (e.g. high)
]: any -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/set_severity")
  let body = {severity: $severity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set custom tags of a public secret incident
#
# POST /v1/public-incidents/secrets/{incident_id}/set_custom_tags
# operationId: set-custom-tags-public-incidents
# --custom_tags item shape: {key: string, value: string}
export def "public-incidents-secrets-set-custom-tags set-custom-tags-public-incidents" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_tags: list # List of custom tags to set — item shape: {key: string, value: string}
]: any -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, date: string, secret_id: int, secret_hash: string, hmsl_hash: string, occurrences_count: int, status: record, triggered_at: string, ignored_at: string, ignore_reason: string, ignorer_id: int, ignorer_api_token_id: string, resolved_at: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, validity: string, severity: string, assignee_id: int, assignee_email: string, share_url: string, feedback_list: table<created_at: string, updated_at: string, member_id: int, email: string, answers: list>, declarative_secret_status: string, resolve_reason: string, gitguardian_url: string, tags: list<string>, custom_tags: table<id: string, key: string, value: string>, risk_score: int, severity_rule_id: int, incident_name: string, is_vaulted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/set_custom_tags")
  let body = {custom_tags: $custom_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List notes on a public secret incident
#
# GET /v1/public-incidents/secrets/{incident_id}/notes
# operationId: list-public-incident-notes
export def "public-incidents-secrets-notes list-public-incident-notes" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --ordering: string@ordering-completer-2 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --member-id: int # Filter by member id. (e.g. 1)
  --search: string # e.g. I revoked this
]: nothing -> table<id: int, incident_id: int, member_id: int, api_token_id: string, created_at: string, updated_at: string, comment: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a public secret incident note
#
# POST /v1/public-incidents/secrets/{incident_id}/notes
# operationId: create-public-incident-note
export def "public-incidents-secrets-notes create-public-incident-note" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment: string # Content of the incident note (e.g. I revoked this secret)
]: any -> record<id: int, incident_id: int, member_id: int, api_token_id: string, created_at: string, updated_at: string, comment: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/notes")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a public secret incident note
#
# PATCH /v1/public-incidents/secrets/{incident_id}/notes/{note_id}
# operationId: update-public-incident-note
export def "public-incidents-secrets-notes update-public-incident-note" [
  incident_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment: string # Content of the incident note (e.g. I revoked this secret)
]: any -> record<id: int, incident_id: int, member_id: int, api_token_id: string, created_at: string, updated_at: string, comment: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/notes/($note_id)")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a public secret incident note
#
# DELETE /v1/public-incidents/secrets/{incident_id}/notes/{note_id}
# operationId: delete-public-incident-note
export def "public-incidents-secrets-notes delete-public-incident-note" [
  incident_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get vault information for a public secret incident
#
# GET /v1/public-incidents/secrets/{incident_id}/vaults
# operationId: get-public-secret-incident-vaults
export def "public-incidents-secrets-vaults get-public-secret-incident-vaults" [
  incident_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<vault_type: string, vault_name: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public-incidents/secrets/($incident_id)/vaults")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List invitations
#
# GET /v1/invitations
# operationId: list-invitations
export def "invitations list-invitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --search: string
  --ordering: string@ordering-completer-4 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<id: int, email: string, role: record, access_level: record, date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invitation
#
# POST /v1/invitations
# operationId: create-invitations
@deprecated --flag role
export def "invitations create-invitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to send an email to the invitee with a link to accept the invitation.
  email: string # email of the user to invite.  (e.g. eric@gitguardian.com)
  --role: any # Use `access_level` instead.  (DEPRECATED, default: member, e.g. manager)
  --access-level: any # default: member, e.g. manager
]: any -> record<id: int, email: string, role: record, access_level: record, date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/invitations" $qp)
  let body = {email: $email, role: $role, access_level: $access_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an invitation
#
# GET /v1/invitations/{invitation_id}
# operationId: retrieve-invitation
export def "invitations retrieve-invitation" [
  invitation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, email: string, role: record, access_level: record, date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/invitations/($invitation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an invitation
#
# DELETE /v1/invitations/{invitation_id}
# operationId: delete-invitation
export def "invitations delete-invitation" [
  invitation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/invitations/($invitation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend an invitation
#
# POST /v1/invitations/{invitation_id}/resend
# operationId: resend-invitation
export def "invitations-resend resend-invitation" [
  invitation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/invitations/($invitation_id)/resend")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check invitation permission for a resource
#
# GET /v1/invitations/{invitation_id}/{resource_type}/{resource_id}
# operationId: get-invitation-resource-access
export def "invitations get-invitation-resource-access" [
  invitation_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invitation_id: int, resource_id: int, resource_type: string, permission: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/invitations/($invitation_id)/($resource_type)/($resource_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Give an invitation access to a resource
#
# PUT /v1/invitations/{invitation_id}/{resource_type}/{resource_id}
# operationId: set-invitation-resource-access
export def "invitations set-invitation-resource-access" [
  invitation_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string # e.g. can_edit
]: any -> record<invitation_id: int, resource_id: int, resource_type: string, permission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/invitations/($invitation_id)/($resource_type)/($resource_id)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke an invitation's access to a resource
#
# DELETE /v1/invitations/{invitation_id}/{resource_type}/{resource_id}
# operationId: revoke-invitation-resource-access
export def "invitations revoke-invitation-resource-access" [
  invitation_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string # e.g. can_edit
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/invitations/($invitation_id)/($resource_type)/($resource_id)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List secret incidents an invitation has access to
#
# GET /v1/invitations/{invitation_id}/secret-incidents
# operationId: list-invitation-secret-incident-access
@deprecated --flag page
export def "invitations-secret-incidents list-invitation-secret-incident-access" [
  invitation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --assignee-email: string # e.g. eric@gitguardian.com
  --assignee-id: int # e.g. 4932
  --status: string
  --severity: string
  --validity: string
  --tags: string # e.g. FROM_HISTORICAL_SCAN,SENSITIVE_FILE
  --ordering: string@ordering-completer-6 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --detector-group-name: string # e.g. slackbot_token
  --ignorer-id: int # e.g. 4932
  --ignorer-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --resolver-id: int # e.g. 4932
  --resolver-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --feedback: string@bool-completer
  --only-on-provider-archived-sources: string@bool-completer
]: nothing -> table<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: list<record>, feedback_list: list<record>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: list<record>, occurrences: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "assignee_email" $assignee_email "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "detector_group_name" $detector_group_name "scalar") (serialize-qp "ignorer_id" $ignorer_id "scalar") (serialize-qp "ignorer_api_token_id" $ignorer_api_token_id "scalar") (serialize-qp "resolver_id" $resolver_id "scalar") (serialize-qp "resolver_api_token_id" $resolver_api_token_id "scalar") (serialize-qp "feedback" $feedback "scalar") (serialize-qp "only_on_provider_archived_sources" $only_on_provider_archived_sources "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/invitations/($invitation_id)/secret-incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List members
#
# GET /v1/members
# operationId: list-members
@deprecated --flag page
@deprecated --flag role
export def "members list-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --role: string # DEPRECATED
  --access-level: string
  --active: string@bool-completer
  --search: string
  --ordering: string@ordering-completer-3 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<id: int, name: string, email: string, role: record, access_level: record, active: bool, created_at: string, last_login: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "access_level" $access_level "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a member
#
# GET /v1/members/{member_id}
# operationId: retrieve-member
export def "members retrieve-member" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, email: string, role: record, access_level: record, active: bool, created_at: string, last_login: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a member
#
# DELETE /v1/members/{member_id}
# operationId: delete-member
export def "members delete-member" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the member about the removal. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/members/($member_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a member
#
# PATCH /v1/members/{member_id}
# operationId: update-member
@deprecated --flag role
export def "members update-member" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the member about the update. (default: true)
  --role: any # DEPRECATED
  --access-level: any
  --active: string@bool-completer # Whether this member is activated on the workspace. (e.g. true)
]: any -> record<id: int, name: string, email: string, role: record, access_level: record, active: bool, created_at: string, last_login: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/members/($member_id)" $qp)
  let body = {role: $role, access_level: $access_level, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List teams of a member
#
# GET /v1/members/{member_id}/teams
# operationId: list-member-teams
export def "members-teams list-member-teams" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --search: string
  --is-global: string@bool-completer
]: nothing -> table<id: int, name: string, description: string, is_global: bool, gitguardian_url: string, external_provider_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "is_global" $is_global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/members/($member_id)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check member permission for a resource
#
# GET /v1/members/{member_id}/{resource_type}/{resource_id}
# operationId: get-member-resource-access
export def "members get-member-resource-access" [
  member_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<member_id: int, resource_id: int, resource_type: string, permission: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/members/($member_id)/($resource_type)/($resource_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Give a member access to a resource
#
# PUT /v1/members/{member_id}/{resource_type}/{resource_id}
# operationId: set-member-resource-access
export def "members set-member-resource-access" [
  member_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the member about the access. (default: true)
  --permission: string # e.g. can_edit
]: any -> record<member_id: int, resource_id: int, resource_type: string, permission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/members/($member_id)/($resource_type)/($resource_id)" $qp)
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke a member's access to a resource
#
# DELETE /v1/members/{member_id}/{resource_type}/{resource_id}
# operationId: revoke-member-resource-access
export def "members revoke-member-resource-access" [
  member_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string # e.g. can_edit
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/members/($member_id)/($resource_type)/($resource_id)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List secret incidents a member has access to
#
# GET /v1/members/{member_id}/secret-incidents
# operationId: list-member-secret-incident-access
@deprecated --flag page
export def "members-secret-incidents list-member-secret-incident-access" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --assignee-email: string # e.g. eric@gitguardian.com
  --assignee-id: int # e.g. 4932
  --status: string
  --severity: string
  --validity: string
  --tags: string # e.g. FROM_HISTORICAL_SCAN,SENSITIVE_FILE
  --ordering: string@ordering-completer-6 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --detector-group-name: string # e.g. slackbot_token
  --ignorer-id: int # e.g. 4932
  --ignorer-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --resolver-id: int # e.g. 4932
  --resolver-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --feedback: string@bool-completer
  --only-on-provider-archived-sources: string@bool-completer
]: nothing -> table<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: list<record>, feedback_list: list<record>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: list<record>, occurrences: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "assignee_email" $assignee_email "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "detector_group_name" $detector_group_name "scalar") (serialize-qp "ignorer_id" $ignorer_id "scalar") (serialize-qp "ignorer_api_token_id" $ignorer_api_token_id "scalar") (serialize-qp "resolver_id" $resolver_id "scalar") (serialize-qp "resolver_api_token_id" $resolver_api_token_id "scalar") (serialize-qp "feedback" $feedback "scalar") (serialize-qp "only_on_provider_archived_sources" $only_on_provider_archived_sources "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/members/($member_id)/secret-incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a member's email settings
#
# GET /v1/members/{member_id}/email_notifications
# operationId: retrieve-member-email-settings
export def "members-email-notifications retrieve-member-email-settings" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<private_issue_realtime: record<is_active: bool, settings: record<vcs_author_only: bool, issue_type: string>>, weekly_recap: record<is_active: bool, settings: record>, private_issue_access: record<is_active: bool, settings: record>, private_issue_feedback_submitted: record<is_active: bool, settings: record>, private_issue_ignored_with_valid_secret: record<is_active: bool, settings: record>, health_checks: record<is_active: bool, settings: record>, team_updates: record<is_active: bool, settings: record>, historical_scan_completion: record<is_active: bool, settings: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/members/($member_id)/email_notifications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a member's email settings
#
# PATCH /v1/members/{member_id}/email_notifications
# operationId: update-member-email-settings
# --private_issue_realtime shape: {is_active?: bool, settings?: record}
# --weekly_recap shape: {is_active?: bool, settings?: record}
# --private_issue_access shape: {is_active?: bool, settings?: record}
# --private_issue_feedback_submitted shape: {is_active?: bool, settings?: record}
# --private_issue_ignored_with_valid_secret shape: {is_active?: bool, settings?: record}
# --health_checks shape: {is_active?: bool, settings?: record}
# --team_updates shape: {is_active?: bool, settings?: record}
# --historical_scan_completion shape: {is_active?: bool, settings?: record}
export def "members-email-notifications update-member-email-settings" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the member about the update. (default: true)
  --private-issue-realtime: record # shape: {is_active?: bool, settings?: record}
  --weekly-recap: record # shape: {is_active?: bool, settings?: record}
  --private-issue-access: record # shape: {is_active?: bool, settings?: record}
  --private-issue-feedback-submitted: record # shape: {is_active?: bool, settings?: record}
  --private-issue-ignored-with-valid-secret: record # shape: {is_active?: bool, settings?: record}
  --health-checks: record # shape: {is_active?: bool, settings?: record}
  --team-updates: record # shape: {is_active?: bool, settings?: record}
  --historical-scan-completion: record # shape: {is_active?: bool, settings?: record}
]: any -> record<private_issue_realtime: record<is_active: bool, settings: record<vcs_author_only: bool, issue_type: string>>, weekly_recap: record<is_active: bool, settings: record>, private_issue_access: record<is_active: bool, settings: record>, private_issue_feedback_submitted: record<is_active: bool, settings: record>, private_issue_ignored_with_valid_secret: record<is_active: bool, settings: record>, health_checks: record<is_active: bool, settings: record>, team_updates: record<is_active: bool, settings: record>, historical_scan_completion: record<is_active: bool, settings: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/members/($member_id)/email_notifications" $qp)
  let body = {private_issue_realtime: $private_issue_realtime, weekly_recap: $weekly_recap, private_issue_access: $private_issue_access, private_issue_feedback_submitted: $private_issue_feedback_submitted, private_issue_ignored_with_valid_secret: $private_issue_ignored_with_valid_secret, health_checks: $health_checks, team_updates: $team_updates, historical_scan_completion: $historical_scan_completion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Content scan
#
# POST /v1/scan
# operationId: content_scan
export def "scan scan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filename: string # e.g. .env
  document: string # e.g.  import urllib.request url = 'http://jen_barber:correcthorsebatterystaple@cake.gitguardian.com/isreal.json' response = urllib.request.urlopen(url) consume(response.read())
]: any -> record<policy_break_count: int, policies: list<string>, policy_breaks: table<type: string, policy: string, validity: string, matches: list, known_secret: bool, incident_url: string>, is_diff: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scan")
  let body = {filename: $filename, document: $document} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Multiple content scan
#
# POST /v1/multiscan
# operationId: multiple_scan
export def "multiscan scan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<policy_break_count: int, policies: list<string>, policy_breaks: list<record>, is_diff: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/multiscan")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Scan content and create incidents
#
# POST /v1/scan/create-incidents
# operationId: scan_create_incidents
# --documents item shape: {filename: string, document: string, location?: record}
export def "scan-create-incidents incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_uuid: string # Unique identifier for the custom source (e.g. 550e8400-e29b-41d4-a716-446655440000)
  documents: list # Array of documents to be processed — item shape: {filename: string, document: string, location?: record}
]: any -> record<policy_break_count: int, policies: list<string>, policy_breaks: table<type: string, policy: string, validity: string, matches: list, known_secret: bool, incident_url: string>, is_diff: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scan/create-incidents")
  let body = {source_uuid: $source_uuid, documents: $documents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List secret detectors
#
# GET /v1/secret_detectors
# operationId: list-secret-detectors
export def "secret-detectors list-secret-detectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --is-active: string@bool-completer # e.g. true
  --type: string # e.g. generic
  --search: string # e.g. aws
  --ordering: string@ordering-completer-7 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<name: string, display_name: string, type: string, category: string, is_active: bool, scans_code_only: bool, checkable: bool, use_with_validity_check_disabled: bool, frequency: float, removed_at: string, open_incidents_count: int, ignored_incidents_count: int, resolved_incidents_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/secret_detectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a secret detector
#
# GET /v1/secret_detectors/{detector_name}
# operationId: get-secret-detector
export def "secret-detectors get-secret-detector" [
  detector_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, display_name: string, type: string, category: string, is_active: bool, scans_code_only: bool, checkable: bool, use_with_validity_check_disabled: bool, frequency: float, removed_at: string, open_incidents_count: int, ignored_incidents_count: int, resolved_incidents_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/secret_detectors/($detector_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a secret value
#
# GET /v1/secrets/{secret_id}
# operationId: get-secret-detail
export def "secrets get-secret-detail" [
  secret_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
]: nothing -> record<id: int, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, matches: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/secrets/($secret_id)")
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Quota overview
#
# GET /v1/quotas
# operationId: quotas
export def "quotas quotas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<content: record<count: int, limit: int, remaining: int, since: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sources
#
# GET /v1/sources
# operationId: list-sources
@deprecated --flag page
export def "sources list-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --search: string # e.g. test-repository
  --last-scan-status: string
  --health: string
  --type: string # e.g. github
  --ordering: string@ordering-completer-8 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --visibility: string@visibility-completer # e.g. public
  --external-id: string # e.g. 1
  --source-criticality: string@source-criticality-completer # e.g. critical
  --monitored: string@bool-completer # e.g. true
  --provider-metadata-archived: string@bool-completer # e.g. true
  --team-id: int # e.g. 42
]: nothing -> table<id: int, url: string, type: string, full_name: string, health: record, default_branch: string, default_branch_head: string, open_incidents_count: int, closed_incidents_count: int, secret_incidents_breakdown: record<open_secret_incidents: record, closed_secret_incidents: record>, visibility: string, external_id: string, source_criticality: string, last_scan: record, monitored: bool, provider_metadata: record<archived: bool>, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "last_scan_status" $last_scan_status "scalar") (serialize-qp "health" $health "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "source_criticality" $source_criticality "scalar") (serialize-qp "monitored" $monitored "scalar") (serialize-qp "provider_metadata_archived" $provider_metadata_archived "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a source
#
# GET /v1/sources/{source_id}
# operationId: retrieve-source
export def "sources retrieve-source" [
  source_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, url: string, type: string, full_name: string, health: record, default_branch: string, default_branch_head: string, open_incidents_count: int, closed_incidents_count: int, secret_incidents_breakdown: record<open_secret_incidents: record<total: int, severity_breakdown: record>, closed_secret_incidents: record<total: int, severity_breakdown: record>>, visibility: string, external_id: string, source_criticality: string, last_scan: record, monitored: bool, provider_metadata: record<archived: bool>, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sources/($source_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a source
#
# PATCH /v1/sources/{source_id}
# operationId: update-source
# --secret_incidents_breakdown shape: {open_secret_incidents?: any, closed_secret_incidents?: any}
export def "sources update-source" [
  source_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-criticality: string # Criticality of the source.  (e.g. critical)
  --monitored: string@bool-completer # Whether the source is currently monitored by GitGuardian.  (e.g. true)
]: any -> record<id: int, url: string, type: string, full_name: string, health: record, default_branch: string, default_branch_head: string, open_incidents_count: int, closed_incidents_count: int, secret_incidents_breakdown: record<open_secret_incidents: record<total: int, severity_breakdown: record>, closed_secret_incidents: record<total: int, severity_breakdown: record>>, visibility: string, external_id: string, source_criticality: string, last_scan: record, monitored: bool, provider_metadata: record<archived: bool>, deleted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sources/($source_id)")
  let body = {source_criticality: $source_criticality, monitored: $monitored} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List secret incidents of a source
#
# GET /v1/sources/{source_id}/incidents/secrets
# operationId: list-sources-incidents
export def "sources-incidents-secrets list-sources-incidents" [
  source_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --assignee-email: string # e.g. eric@gitguardian.com
  --assignee-id: int # e.g. 4932
  --status: string
  --severity: string
  --validity: string
  --tags: string # e.g. FROM_HISTORICAL_SCAN,SENSITIVE_FILE
  --custom-tags: string # e.g. d45a123f-b15d-4fea-abf6-ff2a8479de5b,55b349d7-8c3a-40c9-957c-e58f5c3a7391
  --custom-tag-key: string
  --custom-tag-value: string
  --ordering: string@ordering-completer-6 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --detector-group-name: string # e.g. slackbot_token
  --ignorer-id: int # e.g. 4932
  --ignorer-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --resolver-id: int # e.g. 4932
  --resolver-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --feedback: string@bool-completer
  --only-on-provider-archived-sources: string@bool-completer
]: nothing -> table<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: list<record>, feedback_list: list<record>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: list<record>, occurrences: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "assignee_email" $assignee_email "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "custom_tags" $custom_tags "scalar") (serialize-qp "custom_tag_key" $custom_tag_key "scalar") (serialize-qp "custom_tag_value" $custom_tag_value "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "detector_group_name" $detector_group_name "scalar") (serialize-qp "ignorer_id" $ignorer_id "scalar") (serialize-qp "ignorer_api_token_id" $ignorer_api_token_id "scalar") (serialize-qp "resolver_id" $resolver_id "scalar") (serialize-qp "resolver_api_token_id" $resolver_api_token_id "scalar") (serialize-qp "feedback" $feedback "scalar") (serialize-qp "only_on_provider_archived_sources" $only_on_provider_archived_sources "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/sources/($source_id)/incidents/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger scans on sources
#
# POST /v1/sources/scans
# operationId: trigger-source-scans
export def "sources-scans trigger-source-scans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_ids: list # List of source IDs to scan. (e.g. [1, 2, 3])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/scans")
  let body = {source_ids: $source_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List custom sources
#
# GET /v1/sources/custom-sources
# operationId: list-custom-sources
@deprecated --flag page
export def "sources-custom-sources list-custom-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --search: string # e.g. my-custom-source
  --ordering: string@ordering-completer-9 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<id: string, source_uuid: string, name: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sources/custom-sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create custom source
#
# POST /v1/sources/custom-sources
# operationId: create-custom-source
export def "sources-custom-sources create-custom-source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the custom source (e.g. My Custom Source)
  --description: string # The description of the custom source (nullable, e.g. A custom source for testing purposes)
]: any -> record<id: string, source_uuid: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sources/custom-sources")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a custom source
#
# GET /v1/sources/custom-sources/{custom_source_id}
# operationId: get-custom-source
export def "sources-custom-sources get-custom-source" [
  custom_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, source_uuid: string, name: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sources/custom-sources/($custom_source_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom source
#
# PATCH /v1/sources/custom-sources/{custom_source_id}
# operationId: update-custom-source
export def "sources-custom-sources update-custom-source" [
  custom_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the custom source (e.g. My Custom Source)
  --description: string # The description of the custom source (nullable, e.g. A custom source for testing purposes)
]: any -> record<id: string, source_uuid: string, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sources/custom-sources/($custom_source_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom source
#
# DELETE /v1/sources/custom-sources/{custom_source_id}
# operationId: delete-custom-source
export def "sources-custom-sources delete-custom-source" [
  custom_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sources/custom-sources/($custom_source_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List developers
#
# GET /v1/public-perimeter/developers
# operationId: list-developers
export def "public-perimeter-developers list-developers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --ordering: string@ordering-completer-10 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<id: int, type: string, avatar_url: string, emails: list<string>, first_linked_at: string, is_active: bool, github_id: int, github_login: string, name: string, reasons: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/public-perimeter/developers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List audit Logs
#
# GET /v1/audit_logs
# operationId: list-audit-logs
export def "audit-logs list-audit-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --event-name: string # Entries matching this event name. (e.g. user.logged_in)
  --member-id: int # The id of the member to retrieve. (e.g. 3252)
  --member-name: string # Entries matching this member name. (e.g. John Smith)
  --member-email: string # Entries matching this member email. (e.g. john.smith@example.org)
  --api-token-id: string # Entries matching this API token id. (format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8)
  --ip-address: string # Entries matching this IP address. (e.g. 8.8.8.8)
]: nothing -> table<id: int, date: string, member_email: string, member_name: string, member_id: int, api_token_id: string, ip_address: string, target_ids: list<string>, action_type: string, event_name: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "event_name" $event_name "scalar") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "member_name" $member_name "scalar") (serialize-qp "member_email" $member_email "scalar") (serialize-qp "api_token_id" $api_token_id "scalar") (serialize-qp "ip_address" $ip_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/audit_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List audit log event names
#
# GET /v1/audit_logs/event_names
# operationId: list-audit-log-event-names
export def "audit-logs-event-names list-audit-log-event-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<events: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audit_logs/event_names")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Health
#
# GET /v1/health
# operationId: api_health
export def "health health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<detail: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List health checks
#
# GET /v1/health-checks
# operationId: list-health-checks
export def "health-checks list-health-checks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --type: string@type-completer # Filter by integration type. (e.g. github-installation)
  --status: string@status-completer # e.g. fail
  --started-at-after: string # format: date-time, e.g. 2024-01-01T00:00:00Z
  --started-at-before: string # format: date-time, e.g. 2024-12-31T23:59:59Z
]: nothing -> table<id: int, status: string, started_at: string, first_started_at: string, type: string, instance: record<id: int, name: string, url: string, status: string>, results: list<record>, last_successful_check_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "started_at_after" $started_at_after "scalar") (serialize-qp "started_at_before" $started_at_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/health-checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List health check history for an instance
#
# GET /v1/health-checks/{type}/{instance_id}
# operationId: list-health-check-instance-history
export def "health-checks list-health-check-instance-history" [
  type: string
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --status: string@status-completer # e.g. fail
  --started-at-after: string # format: date-time, e.g. 2024-01-01T00:00:00Z
  --started-at-before: string # format: date-time, e.g. 2024-12-31T23:59:59Z
  --ordering: string@ordering-completer-11 # Sort the results by their field value. The default sort is DESC (most recent first). Prefix with `-` for descending order.  (default: -started_at)
]: nothing -> table<id: int, status: string, started_at: string, first_started_at: string, type: string, instance: record<id: int, name: string, url: string, status: string>, results: list<record>, last_successful_check_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "started_at_after" $started_at_after "scalar") (serialize-qp "started_at_before" $started_at_before "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/health-checks/($type)/($instance_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a health check
#
# POST /v1/health-checks/{type}/{instance_id}/trigger
# operationId: trigger-health-check
export def "health-checks-trigger trigger-health-check" [
  type: string
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<detail: string, result_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/health-checks/($type)/($instance_id)/trigger")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List teams
#
# GET /v1/teams
# operationId: list-teams
export def "teams list-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --is-global: string@bool-completer
  --search: string
  --linked-to-an-external-provider: string@bool-completer
]: nothing -> table<id: int, name: string, description: string, is_global: bool, gitguardian_url: string, external_provider_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "is_global" $is_global "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "linked_to_an_external_provider" $linked_to_an_external_provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /v1/teams
# operationId: create-teams
export def "teams create-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. feature team A
  --description: string # team description. (nullable, e.g. Description of my team)
  --external-provider-id: string # ID of the external provider associated to the team. (nullable, e.g. 123-456-7890)
]: any -> record<id: int, name: string, description: string, is_global: bool, gitguardian_url: string, external_provider_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let body = {name: $name, description: $description, external_provider_id: $external_provider_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a team
#
# GET /v1/teams/{team_id}
# operationId: retrieve-team
export def "teams retrieve-team" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, description: string, is_global: bool, gitguardian_url: string, external_provider_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a team
#
# DELETE /v1/teams/{team_id}
# operationId: delete-team
export def "teams delete-team" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team
#
# PATCH /v1/teams/{team_id}
# operationId: update-team
export def "teams update-team" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # e.g. feature team A
  --description: string # team description. (nullable, e.g. Description of my team)
  --external-provider-id: string # ID of the external provider associated to the team. (nullable, e.g. 123-456-7890)
]: any -> record<id: int, name: string, description: string, is_global: bool, gitguardian_url: string, external_provider_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)")
  let body = {name: $name, description: $description, external_provider_id: $external_provider_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List secret incidents of a team
#
# GET /v1/teams/{team_id}/incidents/secrets
# DEPRECATED
# operationId: list-team-incidents
@deprecated
export def "teams-incidents-secrets list-team-incidents" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --assignee-email: string # e.g. eric@gitguardian.com
  --assignee-id: int # e.g. 4932
  --status: string
  --severity: string
  --validity: string
  --tags: string # e.g. FROM_HISTORICAL_SCAN,SENSITIVE_FILE
  --custom-tags: string # e.g. d45a123f-b15d-4fea-abf6-ff2a8479de5b,55b349d7-8c3a-40c9-957c-e58f5c3a7391
  --custom-tag-key: string
  --custom-tag-value: string
  --ordering: string@ordering-completer-6 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --detector-group-name: string # e.g. slackbot_token
  --ignorer-id: int # e.g. 4932
  --ignorer-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --resolver-id: int # e.g. 4932
  --resolver-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --only-on-provider-archived-sources: string@bool-completer
]: nothing -> table<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: list<record>, feedback_list: list<record>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: list<record>, occurrences: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "assignee_email" $assignee_email "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "custom_tags" $custom_tags "scalar") (serialize-qp "custom_tag_key" $custom_tag_key "scalar") (serialize-qp "custom_tag_value" $custom_tag_value "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "detector_group_name" $detector_group_name "scalar") (serialize-qp "ignorer_id" $ignorer_id "scalar") (serialize-qp "ignorer_api_token_id" $ignorer_api_token_id "scalar") (serialize-qp "resolver_id" $resolver_id "scalar") (serialize-qp "resolver_api_token_id" $resolver_api_token_id "scalar") (serialize-qp "only_on_provider_archived_sources" $only_on_provider_archived_sources "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/incidents/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check team permission for a resource
#
# GET /v1/teams/{team_id}/{resource_type}/{resource_id}
# operationId: get-team-resource-access
export def "teams get-team-resource-access" [
  team_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<team_id: int, resource_id: int, resource_type: string, permission: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/($resource_type)/($resource_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Give a team access to a resource
#
# PUT /v1/teams/{team_id}/{resource_type}/{resource_id}
# operationId: set-team-resource-access
export def "teams set-team-resource-access" [
  team_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the team members about the access. (default: true)
  --permission: string # e.g. can_edit
]: any -> record<team_id: int, resource_id: int, resource_type: string, permission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/($resource_type)/($resource_id)" $qp)
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke a team's access to a resource
#
# DELETE /v1/teams/{team_id}/{resource_type}/{resource_id}
# operationId: revoke-team-resource-access
export def "teams revoke-team-resource-access" [
  team_id: int
  resource_type: string
  resource_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string # e.g. can_edit
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/($resource_type)/($resource_id)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List secret incidents a team has access to
#
# GET /v1/teams/{team_id}/secret-incidents
# operationId: list-team-secret-incident-access
@deprecated --flag page
export def "teams-secret-incidents list-team-secret-incident-access" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --page: int # Page number. (DEPRECATED, default: 1)
  --per-page: int # Number of items to list per page. (default: 20)
  --date-before: string # format: datetime, e.g. 2019-08-30T14:15:22Z
  --date-after: string # format: datetime, e.g. 2019-08-22T14:15:22Z
  --assignee-email: string # e.g. eric@gitguardian.com
  --assignee-id: int # e.g. 4932
  --status: string
  --severity: string
  --validity: string
  --tags: string # e.g. FROM_HISTORICAL_SCAN,SENSITIVE_FILE
  --custom-tags: string # e.g. d45a123f-b15d-4fea-abf6-ff2a8479de5b,55b349d7-8c3a-40c9-957c-e58f5c3a7391
  --custom-tag-key: string
  --custom-tag-value: string
  --ordering: string@ordering-completer-6 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --detector-group-name: string # e.g. slackbot_token
  --ignorer-id: int # e.g. 4932
  --ignorer-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --resolver-id: int # e.g. 4932
  --resolver-api-token-id: string # format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8
  --feedback: string@bool-completer
  --only-on-provider-archived-sources: string@bool-completer
]: nothing -> table<id: int, date: string, detector: record<name: string, display_name: string, nature: string, family: string, category: string, detector_group_name: string, detector_group_display_name: string>, secret_id: int, secret_hash: string, hmsl_hash: string, gitguardian_url: string, regression: bool, status: record, assignee_id: int, assignee_email: string, occurrences_count: int, secret_presence: record<files_requiring_code_fix: int, files_pending_merge: int, files_fixed: int, outside_vcs: int, removed_outside_vcs: int, in_vcs: int, removed_in_vcs: int>, ignore_reason: string, triggered_at: string, ignored_at: string, ignorer_id: int, ignorer_api_token_id: string, resolver_id: int, resolver_api_token_id: string, secret_revoked: bool, severity: string, validity: string, resolved_at: string, share_url: string, tags: list<string>, custom_tags: list<record>, feedback_list: list<record>, incident_name: string, risk_score: int, severity_rule_id: int, is_vaulted: bool, public_exposure: record<source_publicly_visible: bool, public_incident_linked: bool, leaked_outside_perimeter: bool>, destination_tickets: list<record>, occurrences: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "date_before" $date_before "scalar") (serialize-qp "date_after" $date_after "scalar") (serialize-qp "assignee_email" $assignee_email "scalar") (serialize-qp "assignee_id" $assignee_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "validity" $validity "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "custom_tags" $custom_tags "scalar") (serialize-qp "custom_tag_key" $custom_tag_key "scalar") (serialize-qp "custom_tag_value" $custom_tag_value "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "detector_group_name" $detector_group_name "scalar") (serialize-qp "ignorer_id" $ignorer_id "scalar") (serialize-qp "ignorer_api_token_id" $ignorer_api_token_id "scalar") (serialize-qp "resolver_id" $resolver_id "scalar") (serialize-qp "resolver_api_token_id" $resolver_api_token_id "scalar") (serialize-qp "feedback" $feedback "scalar") (serialize-qp "only_on_provider_archived_sources" $only_on_provider_archived_sources "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/secret-incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List team invitations
#
# GET /v1/teams/{team_id}/team_invitations
# operationId: list-team-invitation
export def "teams-team-invitations list-team-invitation" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --invitation-id: int # The id of an invitation to filter on
  --is-team-leader: string@bool-completer # e.g. true
  --team-permission: string # e.g. can_manage
  --incident-permission: string # e.g. can_edit
]: nothing -> table<id: int, invitation_id: int, team_id: int, is_team_leader: bool, team_permission: string, incident_permission: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "invitation_id" $invitation_id "scalar") (serialize-qp "is_team_leader" $is_team_leader "scalar") (serialize-qp "team_permission" $team_permission "scalar") (serialize-qp "incident_permission" $incident_permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team invitation
#
# POST /v1/teams/{team_id}/team_invitations
# operationId: create-team-invitations
@deprecated --flag team-permission
export def "teams-team-invitations create-team-invitations" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invitation_id: int # e.g. 4851
  --is-team-leader: string@bool-completer # e.g. false
  --team-permission: string # team_permission is replaced by is_team_leader (DEPRECATED, e.g. cannot_manage)
  --incident-permission: string # e.g. can_edit
]: any -> record<id: int, invitation_id: int, team_id: int, is_team_leader: bool, team_permission: string, incident_permission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_invitations")
  let body = {invitation_id: $invitation_id, is_team_leader: $is_team_leader, team_permission: $team_permission, incident_permission: $incident_permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a team invitation
#
# PATCH /v1/teams/{team_id}/team_invitations/{team_invitation_id}
# operationId: update-team-invitation
@deprecated --flag team-permission
export def "teams-team-invitations update-team-invitation" [
  team_id: int
  team_invitation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-team-leader: string@bool-completer # e.g. false
  --team-permission: string # team_permission is replaced by is_team_leader (DEPRECATED, e.g. cannot_manage)
  --incident-permission: string # e.g. can_view
]: any -> record<id: int, invitation_id: int, team_id: int, is_team_leader: bool, team_permission: string, incident_permission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_invitations/($team_invitation_id)")
  let body = {is_team_leader: $is_team_leader, team_permission: $team_permission, incident_permission: $incident_permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a team invitation
#
# DELETE /v1/teams/{team_id}/team_invitations/{team_invitation_id}
# operationId: delete-team-invitation
export def "teams-team-invitations delete-team-invitation" [
  team_id: int
  team_invitation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_invitations/($team_invitation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List team memberships
#
# GET /v1/teams/{team_id}/team_memberships
# operationId: list-team-memberships
export def "teams-team-memberships list-team-memberships" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --is-team-leader: string@bool-completer # e.g. true
  --team-permission: string # e.g. can_manage
  --incident-permission: string # e.g. can_edit
  --member-id: float # e.g. 1234
]: nothing -> table<id: int, member_id: int, team_id: int, is_team_leader: bool, team_permission: string, incident_permission: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "is_team_leader" $is_team_leader "scalar") (serialize-qp "team_permission" $team_permission "scalar") (serialize-qp "incident_permission" $incident_permission "scalar") (serialize-qp "member_id" $member_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a member to a team
#
# POST /v1/teams/{team_id}/team_memberships
# operationId: create-team-membership
@deprecated --flag team-permission
export def "teams-team-memberships create-team-membership" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the member about the team membership. (default: true)
  --member-id: int # Id of a workspace member. (e.g. 2489)
  --is-team-leader: string@bool-completer # e.g. false
  --team-permission: string # team_permission is replaced by is_team_leader (DEPRECATED, e.g. cannot_manage)
  --incident-permission: string # e.g. can_edit
]: any -> record<id: int, member_id: int, team_id: int, is_team_leader: bool, team_permission: string, incident_permission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_memberships" $qp)
  let body = {member_id: $member_id, is_team_leader: $is_team_leader, team_permission: $team_permission, incident_permission: $incident_permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a team membership
#
# PATCH /v1/teams/{team_id}/team_memberships/{team_membership_id}
# operationId: update-team-membership
@deprecated --flag team-permission
export def "teams-team-memberships update-team-membership" [
  team_id: int
  team_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --is-team-leader: string@bool-completer # e.g. false
  --team-permission: string # team_permission is replaced by is_team_leader (DEPRECATED, e.g. cannot_manage)
  --incident-permission: string # e.g. can_view
]: any -> record<id: int, member_id: int, team_id: int, is_team_leader: bool, team_permission: string, incident_permission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_memberships/($team_membership_id)")
  let body = {is_team_leader: $is_team_leader, team_permission: $team_permission, incident_permission: $incident_permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a member from a team
#
# DELETE /v1/teams/{team_id}/team_memberships/{team_membership_id}
# operationId: delete-team-membership
export def "teams-team-memberships delete-team-membership" [
  team_id: int
  team_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the member about the removal from the team. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_memberships/($team_membership_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List team memberships of a member
#
# GET /v1/members/{member_id}/team_memberships
# operationId: list-member-team-memberships
export def "members-team-memberships list-member-team-memberships" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --team-id: int # The id of a team to filter on
]: nothing -> table<id: int, member_id: int, team_id: int, is_team_leader: bool, team_permission: string, incident_permission: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/members/($member_id)/team_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List team requests of a team
#
# GET /v1/teams/{team_id}/team_requests
# operationId: list-team-requests
export def "teams-team-requests list-team-requests" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --member-id: float # e.g. 1234
]: nothing -> table<id: int, member_id: int, team_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "member_id" $member_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request access to a team
#
# POST /v1/teams/{team_id}/team_requests
# operationId: create-team-request
export def "teams-team-requests create-team-request" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, member_id: int, team_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel or decline a team request
#
# DELETE /v1/teams/{team_id}/team_requests/{team_request_id}
# operationId: delete-team-request
export def "teams-team-requests delete-team-request" [
  team_id: int
  team_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the member about the request having been denied. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_requests/($team_request_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept a team request
#
# POST /v1/teams/{team_id}/team_requests/{team_request_id}/accept
# operationId: accept-team-request
@deprecated --flag team-permission
export def "teams-team-requests-accept accept-team-request" [
  team_id: int
  team_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-email: string@bool-completer # Whether to notify the member about the request having been accepted. (default: true)
  --is-team-leader: string@bool-completer # e.g. false
  --team-permission: string # team_permission is replaced by is_team_leader (DEPRECATED, e.g. cannot_manage)
  --incident-permission: string # e.g. can_view
]: any -> record<id: int, member_id: int, team_id: int, is_team_leader: bool, team_permission: string, incident_permission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_email" $send_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/team_requests/($team_request_id)/accept" $qp)
  let body = {is_team_leader: $is_team_leader, team_permission: $team_permission, incident_permission: $incident_permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List team requests of a member
#
# GET /v1/members/{member_id}/team_requests
# operationId: list-member-team-requests
export def "members-team-requests list-member-team-requests" [
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --team-id: float # e.g. 1234
]: nothing -> table<id: int, member_id: int, team_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/members/($member_id)/team_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List team sources
#
# GET /v1/teams/{team_id}/sources
# operationId: list-team-sources
export def "teams-sources list-team-sources" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --search: string # e.g. test-repository
  --last-scan-status: string
  --health: string
  --type: string
  --ordering: string@ordering-completer-8 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --visibility: string@visibility-completer # e.g. public
  --external-id: string # e.g. 1
]: nothing -> table<id: int, url: string, type: string, full_name: string, health: record, default_branch: string, default_branch_head: string, open_incidents_count: int, closed_incidents_count: int, secret_incidents_breakdown: record<open_secret_incidents: record, closed_secret_incidents: record>, visibility: string, external_id: string, source_criticality: string, last_scan: record, monitored: bool, provider_metadata: record<archived: bool>, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "last_scan_status" $last_scan_status "scalar") (serialize-qp "health" $health "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "external_id" $external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team perimeter
#
# POST /v1/teams/{team_id}/sources
# operationId: update-team-sources
export def "teams-sources update-team-sources" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sources-to-add: list # Ids of sources to add to the perimeter.
  --sources-to-remove: list # Ids of sources to remove from the perimeter.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/sources")
  let body = {sources_to_add: $sources_to_add, sources_to_remove: $sources_to_remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List honeytokens
#
# GET /v1/honeytokens
# operationId: list-honeytoken
export def "honeytokens list-honeytoken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --status: string@status-completer-1
  --type: string@type-completer-1
  --search: string
  --creator-id: float
  --revoker-id: float
  --creator-api-token-id: string
  --revoker-api-token-id: string
  --tags: string
  --ordering: string@ordering-completer-12 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --show-token: string@bool-completer # default: false
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
]: nothing -> table<id: string, name: string, description: string, created_at: string, gitguardian_url: string, status: string, triggered_at: string, revoked_at: string, open_events_count: int, type: string, creator_id: int, revoker_id: int, creator_api_token_id: string, revoker_api_token_id: string, token: record, tags: list<string>, custom_tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "creator_id" $creator_id "scalar") (serialize-qp "revoker_id" $revoker_id "scalar") (serialize-qp "creator_api_token_id" $creator_api_token_id "scalar") (serialize-qp "revoker_api_token_id" $revoker_api_token_id "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "show_token" $show_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/honeytokens" $qp)
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a honeytoken
#
# POST /v1/honeytokens
# operationId: create-honeytoken
# --custom_tags item shape: {key?: string, value?: string}
export def "honeytokens create-honeytoken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # honeytoken name.  (e.g. honeytoken name)
  --description: string # honeytoken description.  (e.g. This honeytoken was placed in the repository test)
  type: string@type-completer-1 # honeytoken type  (e.g. AWS)
  --custom-tags: list # Custom tags to set on the honeytoken. If the custom tag doesn't exist, it will be created. — item shape: {key?: string, value?: string}
]: any -> record<id: string, name: string, description: string, created_at: string, gitguardian_url: string, status: string, triggered_at: string, revoked_at: string, open_events_count: int, type: string, creator_id: int, revoker_id: int, creator_api_token_id: string, revoker_api_token_id: string, token: record, tags: list<string>, custom_tags: table<id: string, key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/honeytokens")
  let body = {name: $name, description: $description, type: $type, custom_tags: $custom_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a machine/user's honeytoken deployments (read-only)
#
# GET /v1/honeytokens/endpoint-deployments
# operationId: list-endpoint-deployments
export def "honeytokens-endpoint-deployments list-endpoint-deployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --machine-id: string # Stable machine identifier (key for the Endpoint). (e.g. 7e3a9d7f-8a5e-4e23-9c2f-eb1d6f64fa55)
  --username: string # OS-level username on the machine (key for the EndpointUser). (e.g. alice)
]: nothing -> record<deployments: table<id: string, type: string, method: string, config: record, status: string, action: string, token: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "machine_id" $machine_id "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/honeytokens/endpoint-deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reconcile (plant) honeytokens for a machine/user
#
# POST /v1/honeytokens/endpoint-deployments
# operationId: create-endpoint-deployment
# --config shape: {filename?: string, profile_name?: string}
# --custom_tags item shape: {key?: string, value?: string}
# --machine_info shape: {machine_id: string, username: string, hostname: string}
export def "honeytokens-endpoint-deployments create-endpoint-deployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2 # Honeytoken kind to reconcile. Optional, defaults to `aws`.  (default: aws)
  --method: string@method-completer # Placement method. Optional; defaults to the type's default (`aws_credentials`). Selects how the honeytoken is materialized on the endpoint. `method` + `config` only steer the creation of a *new* deployment for the `(machine, user, type, method)` key — they are ignored if a live deployment already exists (except that a conflicting explicit `config` is rejected, see 409).
  --config: record # Optional per-call override of the placement config. Omitted fields fall back to the method default. `method` is never accepted here (use the top-level `method`). — shape: {filename?: string, profile_name?: string}
  --description: string # Optional honeytoken description (applied only on creation). (e.g. Deployed by ggshield on the CI runner)
  --custom-tags: list # Custom tags to set on the honeytoken (applied only on creation). — item shape: {key?: string, value?: string}
  machine_info: record # Machine and OS user the honeytokens are disseminated to. Used to upsert an Endpoint + EndpointUser keyed by `(account, machine_id)` and `(endpoint, username)` respectively. — shape: {machine_id: string, username: string, hostname: string}
]: any -> record<deployments: table<id: string, type: string, method: string, config: record, status: string, action: string, token: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/honeytokens/endpoint-deployments")
  let body = {type: $type, method: $method, config: $config, description: $description, custom_tags: $custom_tags, machine_info: $machine_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Confirm a honeytoken endpoint deployment
#
# PATCH /v1/honeytokens/endpoint-deployments/{id}
# operationId: confirm-endpoint-deployment
export def "honeytokens-endpoint-deployments confirm-endpoint-deployment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer-2 # Outcome reported by the client.
]: any -> record<id: string, method: string, config: record<filename: string, profile_name: string>, status: string, planted_at: string, last_synced_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/honeytokens/endpoint-deployments/($id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a honeytoken within a context
#
# POST /v1/honeytokens/with-context
# operationId: create-honeytoken-with-context
# --custom_tags item shape: {key?: string, value?: string}
export def "honeytokens-with-context create-honeytoken-with-context" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Honeytoken name.  (e.g. honeytoken name)
  --description: string # Honeytoken description.  (e.g. This honeytoken was placed in the repository test)
  type: string@type-completer-1 # Honeytoken type.  (e.g. AWS)
  --custom-tags: list # Custom tags to set on the honeytoken. If the custom tag doesn't exist, it will be created. — item shape: {key?: string, value?: string}
  --language: string # Language to use for the context. If not set but `project_extensions` is set, the languages will be inferred from the extensions. (e.g. python)
  --filename: string # Filename to use for the context. (e.g. test_config.py)
  --project-extensions: list # An array of file extensions that can be used for the context. (e.g. [.c, .h])
]: any -> record<content: string, filepath: string, language: string, suggested_commit_message: string, honeytoken_id: string, gitguardian_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/honeytokens/with-context")
  let body = {name: $name, description: $description, type: $type, custom_tags: $custom_tags, language: $language, filename: $filename, project_extensions: $project_extensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a honeytoken
#
# GET /v1/honeytokens/{honeytoken_id}
# operationId: retrieve-honeytoken
export def "honeytokens retrieve-honeytoken" [
  honeytoken_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-token: string@bool-completer # default: false
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
]: nothing -> record<id: string, name: string, description: string, created_at: string, gitguardian_url: string, status: string, triggered_at: string, revoked_at: string, open_events_count: int, type: string, creator_id: int, revoker_id: int, creator_api_token_id: string, revoker_api_token_id: string, token: record, tags: list<string>, custom_tags: table<id: string, key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_token" $show_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)" $qp)
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a honeytoken
#
# PATCH /v1/honeytokens/{honeytoken_id}
# operationId: update-honeytoken
# --custom_tags item shape: {key?: string, value?: string}
export def "honeytokens update-honeytoken" [
  honeytoken_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
  --name: string # A new honeytoken name (e.g. test-honeytoken)
  --description: string # A new honeytoken description (e.g. honeytoken in repository test)
  --custom-tags: list # A new set of custom tags for the honeytoken. Will completely override the former custom tags. — item shape: {key?: string, value?: string}
]: any -> record<id: string, name: string, description: string, created_at: string, gitguardian_url: string, status: string, triggered_at: string, revoked_at: string, open_events_count: int, type: string, creator_id: int, revoker_id: int, creator_api_token_id: string, revoker_api_token_id: string, token: record, tags: list<string>, custom_tags: table<id: string, key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)")
  let body = {name: $name, description: $description, custom_tags: $custom_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the honeytoken
#
# POST /v1/honeytokens/{honeytoken_id}/reset
# operationId: reset-honeytoken
export def "honeytokens-reset reset-honeytoken" [
  honeytoken_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
]: nothing -> record<id: string, name: string, description: string, created_at: string, gitguardian_url: string, status: string, triggered_at: string, revoked_at: string, open_events_count: int, type: string, creator_id: int, revoker_id: int, creator_api_token_id: string, revoker_api_token_id: string, token: record, tags: list<string>, custom_tags: table<id: string, key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)/reset")
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke the honeytoken
#
# POST /v1/honeytokens/{honeytoken_id}/revoke
# operationId: revoke-honeytoken
export def "honeytokens-revoke revoke-honeytoken" [
  honeytoken_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
]: nothing -> record<id: string, name: string, description: string, created_at: string, gitguardian_url: string, status: string, triggered_at: string, revoked_at: string, open_events_count: int, type: string, creator_id: int, revoker_id: int, creator_api_token_id: string, revoker_api_token_id: string, token: record, tags: list<string>, custom_tags: table<id: string, key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)/revoke")
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List notes on an honeytoken
#
# GET /v1/honeytokens/{honeytoken_id}/notes
# operationId: list-honeytoken-notes
export def "honeytokens-notes list-honeytoken-notes" [
  honeytoken_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --ordering: string@ordering-completer-2 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --member-id: int # Filter by member id. (e.g. 1)
  --api-token-id: string # Entries matching this API token id. (format: uuid, e.g. fdf075f9-1662-4cf1-9171-af50568158a8)
  --search: string # e.g. I revoked this
]: nothing -> table<id: string, honeytoken_id: string, member_id: int, api_token_id: string, created_at: string, updated_at: string, comment: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "member_id" $member_id "scalar") (serialize-qp "api_token_id" $api_token_id "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an honeytoken note
#
# POST /v1/honeytokens/{honeytoken_id}/notes
# operationId: create-honeytoken-note
export def "honeytokens-notes create-honeytoken-note" [
  honeytoken_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment: string # Content of the honeytoken note (e.g. I revoked this honeytoken)
]: any -> record<id: string, honeytoken_id: string, member_id: int, api_token_id: string, created_at: string, updated_at: string, comment: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)/notes")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a honeytoken note
#
# PATCH /v1/honeytokens/{honeytoken_id}/notes/{note_id}
# operationId: update-honeytoken-note
export def "honeytokens-notes update-honeytoken-note" [
  honeytoken_id: string
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  comment: string # Content of the honeytoken note (e.g. I revoked this)
]: any -> record<id: string, honeytoken_id: string, member_id: int, api_token_id: string, created_at: string, updated_at: string, comment: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)/notes/($note_id)")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a honeytoken note
#
# DELETE /v1/honeytokens/{honeytoken_id}/notes/{note_id}
# operationId: delete-honeytoken-note
export def "honeytokens-notes delete-honeytoken-note" [
  honeytoken_id: string
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sources on an honeytoken
#
# GET /v1/honeytokens/{honeytoken_id}/sources
# operationId: list-honeytoken-sources
export def "honeytokens-sources list-honeytoken-sources" [
  honeytoken_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --ordering: string@ordering-completer-13 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
  --provider-metadata-archived: string@bool-completer # e.g. true
]: nothing -> table<provider_metadata: record<archived: bool>, type: record, name: string, url: string, open_issues_count: float, total_files_count: float, files: list<string>, source_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "provider_metadata_archived" $provider_metadata_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/honeytokens/($honeytoken_id)/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk prefix lookup for honeytoken HMSL hashes
#
# POST /v1/honeytokens/prefixes
# operationId: check-honeytoken-prefixes
export def "honeytokens-prefixes check-honeytoken-prefixes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prefixes: list # List of 5-character lowercase hexadecimal HMSL hash prefixes. Maximum 500 prefixes per request.  (e.g. [abcde, 12345])
]: any -> record<matches: table<hint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/honeytokens/prefixes")
  let body = {prefixes: $prefixes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all honeytokens events
#
# GET /v1/honeytokens_events
# operationId: list-honeytokens-events
export def "honeytokens-events list-honeytokens-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --ordering: string@ordering-completer-14 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'
  --honeytoken-id: string # Filter by honeytoken id (format: uuid, e.g. d45a123f-b15d-4fea-abf6-ff2a8479de5b)
  --status: string@status-completer-3 # Filter by status (default: open)
  --ip-address: string # Filter by ip address (e.g. 8.8.8.8)
  --tags: string
  --search: string # Search events based on the `data` field content (e.g. I revoked this)
  --X-Privacy-Mode: string@X-Privacy-Mode-completer # When set to `true`, sensitive values in the response are obfuscated (replaced with `<GG>OBFUSCATED</GG>`). Useful for sharing API responses without exposing sensitive data.
]: nothing -> table<id: string, honeytoken_id: string, triggered_at: string, gitguardian_url: string, status: string, ip_address: string, action: string, data: record, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "honeytoken_id" $honeytoken_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "ip_address" $ip_address "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/honeytokens_events" $qp)
  let extra_headers = {"X-Privacy-Mode": $X_Privacy_Mode} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List IP allowlist rules
#
# GET /v1/ip-allowlist
# operationId: list-ip-allowlist
export def "ip-allowlist list-ip-allowlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --search: string
  --ordering: string@ordering-completer-15 # Sort the results by their field value. The default sort is ASC, DESC if the field is preceded by a '-'.
]: nothing -> table<id: string, tag: string, created_at: string, ip_ranges: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ip-allowlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an IP allowlist rule
#
# POST /v1/ip-allowlist
# operationId: create-ip-allowlist
export def "ip-allowlist create-ip-allowlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tag: string # Tag for the IP allowlist rule (e.g. Main office)
  ip_ranges: list # The IP addresses (individual IPs or CIDR notation) to include in the IP allowlist rule (e.g. [35.153.173.97, 10.0.0.0/24])
]: any -> record<id: string, tag: string, created_at: string, ip_ranges: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ip-allowlist")
  let body = {tag: $tag, ip_ranges: $ip_ranges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an IP allowlist rule
#
# GET /v1/ip-allowlist/{ip_allowlist_rule_id}
# operationId: retrieve-ipallowlist
export def "ip-allowlist retrieve-ipallowlist" [
  ip_allowlist_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, tag: string, created_at: string, ip_ranges: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ip-allowlist/($ip_allowlist_rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an IP allowlist rule
#
# PATCH /v1/ip-allowlist/{ip_allowlist_rule_id}
# operationId: update-ipallowlist
export def "ip-allowlist update-ipallowlist" [
  ip_allowlist_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # A new tag (e.g. Satellite office)
  --ip-ranges: list # The IP addresses (individual IPs or CIDR notation) to include in the IP allowlist rule (e.g. [35.45.64.56, 10.0.0.0/24])
]: any -> record<id: string, tag: string, created_at: string, ip_ranges: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ip-allowlist/($ip_allowlist_rule_id)")
  let body = {tag: $tag, ip_ranges: $ip_ranges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an IP allowlist rule
#
# DELETE /v1/ip-allowlist/{ip_allowlist_rule_id}
# operationId: delete-ipallowlist
export def "ip-allowlist delete-ipallowlist" [
  ip_allowlist_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ip-allowlist/($ip_allowlist_rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List GitGuardian IP addresses
#
# GET /v1/ips
# operationId: list_ip_addresses
export def "ips addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ipv4_cidrs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ips")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a member (SCIM)
#
# POST /v1/scim/v2/Users
# operationId: scim-user-create
export def "scim-users scim-user-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scim/v2/Users")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/scim+json" $body
}

# List members (SCIM)
#
# GET /v1/scim/v2/Users
# operationId: scim-user-list
export def "scim-users scim-user-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Filter users using SCIM filtering DSL.
  --startIndex: int # The 1-based index of the first result in the current set of list results. (default: 1)
  --count: int # Specifies the desired maximum number of query results per page. (default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/scim/v2/Users" $qp)
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detail of a member (SCIM)
#
# GET /v1/scim/v2/Users/{id}
# operationId: scim-user-detail
export def "scim-users scim-user-detail" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Users/($id)")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update of a member (SCIM)
#
# PUT /v1/scim/v2/Users/{id}
# operationId: scim-user-update
export def "scim-users scim-user-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Users/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/scim+json" $body
}

# Update (partial) of a member (SCIM)
#
# PATCH /v1/scim/v2/Users/{id}
# operationId: scim-user-partial-update
export def "scim-users scim-user-partial-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Users/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/scim+json" $body
}

# Delete a member (SCIM)
#
# DELETE /v1/scim/v2/Users/{id}
# operationId: scim-user-delete
export def "scim-users scim-user-delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List groups (SCIM)
#
# GET /v1/scim/v2/Groups
# operationId: scim-group-list
export def "scim-groups scim-group-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Filter groups using the SCIM filtering DSL.
  --startIndex: int # The 1-based index of the first result in the current set of list results. (default: 1)
  --count: int # Specifies the desired maximum number of query results per page. (default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/scim/v2/Groups" $qp)
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a group (SCIM)
#
# POST /v1/scim/v2/Groups
# operationId: scim-group-create
export def "scim-groups scim-group-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scim/v2/Groups")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/scim+json" $body
}

# Detail of a group (SCIM)
#
# GET /v1/scim/v2/Groups/{id}
# operationId: scim-group-detail
export def "scim-groups scim-group-detail" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Groups/($id)")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a group (SCIM)
#
# PUT /v1/scim/v2/Groups/{id}
# operationId: scim-group-update
export def "scim-groups scim-group-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Groups/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/scim+json" $body
}

# Partially update a group (SCIM)
#
# PATCH /v1/scim/v2/Groups/{id}
# operationId: scim-group-partial-update
export def "scim-groups scim-group-partial-update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Groups/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/scim+json" $body
}

# Delete a group (SCIM)
#
# DELETE /v1/scim/v2/Groups/{id}
# operationId: scim-group-delete
export def "scim-groups scim-group-delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Service Provider Configuration (SCIM)
#
# GET /v1/scim/v2/ServiceProviderConfig
# operationId: scim-service-provider-config
export def "scim-service-provider-config scim-service-provider-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scim/v2/ServiceProviderConfig")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Resource Types (SCIM)
#
# GET /v1/scim/v2/ResourceTypes
# operationId: scim-resource-types-list
export def "scim-resource-types scim-resource-types-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scim/v2/ResourceTypes")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resource Types (SCIM)
#
# GET /v1/scim/v2/ResourceTypes/{name}
# operationId: scim-resource-types-detail
export def "scim-resource-types scim-resource-types-detail" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/ResourceTypes/($name)")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Schemas (SCIM)
#
# GET /v1/scim/v2/Schemas
# operationId: scim-schema-list
export def "scim-schemas scim-schema-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scim/v2/Schemas")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schema (SCIM)
#
# GET /v1/scim/v2/Schemas/{name}
# operationId: scim-schema-detail
export def "scim-schemas scim-schema-detail" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Schemas/($name)")
  let accept_val = "application/scim+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List custom tags
#
# GET /v1/custom_tags
# operationId: list-custom-tags
export def "custom-tags list-custom-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor.
  --per-page: int # Number of items to list per page. (default: 20)
  --key: string # e.g. env
]: nothing -> table<id: string, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/custom_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom tag
#
# POST /v1/custom_tags
# operationId: create-custom-tag
export def "custom-tags create-custom-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # e.g. env
  --value: string # nullable, e.g. prod
]: any -> record<id: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/custom_tags")
  let body = {key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update custom tags key
#
# PATCH /v1/custom_tags
# operationId: update-custom-tags-key
export def "custom-tags update-custom-tags-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --old-key: string # e.g. env
  --new-key: string # e.g. environment
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "old_key" $old_key "scalar") (serialize-qp "new_key" $new_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/custom_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a custom tags key
#
# DELETE /v1/custom_tags
# operationId: delete-custom-tags-key
export def "custom-tags delete-custom-tags-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # e.g. env
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/custom_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a custom tag
#
# GET /v1/custom_tags/{custom_tag_id}
# operationId: get-custom-tag
export def "custom-tags get-custom-tag" [
  custom_tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom_tags/($custom_tag_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Full Update of a Custom Tag
#
# PUT /v1/custom_tags/{custom_tag_id}
# operationId: update-custom-tag
export def "custom-tags update-custom-tag" [
  custom_tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # e.g. env
  --value: string # nullable, e.g. prod
]: any -> record<id: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom_tags/($custom_tag_id)")
  let body = {key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partial update of a Custom Tag
#
# PATCH /v1/custom_tags/{custom_tag_id}
# operationId: partial-update-custom-tag
export def "custom-tags partial-update-custom-tag" [
  custom_tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # e.g. env
  --value: string # nullable, e.g. prod
]: any -> record<id: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom_tags/($custom_tag_id)")
  let body = {key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletion of a custom tag
#
# DELETE /v1/custom_tags/{custom_tag_id}
# operationId: delete-custom-tag
export def "custom-tags delete-custom-tag" [
  custom_tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom_tags/($custom_tag_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
