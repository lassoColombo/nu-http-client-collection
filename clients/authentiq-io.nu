# Auto-generated client for Authentiq Connect API v1.0
# Source: https://api.apis.guru/v2/specs/authentiq.io/1.0/openapi.json
# Auth: --token flag or $env.AUTHENTIQ_CONNECT_API_TOKEN

const BASE_URL = "https://connect.authentiq.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AUTHENTIQ_CONNECT_API_TOKEN | default "" }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://connect.authentiq.io"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authorize get" } } | get name | first)
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

# Authenticate a user
#
# GET /authorize
# Docs: http://openid.net/specs/openid-connect-core-1_0.html#AuthorizationEndpoint — OIDC Authorization Endpoint
# operationId: authorize
export def "authorize get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # A client ID obtained from the [Dashboard](https://dashboard.authentiq.com/).
  --response-type: string # The OIDC response type to use for this authentication flow. Valid choices are `code`, `id_token`, `token`, `token id_token`, `code id_token` `code token` and `code token id_token`, but a client can be configured with a more restricted set.
  --scope: string # The space-separated identity claims to request from the end-user. Always include `openid` as a scope for compatibility with OIDC.
  --redirect-uri: string # The location to redirect to after (un)successful authentication. See OIDC for the parameters passed in the query string (`response_mode=query`) or as fragments (`response_mode=fragment`). Unless the client is in test-mode this must be one of the registered redirect URLs.
  --state: string # An opaque string that will be passed back to the redirect URL and therefore can be used to communicate client side state and prevent CSRF attacks.
  --response-mode: string # Whether to append parameters to the redirect URL in the query string (`query`) or as fragments (`fragment`). This option usually has a sensible default for each of the response types.
  --nonce: string # An nonce provided by the client (and opaque to Authentiq Connect) that will be included in any ID Token generated for this session. Clients should use the nonce to mitigate replay attacks.
  --display: string # The authentication display mode, which can be one of `page`, `popup` or `modal`. Defaults to `page`. (default: page)
  --prompt: string # Space-delimited, case sensitive list of ASCII string values that specifies whether the Authorization Server prompts the End-User for reauthentication and consent. The supported values are: `none`, `login`, `consent`. If `consent` the end-user is asked to (re)confirm what claims they share. Use `none` to check for an active session. (default: login)
  --max-age: int # Specifies the allowable elapsed time in seconds since the last time the end-user was actively authenticated. (default: 0)
  --ui-locales: string # Specifies the preferred language to use on the authorization page, as a space-separated list of BCP47 language tags. Ignored at the moment.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "response_type" $response_type "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "response_mode" $response_mode "scalar") (serialize-qp "nonce" $nonce "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "prompt" $prompt "scalar") (serialize-qp "max_age" $max_age "scalar") (serialize-qp "ui_locales" $ui_locales "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List clients
#
# GET /client
# operationId: client
export def "client list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<application_type: string, client_id: string, client_name: string, client_uri: string, contacts: list<string>, default_max_age: int, default_scopes: list<string>, grant_types: list<string>, logo_uri: string, policy_uri: string, redirect_uris: list<string>, response_types: list<string>, tos_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a client
#
# POST /client
# Docs: http://openid.net/specs/openid-connect-registration-1_0.html#ClientRegistration — OIDC Client Registration Endpoint
# operationId: createClient
export def "client create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --application-type: string
  --client-id: string
  client_name: string
  client_uri: string
  --contacts: list<string>
  --default-max-age: int # format: int64
  --default-scopes: list<string>
  --grant-types: list<string>
  --logo-uri: string
  --policy-uri: string
  --redirect-uris: list<string>
  --response-types: list<string>
  --tos-uri: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client")
  let req_body = {"application_type": $application_type, "client_id": $client_id, "client_name": $client_name, "client_uri": $client_uri, "contacts": $contacts, "default_max_age": $default_max_age, "default_scopes": $default_scopes, "grant_types": $grant_types, "logo_uri": $logo_uri, "policy_uri": $policy_uri, "redirect_uris": $redirect_uris, "response_types": $response_types, "tos_uri": $tos_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a client
#
# DELETE /client/{client_id}
# Docs: http://openid.net/specs/openid-connect-registration-1_0.html#ClientConfigurationEndpoint — OIDC Client Configuration Endpoint
# operationId: clientClient_id
export def "client delete" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/client/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a client
#
# GET /client/{client_id}
# Docs: http://openid.net/specs/openid-connect-registration-1_0.html#ClientConfigurationEndpoint — OIDC Client Configuration Endpoint
# operationId: getClient
export def "client get" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<application_type: string, client_id: string, client_name: string, client_uri: string, contacts: list<string>, default_max_age: int, default_scopes: list<string>, grant_types: list<string>, logo_uri: string, policy_uri: string, redirect_uris: list<string>, response_types: list<string>, tos_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/client/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a client
#
# PUT /client/{client_id}
# Docs: http://openid.net/specs/openid-connect-registration-1_0.html#ClientConfigurationEndpoint — OIDC Client Configuration Endpoint
# operationId: updateClient
export def "client update" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --application-type: string
  --body-client-id: string
  client_name: string
  client_uri: string
  --contacts: list<string>
  --default-max-age: int # format: int64
  --default-scopes: list<string>
  --grant-types: list<string>
  --logo-uri: string
  --policy-uri: string
  --redirect-uris: list<string>
  --response-types: list<string>
  --tos-uri: string
]: any -> record<application_type: string, client_id: string, client_name: string, client_uri: string, contacts: list<string>, default_max_age: int, default_scopes: list<string>, grant_types: list<string>, logo_uri: string, policy_uri: string, redirect_uris: list<string>, response_types: list<string>, tos_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/client/{client_id}"))
  let req_body = {"application_type": $application_type, "client_id": $body_client_id, "client_name": $client_name, "client_uri": $client_uri, "contacts": $contacts, "default_max_age": $default_max_age, "default_scopes": $default_scopes, "grant_types": $grant_types, "logo_uri": $logo_uri, "policy_uri": $policy_uri, "redirect_uris": $redirect_uris, "response_types": $response_types, "tos_uri": $tos_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Obtain an ID Token
#
# POST /token
# Docs: http://openid.net/specs/openid-connect-core-1_0.html#TokenEndpoint — OIDC Token Endpoint
# operationId: token
export def "token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # HTTP Basic authorization header.
  client_id: string # The registered client ID.
  client_secret: string # The registered client ID secret. (format: password)
  code: string # The authorization code previously obtained from the Authentication endpoint.
  grant_type: string # The authorization grant type, must be `authorization_code`.
  redirect_uri: string # The redirect URL that was used previously with the Authentication endpoint.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token")
  let req_body = {"client_id": $client_id, "client_secret": $client_secret, "code": $code, "grant_type": $grant_type, "redirect_uri": $redirect_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a user profile
#
# GET /userinfo
# Docs: http://openid.net/specs/openid-connect-core-1_0.html#UserInfo — OIDC UserInfo Endpoint
# operationId: userInfo
export def "userinfo get-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Include a session iframe
#
# GET /{client_id}/iframe
# Docs: http://openid.net/specs/openid-connect-session-1_0.html#OPiframe — OIDC OP Session Management Iframe
# operationId: authorizeIframe
export def "iframe get-authorize" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/{client_id}/iframe"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
