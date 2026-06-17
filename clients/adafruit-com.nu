# Auto-generated client for Adafruit IO REST API v2.0.0
# Source: https://api.apis.guru/v2/specs/adafruit.com/2.0.0/swagger.json
# Auth: --token flag or $env.ADAFRUIT_IO_REST_API_TOKEN

const BASE_URL = "https://io.adafruit.com/api/v2"
const DEFAULT_AUTH = "x-aio-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADAFRUIT_IO_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-aio-key" => { {headers: {X-AIO-Key: $token_val}, query: ""} }
    "x-aio-signature" => { {headers: {X-AIO-Signature: $token_val}, query: ""} }
    "query-X-AIO-Key" => { {headers: {}, query: $"X-AIO-Key=($token_val)"} }
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

def base-url-completer [] { ["https://io.adafruit.com/api/v2" "http://io.adafruit.com/api/v2"] }
def auth-scheme-completer [] { ["x-aio-key" "x-aio-signature" "query-X-AIO-Key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/csv"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "user currentUser" } } | get name | first)
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

# Get information about the current user
#
# GET /user
# operationId: currentUser
export def "user currentUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<color: string, created_at: string, id: float, name: string, time_zone: string, updated_at: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send data to a feed via webhook URL.
#
# POST /webhooks/feed/:token
# operationId: createWebhookFeedData
export def "webhooks-feed-token create-webhook-feed-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --value: string
]: any -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/feed/:token")
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send arbitrary data to a feed via webhook URL.
#
# POST /webhooks/feed/:token/raw
# operationId: createRawWebhookFeedData
export def "webhooks-feed-token-raw create-raw-webhook-feed-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/feed/:token/raw")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All activities for current user
#
# DELETE /{username}/activities
# operationId: destroyActivities
export def "activities delete" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/activities"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All activities for current user
#
# GET /{username}/activities
# operationId: allActivities
export def "activities allActivities" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> table<action: string, created_at: string, data: record, id: float, model: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/activities") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get activities by type for current user
#
# GET /{username}/activities/{type}
# operationId: getActivity
export def "activities get-activity" [
  username: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> table<action: string, created_at: string, data: record, id: float, model: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, type: $type} | format pattern "/{username}/activities/{type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All dashboards for current user
#
# GET /{username}/dashboards
# operationId: allDashboards
export def "dashboards allDashboards" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<blocks: list<record>, description: string, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/dashboards"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Dashboard
#
# POST /{username}/dashboards
# operationId: createDashboard
export def "dashboards create" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/dashboards"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All blocks for current user
#
# GET /{username}/dashboards/{dashboard_id}/blocks
# operationId: allBlocks
export def "dashboards-blocks allBlocks" [
  username: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<block_feeds: list<record>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, dashboard_id: $dashboard_id} | format pattern "/{username}/dashboards/{dashboard_id}/blocks"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Block
#
# POST /{username}/dashboards/{dashboard_id}/blocks
# operationId: createBlock
export def "dashboards-blocks create" [
  username: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, dashboard_id: $dashboard_id} | format pattern "/{username}/dashboards/{dashboard_id}/blocks"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing Block
#
# DELETE /{username}/dashboards/{dashboard_id}/blocks/{id}
# operationId: destroyBlock
export def "dashboards-blocks delete" [
  username: string
  dashboard_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, dashboard_id: $dashboard_id, id: $id} | format pattern "/{username}/dashboards/{dashboard_id}/blocks/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Block based on ID
#
# GET /{username}/dashboards/{dashboard_id}/blocks/{id}
# operationId: getBlock
export def "dashboards-blocks get" [
  username: string
  dashboard_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, dashboard_id: $dashboard_id, id: $id} | format pattern "/{username}/dashboards/{dashboard_id}/blocks/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties of an existing Block
#
# PATCH /{username}/dashboards/{dashboard_id}/blocks/{id}
# operationId: updateBlock
export def "dashboards-blocks update-by-username-dashboard_id-id" [
  username: string
  dashboard_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, dashboard_id: $dashboard_id, id: $id} | format pattern "/{username}/dashboards/{dashboard_id}/blocks/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace an existing Block
