# Auto-generated client for Turbine Labs API v1.0
# Source: https://api.apis.guru/v2/specs/turbinelabs.io/1.0/swagger.json
# Auth: --token flag or $env.TURBINE_LABS_API_TOKEN

const BASE_URL = "https://api.turbinelabs.io/v1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TURBINE_LABS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.turbinelabs.io/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["after" "before"] }
def protocol-completer [] { ["http" "http2" "http_auto" "tcp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-user-self get" } } | get name | first)
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

# Returns the user object for the account authorized and making this request.
#
# GET /admin/user/self
export def "admin-user-self get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<checksum: string, deleted_at: string, login_email: string, user_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/user/self")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the specified access token.
#
# DELETE /admin/user/self/access_token/{access-token-key}
export def "admin-user-self-access-token delete" [
  access_token_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the user to be modified (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record<code: int, fields: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/user/self/access_token/($access_token_key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists Access Tokens that are configured for the authenticated user.
#
# GET /admin/user/self/access_tokens
export def "admin-user-self-access-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: table<access_token_key: string, checksum: string, created_at: string, description: string, signed_token: string, user_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/user/self/access_tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Access Token and associates it with the authenticated user.
#
# POST /admin/user/self/access_tokens
export def "admin-user-self-access-tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
]: any -> record<access_token_key: string, checksum: string, created_at: string, description: string, signed_token: string, user_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/user/self/access_tokens")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Allows an arbitrary filter to be specified and applied to the org\'s change log.
#
# GET /changelog/adhoc
export def "changelog-adhoc get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Encoded FilterSums representing the query you would like to execute. See object definition for details.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/changelog/adhoc" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get changes related to the indicated cluster
#
# GET /changelog/cluster-graph/{clusterKey}
export def "changelog-cluster-graph get" [
  clusterKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code.  (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/changelog/cluster-graph/($clusterKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get changes related to the indicated domain
#
# GET /changelog/domain-graph/{domainKey}
export def "changelog-domain-graph get" [
  domainKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code.  (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/changelog/domain-graph/($domainKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get changes related to the indicated route
#
# GET /changelog/route-graph/{routeKey}
export def "changelog-route-graph get" [
  routeKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code.  (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/changelog/route-graph/($routeKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get changes related to the indicated SharedRules
#
# GET /changelog/shared-rules-graph/{sharedRulesKey}
export def "changelog-shared-rules-graph get" [
  sharedRulesKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code.  (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/changelog/shared-rules-graph/($sharedRulesKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get changes in a specified zone
#
# GET /changelog/zone/{zoneKey}
export def "changelog-zone get" [
  zoneKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch.  (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code.  (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/changelog/zone/($zoneKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get clusters
#
# GET /cluster
export def "cluster list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ClusterFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ClusterFilter will be included.
]: nothing -> record<result: table<circuit_breakers: record, health_checks: list, instances: list, name: string, outlier_detection: record, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cluster" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create cluster
#
# POST /cluster
# --circuit_breakers shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
# --health_checks item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
# --instances item shape: {host?: string, metadata?: list, port?: int}
# --outlier_detection shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
export def "cluster post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --circuit-breakers: record # Provides limits on various parameters to protect clusters against sudden surges in traffic. — shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
  --health-checks: list # item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
  --instances: list # item shape: {host?: string, metadata?: list, port?: int}
  name: string
  --outlier-detection: record # A form of passive health checking that dynamically determines whether instances in a cluster are performing unlike others and preemptively removes them from a load balancing set. — shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
  --require-tls: oneof<nothing, bool> # If set, requests to this collection of hosts will be made via HTTPS. At this time neither certificate validation and certificate pinning are supported for proxy clients of this cluster.
  zone_key: string
]: any -> record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster")
  let body = {circuit_breakers: $circuit_breakers, health_checks: $health_checks, instances: $instances, name: $name, outlier_detection: $outlier_detection, require_tls: $require_tls, zone_key: $zone_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete cluster
#
# DELETE /cluster/{clusterKey}
export def "cluster delete" [
  clusterKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the cluster to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cluster/($clusterKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get cluster
#
# GET /cluster/{clusterKey}
export def "cluster get" [
  clusterKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cluster/($clusterKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify cluster
#
# PUT /cluster/{clusterKey}
# --circuit_breakers shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
# --health_checks item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
# --instances item shape: {host?: string, metadata?: list, port?: int}
# --outlier_detection shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
export def "cluster put" [
  clusterKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --circuit-breakers: record # Provides limits on various parameters to protect clusters against sudden surges in traffic. — shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
  --health-checks: list # item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
  --instances: list # item shape: {host?: string, metadata?: list, port?: int}
  name: string
  --outlier-detection: record # A form of passive health checking that dynamically determines whether instances in a cluster are performing unlike others and preemptively removes them from a load balancing set. — shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
  --require-tls: oneof<nothing, bool> # If set, requests to this collection of hosts will be made via HTTPS. At this time neither certificate validation and certificate pinning are supported for proxy clients of this cluster.
  zone_key: string
  checksum: string
  cluster_key: string
]: any -> record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cluster/($clusterKey)")
  let body = {circuit_breakers: $circuit_breakers, health_checks: $health_checks, instances: $instances, name: $name, outlier_detection: $outlier_detection, require_tls: $require_tls, zone_key: $zone_key, checksum: $checksum, cluster_key: $cluster_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# add instance
#
# POST /cluster/{clusterKey}/instances
# --metadata item shape: {key?: string, value?: string}
export def "cluster-instances post" [
  clusterKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string
  --metadata: list # item shape: {key?: string, value?: string}
  --port: int
]: any -> record<result: record<host: string, metadata: list<record>, port: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cluster/($clusterKey)/instances")
  let body = {host: $host, metadata: $metadata, port: $port} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# remove instance
#
# DELETE /cluster/{clusterKey}/instances/{instanceIdentifier}
export def "cluster-instances delete" [
  clusterKey: string
  instanceIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the instance to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cluster/($clusterKey)/instances/($instanceIdentifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get domains
#
# GET /domain
export def "domain list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of DomainFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any DomainFilter will be included.
]: nothing -> record<result: table<aliases: list, checksum: string, cors_config: record, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list, ssl_config: record, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create domain
#
# POST /domain
# --cors_config shape: {allow_credentials?: bool, allowed_headers?: list, allowed_methods: list, allowed_origins: list, exposed_headers?: list, max_age?: int}
# --redirects item shape: {from: string, header_constraints?: list, name: string, redirect_type: "permanent"|"temporary", to: string}
# --ssl_config shape: {cert_key_pairs: list, cipher_filter?: string, protocols?: list}
export def "domain post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: list # A set of alternate names that this Domain may be referenced by. May start ('*.') or end ('.*') with a wildcard.
  --checksum: string
  --cors-config: record # Experimental: Controls simple CORS responses for the associated domain. The configurable properties map closely to the CORS specification which should be referenced for a full discussion on their meaning: https://www.w3.org/TR/cors/ or https://developer.mozilla.org/docs/Web/HTTP/Access_control_CORS. — shape: {allow_credentials?: bool, allowed_headers?: list, allowed_methods: list, allowed_origins: list, exposed_headers?: list, max_age?: int}
  --domain-key: string
  --force-https: oneof<nothing, bool> # If set to true, requests must use TLS. If a request is not using TLS, (as determined by the scheme or the presence of X-Forwarded-Proto header), a 301 redirect will be sent telling the client to use HTTPS.
  --gzip-enabled: oneof<nothing, bool> # Experimental: if set to true will enable gzip compression on data that passes trough this domain
  name: string
  port: int
  --redirects: list # item shape: {from: string, header_constraints?: list, name: string, redirect_type: "permanent"|"temporary", to: string}
  --ssl-config: record # Experimental: Specifies whether a domain should support SSL/TLS connections from clients.  If not set the proxy will expect unencrypted HTTP traffic. — shape: {cert_key_pairs: list, cipher_filter?: string, protocols?: list}
  zone_key: string
]: any -> record<result: record<aliases: list<string>, checksum: string, cors_config: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, exposed_headers: list, max_age: int>, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list<record>, ssl_config: record<cert_key_pairs: list, cipher_filter: string, protocols: list>, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domain")
  let body = {aliases: $aliases, checksum: $checksum, cors_config: $cors_config, domain_key: $domain_key, force_https: $force_https, gzip_enabled: $gzip_enabled, name: $name, port: $port, redirects: $redirects, ssl_config: $ssl_config, zone_key: $zone_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete domain
#
# DELETE /domain/{domainKey}
export def "domain delete" [
  domainKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the domain to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/domain/($domainKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get domain
#
# GET /domain/{domainKey}
export def "domain get" [
  domainKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<aliases: list<string>, checksum: string, cors_config: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, exposed_headers: list, max_age: int>, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list<record>, ssl_config: record<cert_key_pairs: list, cipher_filter: string, protocols: list>, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domain/($domainKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# list listeners
#
# GET /listener
export def "listener list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ListenerFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ListenerFilter will be included.
]: nothing -> record<result: table<domain_keys: list, ip: string, name: string, port: int, protocol: string, tracing_config: record, zone_key: string, checksum: string, listener_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listener" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create listener
#
# POST /listener
# --tracing_config shape: {ingress?: bool, request_headers_for_tags?: list}
export def "listener post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list
  --ip: string # the interface this listener should bind to.
  name: string
  port: int # the port this listener should bind to.
  protocol: string@protocol-completer # the protocol this listener will handle. http and http2 configure the listener to only process requests of that type. http_auto will adapt to HTTP/1.1 and HTTP/2 as needed. tcp configures the listener to be a tcp proxy
  --tracing-config: record # Configures tracing operations to be performed on the given listener — shape: {ingress?: bool, request_headers_for_tags?: list}
  --zone-key: string
]: any -> record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/listener")
  let body = {domain_keys: $domain_keys, ip: $ip, name: $name, port: $port, protocol: $protocol, tracing_config: $tracing_config, zone_key: $zone_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete listener
#
# DELETE /listener/{listenerKey}
export def "listener delete" [
  listenerKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the listener to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list<string>>, zone_key: string, checksum: string, listener_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/listener/($listenerKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get listener
#
# GET /listener/{listenerKey}
export def "listener get" [
  listenerKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/listener/($listenerKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify listener
#
# PUT /listener/{listenerKey}
# --tracing_config shape: {ingress?: bool, request_headers_for_tags?: list}
export def "listener put" [
  listenerKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list
  --ip: string # the interface this listener should bind to.
  name: string
  port: int # the port this listener should bind to.
  protocol: string@protocol-completer # the protocol this listener will handle. http and http2 configure the listener to only process requests of that type. http_auto will adapt to HTTP/1.1 and HTTP/2 as needed. tcp configures the listener to be a tcp proxy
  --tracing-config: record # Configures tracing operations to be performed on the given listener — shape: {ingress?: bool, request_headers_for_tags?: list}
  zone_key: string
  checksum: string
  listener_key: string
]: any -> record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/listener/($listenerKey)")
  let body = {domain_keys: $domain_keys, ip: $ip, name: $name, port: $port, protocol: $protocol, tracing_config: $tracing_config, zone_key: $zone_key, checksum: $checksum, listener_key: $listener_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# list proxies
#
# GET /proxy
export def "proxy list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ProxyFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ProxyFilter will be included.
]: nothing -> record<result: table<domain_keys: list, listener_keys: list, name: string, zone_key: string, checksum: string, proxy_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proxy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create proxy
#
# POST /proxy
export def "proxy post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list
  --listener-keys: list
  name: string
  zone_key: string
]: any -> record<result: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/proxy")
  let body = {domain_keys: $domain_keys, listener_keys: $listener_keys, name: $name, zone_key: $zone_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete proxy
#
# DELETE /proxy/{proxyKey}
export def "proxy delete" [
  proxyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the proxy to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/proxy/($proxyKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get proxy
#
# GET /proxy/{proxyKey}
export def "proxy get" [
  proxyKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/proxy/($proxyKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get routes
#
# GET /route
export def "route list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of RouteFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any RouteFilter will be included.
]: nothing -> record<result: table<checksum: string, cohort_seed: record, domain_key: string, path: string, response_data: record, retry_policy: record, route_key: string, rules: list, shared_rules_key: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/route" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create route
#
# POST /route
# --cohort_seed shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
# --retry_policy shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
# --rules item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list, rule_key?: string}
export def "route post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  domain_key: string
  path: string
  --response-data: any # When a request is served by this Route annotate the response with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from Route take precedence over those from a SharedRules object.
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --route-key: string
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list, rule_key?: string}
  shared_rules_key: string
  zone_key: string
]: any -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/route")
  let body = {checksum: $checksum, cohort_seed: $cohort_seed, domain_key: $domain_key, path: $path, response_data: $response_data, retry_policy: $retry_policy, route_key: $route_key, rules: $rules, shared_rules_key: $shared_rules_key, zone_key: $zone_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete route
#
# DELETE /route/{routeKey}
export def "route delete" [
  routeKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the route to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/route/($routeKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get route
#
# GET /route/{routeKey}
export def "route get" [
  routeKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/route/($routeKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify route
#
# PUT /route/{routeKey}
# --cohort_seed shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
# --retry_policy shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
# --rules item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list, rule_key?: string}
export def "route put" [
  routeKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  domain_key: string
  path: string
  --response-data: any # When a request is served by this Route annotate the response with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from Route take precedence over those from a SharedRules object.
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  route_key: string
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list, rule_key?: string}
  shared_rules_key: string
  zone_key: string
]: any -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/route/($routeKey)")
  let body = {checksum: $checksum, cohort_seed: $cohort_seed, domain_key: $domain_key, path: $path, response_data: $response_data, retry_policy: $retry_policy, route_key: $route_key, rules: $rules, shared_rules_key: $shared_rules_key, zone_key: $zone_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# get shared_rules
#
# GET /shared_rules
export def "shared-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of SharedRulesFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any SharedRulesFilter will be included.
]: nothing -> record<result: table<checksum: string, cohort_seed: record, default: record, properties: list, response_data: record, retry_policy: record, rules: list, shared_rules_key: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create shared_rules
#
# POST /shared_rules
# --cohort_seed shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
# --default shape: {dark?: list, light: list, tap?: list}
# --properties item shape: {key?: string, value?: string}
# --retry_policy shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
# --rules item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list, rule_key?: string}
export def "shared-rules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  default: record # shape: {dark?: list, light: list, tap?: list}
  --properties: list # item shape: {key?: string, value?: string}
  --response-data: any # When a request is served by a Route that is part of this SharedRules group the response is annotated with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from the applicable Route and ClusterConstarint takes precedence over those specified here.
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list, rule_key?: string}
  --shared-rules-key: string
  zone_key: string
]: any -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shared_rules")
  let body = {checksum: $checksum, cohort_seed: $cohort_seed, default: $default, properties: $properties, response_data: $response_data, retry_policy: $retry_policy, rules: $rules, shared_rules_key: $shared_rules_key, zone_key: $zone_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete shared_rules object
#
# DELETE /shared_rules/{sharedRulesKey}
export def "shared-rules delete" [
  sharedRulesKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the shared_rules to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shared_rules/($sharedRulesKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get shared_rules object
#
# GET /shared_rules/{sharedRulesKey}
export def "shared-rules get" [
  sharedRulesKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shared_rules/($sharedRulesKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# modify shared_rules object
#
# PUT /shared_rules/{sharedRulesKey}
# --cohort_seed shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
# --default shape: {dark?: list, light: list, tap?: list}
# --properties item shape: {key?: string, value?: string}
# --retry_policy shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
# --rules item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list, rule_key?: string}
export def "shared-rules put" [
  sharedRulesKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  default: record # shape: {dark?: list, light: list, tap?: list}
  --properties: list # item shape: {key?: string, value?: string}
  --response-data: any # When a request is served by a Route that is part of this SharedRules group the response is annotated with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from the applicable Route and ClusterConstarint takes precedence over those specified here.
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list, rule_key?: string}
  shared_rules_key: string
  zone_key: string
]: any -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shared_rules/($sharedRulesKey)")
  let body = {checksum: $checksum, cohort_seed: $cohort_seed, default: $default, properties: $properties, response_data: $response_data, retry_policy: $retry_policy, rules: $rules, shared_rules_key: $shared_rules_key, zone_key: $zone_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# get a list of zones
#
# GET /zone
export def "zone list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ZoneFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ZoneFilter will be included.
]: nothing -> record<result: table<checksum: string, name: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/zone" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create zone
#
# POST /zone
export def "zone post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<result: record<checksum: string, name: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/zone")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# delete zone
#
# DELETE /zone/{zoneKey}
export def "zone delete" [
  zoneKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the zone to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zone/($zoneKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get zone
#
# GET /zone/{zoneKey}
export def "zone get" [
  zoneKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<checksum: string, name: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/zone/($zoneKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