#
# PUT /{username}/dashboards/{dashboard_id}/blocks/{id}
# operationId: replaceBlock
export def "dashboards-blocks update-by-username-dashboard_id-id-1" [
  username: string
  dashboard_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, dashboard_id: $dashboard_id, id: $id} | format pattern "/{username}/dashboards/{dashboard_id}/blocks/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing Dashboard
#
# DELETE /{username}/dashboards/{id}
# operationId: destroyDashboard
export def "dashboards delete" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/dashboards/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Dashboard based on ID
#
# GET /{username}/dashboards/{id}
# operationId: getDashboard
export def "dashboards get" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/dashboards/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties of an existing Dashboard
#
# PATCH /{username}/dashboards/{id}
# operationId: updateDashboard
export def "dashboards update-by-username-id" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/dashboards/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace an existing Dashboard
#
# PUT /{username}/dashboards/{id}
# operationId: replaceDashboard
export def "dashboards update-by-username-id-1" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/dashboards/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All feeds for current user
#
# GET /{username}/feeds
# operationId: allFeeds
export def "feeds allFeeds" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created_at: string, description: string, details: record<data: record, shared_with: list>, enabled: bool, group: record, groups: list<record>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/feeds"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Feed
#
# POST /{username}/feeds
# operationId: createFeed
export def "feeds create" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --group-key: string
]: nothing -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group_key" $group_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/feeds") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing Feed
#
# DELETE /{username}/feeds/{feed_key}
# operationId: destroyFeed
export def "feeds delete" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get feed by feed key
#
# GET /{username}/feeds/{feed_key}
# operationId: getFeed
export def "feeds get" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties of an existing Feed
#
# PATCH /{username}/feeds/{feed_key}
# operationId: updateFeed
export def "feeds update-by-username-feed_key" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace an existing Feed
#
# PUT /{username}/feeds/{feed_key}
# operationId: replaceFeed
export def "feeds update-by-username-feed_key-1" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all data for the given feed
#
# GET /{username}/feeds/{feed_key}/data
# operationId: allData
export def "feeds-data allData" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`. 
]: nothing -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Data
#
# POST /{username}/feeds/{feed_key}/data
# operationId: createData
export def "feeds-data create" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple new Data records
#
# POST /{username}/feeds/{feed_key}/data/batch
# operationId: batchCreateData
export def "feeds-data-batch batchCreateData" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data/batch"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Chart data for current feed
#
# GET /{username}/feeds/{feed_key}/data/chart
# operationId: chartData
export def "feeds-data-chart chartData" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --resolution: int # A resolution size in minutes. By giving a resolution value you will get back grouped data points aggregated over resolution-sized intervals. NOTE: time span is preferred over resolution, so if you request a span of time that includes more than max limit points you may get a larger resolution than you requested. Valid resolutions are 1, 5, 10, 30, 60, and 120. (format: int32)
  --hours: int # The number of hours the chart should cover. (format: int32)
]: nothing -> record<columns: list<string>, data: list<list<string>>, feed: record<id: int, key: string, name: string>, parameters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "hours" $hours "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data/chart") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# First Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/first
# operationId: firstData
export def "feeds-data-first firstData" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`. 
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data/first") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Last Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/last
# operationId: lastData
export def "feeds-data-last lastData" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`. 
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data/last") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Next Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/next
# operationId: nextData
export def "feeds-data-next nextData" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`. 
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data/next") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Previous Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/previous
# operationId: previousData
export def "feeds-data-previous previousData" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`. 
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data/previous") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Last Data in MQTT CSV format
#
# GET /{username}/feeds/{feed_key}/data/retain
# operationId: retainData
export def "feeds-data-retain retainData" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/data/retain"))
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete existing Data
#
# DELETE /{username}/feeds/{feed_key}/data/{id}
# operationId: destroyData
export def "feeds-data delete" [
  username: string
  feed_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key, id: $id} | format pattern "/{username}/feeds/{feed_key}/data/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns data based on feed key
#
# GET /{username}/feeds/{feed_key}/data/{id}
# operationId: getData
export def "feeds-data get" [
  username: string
  feed_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`. 
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key, id: $id} | format pattern "/{username}/feeds/{feed_key}/data/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties of existing Data
#
# PATCH /{username}/feeds/{feed_key}/data/{id}
# operationId: updateData
export def "feeds-data update-by-username-feed_key-id" [
  username: string
  feed_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key, id: $id} | format pattern "/{username}/feeds/{feed_key}/data/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace existing Data
#
# PUT /{username}/feeds/{feed_key}/data/{id}
# operationId: replaceData
export def "feeds-data update-by-username-feed_key-id-1" [
  username: string
  feed_key: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key, id: $id} | format pattern "/{username}/feeds/{feed_key}/data/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get detailed feed by feed key
#
# GET /{username}/feeds/{feed_key}/details
# operationId: getFeedDetails
export def "feeds-details get" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, feed_key: $feed_key} | format pattern "/{username}/feeds/{feed_key}/details"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All groups for current user
#
# GET /{username}/groups
# operationId: allGroups
export def "groups allGroups" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created_at: string, description: string, feeds: list<record>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/groups"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Group
#
# POST /{username}/groups
# operationId: createGroup
export def "groups create" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/groups"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing Group
#
# DELETE /{username}/groups/{group_key}
# operationId: destroyGroup
export def "groups delete" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Group based on ID
#
# GET /{username}/groups/{group_key}
# operationId: getGroup
export def "groups get" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties of an existing Group
#
# PATCH /{username}/groups/{group_key}
# operationId: updateGroup
export def "groups update-by-username-group_key" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace an existing Group
#
# PUT /{username}/groups/{group_key}
# operationId: replaceGroup
export def "groups update-by-username-group_key-1" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an existing Feed to a Group
#
# POST /{username}/groups/{group_key}/add
# operationId: addFeedToGroup
export def "groups-add create-feed-to" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --feed-key: string
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_key" $feed_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}/add") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new data for multiple feeds in a group
#
# POST /{username}/groups/{group_key}/data
# operationId: createGroupData
export def "groups-data create" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}/data"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All feeds for current user in a given group
#
# GET /{username}/groups/{group_key}/feeds
# operationId: allGroupFeeds
export def "groups-feeds allGroupFeeds" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created_at: string, description: string, details: record<data: record, shared_with: list>, enabled: bool, group: record, groups: list<record>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}/feeds"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Feed in a Group
#
# POST /{username}/groups/{group_key}/feeds
# operationId: createGroupFeed
export def "groups-feeds create" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}/feeds"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All data for current feed in a specific group
#
# GET /{username}/groups/{group_key}/feeds/{feed_key}/data
# operationId: allGroupFeedData
export def "groups-feeds-data allGroupFeedData" [
  username: string
  group_key: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start-time: string # Start time for filtering data. Returns data created after given time. (format: date-time)
  --end-time: string # End time for filtering data. Returns data created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, group_key: $group_key, feed_key: $feed_key} | format pattern "/{username}/groups/{group_key}/feeds/{feed_key}/data") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Data in a feed belonging to a particular group
#
# POST /{username}/groups/{group_key}/feeds/{feed_key}/data
# operationId: createGroupFeedData
export def "groups-feeds-data create" [
  username: string
  group_key: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key, feed_key: $feed_key} | format pattern "/{username}/groups/{group_key}/feeds/{feed_key}/data"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple new Data records in a feed belonging to a particular group
#
# POST /{username}/groups/{group_key}/feeds/{feed_key}/data/batch
# operationId: batchCreateGroupFeedData
export def "groups-feeds-data-batch batchCreateGroupFeedData" [
  username: string
  group_key: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, group_key: $group_key, feed_key: $feed_key} | format pattern "/{username}/groups/{group_key}/feeds/{feed_key}/data/batch"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Feed from a Group
#
# POST /{username}/groups/{group_key}/remove
# operationId: removeFeedFromGroup
export def "groups-remove delete-feed-from" [
  username: string
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --feed-key: string
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_key" $feed_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: $username, group_key: $group_key} | format pattern "/{username}/groups/{group_key}/remove") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the user's data rate limit and current activity level.
#
# GET /{username}/throttle
# operationId: getCurrentUserThrottle
export def "throttle get-current-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<active_data_rate: int, data_rate_limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/throttle"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All tokens for current user
#
# GET /{username}/tokens
# operationId: allTokens
export def "tokens allTokens" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/tokens"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Token
#
# POST /{username}/tokens
# operationId: createToken
export def "tokens create" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/tokens"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing Token
#
# DELETE /{username}/tokens/{id}
# operationId: destroyToken
export def "tokens delete" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/tokens/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Token based on ID
#
# GET /{username}/tokens/{id}
# operationId: getToken
export def "tokens get" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/tokens/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties of an existing Token
#
# PATCH /{username}/tokens/{id}
# operationId: updateToken
export def "tokens update-by-username-id" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/tokens/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace an existing Token
#
# PUT /{username}/tokens/{id}
# operationId: replaceToken
export def "tokens update-by-username-id-1" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/tokens/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All triggers for current user
#
# GET /{username}/triggers
# operationId: allTriggers
export def "triggers allTriggers" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/triggers"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Trigger
#
# POST /{username}/triggers
# operationId: createTrigger
export def "triggers create" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/{username}/triggers"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing Trigger
#
# DELETE /{username}/triggers/{id}
# operationId: destroyTrigger
export def "triggers delete" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/triggers/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Trigger based on ID
#
# GET /{username}/triggers/{id}
# operationId: getTrigger
export def "triggers get" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/triggers/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties of an existing Trigger
#
# PATCH /{username}/triggers/{id}
# operationId: updateTrigger
export def "triggers update-by-username-id" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/triggers/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace an existing Trigger
#
# PUT /{username}/triggers/{id}
# operationId: replaceTrigger
export def "triggers update-by-username-id-1" [
  username: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, id: $id} | format pattern "/{username}/triggers/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All permissions for current user and type
#
# GET /{username}/{type}/{type_id}/acl
# operationId: allPermissions
export def "acl allPermissions" [
  username: string
  type: string
  type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, type: $type, type_id: $type_id} | format pattern "/{username}/{type}/{type_id}/acl"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Permission
#
# POST /{username}/{type}/{type_id}/acl
# operationId: createPermission
export def "acl create-permission" [
  username: string
  type: string
  type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, type: $type, type_id: $type_id} | format pattern "/{username}/{type}/{type_id}/acl"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing Permission
#
# DELETE /{username}/{type}/{type_id}/acl/{id}
# operationId: destroyPermission
export def "acl delete-permission" [
  username: string
  type: string
  type_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, type: $type, type_id: $type_id, id: $id} | format pattern "/{username}/{type}/{type_id}/acl/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Permission based on ID
#
# GET /{username}/{type}/{type_id}/acl/{id}
# operationId: getPermission
export def "acl get-permission" [
  username: string
  type: string
  type_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, type: $type, type_id: $type_id, id: $id} | format pattern "/{username}/{type}/{type_id}/acl/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update properties of an existing Permission
#
# PATCH /{username}/{type}/{type_id}/acl/{id}
# operationId: updatePermission
export def "acl update-permission-by-username-type-type_id-id" [
  username: string
  type: string
  type_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, type: $type, type_id: $type_id, id: $id} | format pattern "/{username}/{type}/{type_id}/acl/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace an existing Permission
#
# PUT /{username}/{type}/{type_id}/acl/{id}
# operationId: replacePermission
export def "acl update-permission-by-username-type-type_id-id-1" [
  username: string
  type: string
  type_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username, type: $type, type_id: $type_id, id: $id} | format pattern "/{username}/{type}/{type_id}/acl/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
