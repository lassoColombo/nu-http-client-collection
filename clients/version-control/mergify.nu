# Auto-generated client for Mergify API vv1
# Source: https://api.mergify.com/v1/openapi.json
# Auth: --token flag or $env.MERGIFY_API_TOKEN

const BASE_URL = "http://localhost/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MERGIFY_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost/v1" "https://api.mergify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["executions_count" "failed_executions_impact" "failed_executions_ratio" "health_confidence" "health_status" "job_name" "pipeline_name" "test_name"] }
def direction-completer [] { ["asc" "desc"] }
def sort-completer-1 [] { ["executions_count" "job_name" "pipeline_name"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "application get" } } | get name | first)
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

# Get current application
#
# GET /application
# operationId: application_application_get
export def "application get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, account_scope: record<id: int, login: string>, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get merge queues configuration
#
# GET /repos/{owner}/{repository}/queues/configuration
# DEPRECATED
# operationId: repository_queues_configuration_repos__owner___repository__queues_configuration_get
@deprecated
export def "repos-queues-configuration get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<configuration: table<name: string, config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/queues/configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause the merge queue
#
# PUT /repos/{owner}/{repository}/queue/pause
# DEPRECATED
# operationId: create_queue_pause_repos__owner___repository__queue_pause_put
@deprecated
export def "repos-queue-pause put" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  reason: string # The reason of the queue pause
]: any -> record<queue_pause: table<reason: string, pause_date: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/queue/pause")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unpause merge queue
#
# DELETE /repos/{owner}/{repository}/queue/pause
# DEPRECATED
# operationId: delete_queue_pause_repos__owner___repository__queue_pause_delete
@deprecated
export def "repos-queue-pause delete" [
  owner: string
  repository: string
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
  let full_url = (build-url $base $"/repos/($owner)/($repository)/queue/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get queue pause data
#
# GET /repos/{owner}/{repository}/queue/pause
# DEPRECATED
# operationId: get_queue_pause_repos__owner___repository__queue_pause_get
@deprecated
export def "repos-queue-pause get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<queue_pause: table<reason: string, pause_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/queue/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause merge queue
#
# POST /repos/{owner}/{repository}/queue/pause/delete
# DEPRECATED
# operationId: delete_queue_pause_repos__owner___repository__queue_pause_delete_post
@deprecated
export def "repos-queue-pause-delete post" [
  owner: string
  repository: string
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
  let full_url = (build-url $base $"/repos/($owner)/($repository)/queue/pause/delete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get merge queues
#
# GET /repos/{owner}/{repository}/queues
# DEPRECATED
# operationId: repository_queues_repos__owner___repository__queues_get
@deprecated
export def "repos-queues get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<queues: table<branch: record, pull_requests: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/queues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the base refs in the repository
#
# GET /repos/{owner}/{repository}/queues/branches
# DEPRECATED
# operationId: get_queue_base_refs_repos__owner___repository__queues_branches_get
@deprecated
export def "repos-queues-branches get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<base_refs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/queues/branches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get PNG badge
#
# GET /badges/{owner}/{repository}.png
# DEPRECATED
# operationId: badge_png_badges__owner___repository__png_get
@deprecated
export def "badges get-by-owner-repository" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --style: string # The style of the button, more details on https://shields.io/. (default: flat)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "style" $style "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/badges/($owner)/($repository).png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SVG badge
#
# GET /badges/{owner}/{repository}.svg
# DEPRECATED
# operationId: badge_svg_badges__owner___repository__svg_get
@deprecated
export def "badges get-by-owner-repository-1" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --style: string # The style of the button, more details on https://shields.io/. (default: flat)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "style" $style "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/badges/($owner)/($repository).svg" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shields.io badge config
#
# GET /badges/{owner}/{repository}
# DEPRECATED
# operationId: badge_badges__owner___repository__get
@deprecated
export def "badges get-by-owner-repository-2" [
  owner: string
  repository: string
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
  let full_url = (build-url $base $"/badges/($owner)/($repository)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Mergify simulation for a pull request
#
# POST /repos/{owner}/{repository}/pulls/{number}/simulator
# operationId: simulator_pull_repos__owner___repository__pulls__number__simulator_post
export def "repos-pulls-simulator post" [
  owner: string
  repository: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mergify_yml: string # A Mergify configuration
]: any -> record<title: string, summary: string, deprecations: table<message: string, deadline: string, path_to_field: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/pulls/($number)/simulator")
  let body = {mergify_yml: $mergify_yml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Mergify simulation for a repository
#
# POST /repos/{owner}/{repository}/simulator
# operationId: simulator_repo_repos__owner___repository__simulator_post
export def "repos-simulator post" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mergify_yml: string # A Mergify configuration
]: any -> record<title: string, summary: string, deprecations: table<message: string, deadline: string, path_to_field: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/simulator")
  let body = {mergify_yml: $mergify_yml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Mergify configuration simulation for a repository
#
# POST /repos/{owner}/{repository}/configuration-simulator
# operationId: repository_configuration_simulator_repos__owner___repository__configuration_simulator_post
export def "repos-configuration-simulator post" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mergify_yml: string # A Mergify configuration
]: any -> record<message: string, deprecations: table<message: string, deadline: string, path_to_field: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/configuration-simulator")
  let body = {mergify_yml: $mergify_yml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the events log
#
# GET /repos/{owner}/{repository}/logs
# operationId: get_repository_events_repos__owner___repository__logs_get
export def "repos-logs get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pull-request: string # Filter events by pull-request number. Repeatable to match several PRs at once (e.g. `?pull_request=1&pull_request=2`).
  --base-ref: string # Get events for PRs to the given base ref
  --event-type: string # The specific types of events to select
  --outcome: string # Filter events by derived outcome label (`success` / `failure` / `pending` / `neutral`). Repeatable to match several outcomes at once (e.g. `?outcome=success&outcome=failure`).
  --trigger: string # Include only events whose `trigger` matches one of the given values (exact match). Repeatable. Mirrors Datadog's facet behaviour after clicking `Only`: the URL switches from exclusion mode to inclusion mode with a positive list — shorter than `not_trigger=<everything else>`. Mutually exclusive with `not_trigger`.
  --not-trigger: string # Exclude events whose `trigger` matches any of the given values (exact match). Repeatable. Mirrors Datadog's facet semantics: the default state is `all triggers included`, and unchecking a trigger in the dashboard sidebar adds it to the exclusion list. Mutually exclusive with `trigger` (positive include).
  --received-from: string # Start of the time range (ISO 8601 with timezone, e.g. 2024-01-01T00:00:00Z). Defaults to `received_to - 1 day`.
  --received-to: string # End of the time range (ISO 8601 with timezone, e.g. 2024-01-01T00:00:00Z). Defaults to `now`.
  --cursor: string # The opaque cursor of the current page. Must be extracted from RFC 5988 pagination links to get first/previous/next/last pages
  --per-page: int # The number of items per page (default: 10)
]: nothing -> record<size: int, per_page: int, events: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pull_request" $pull_request "scalar") (serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "outcome" $outcome "scalar") (serialize-qp "trigger" $trigger "scalar") (serialize-qp "not_trigger" $not_trigger "scalar") (serialize-qp "received_from" $received_from "scalar") (serialize-qp "received_to" $received_to "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get aggregated event counts
#
# GET /repos/{owner}/{repository}/logs/aggregate
# operationId: get_repository_events_aggregate_repos__owner___repository__logs_aggregate_get
export def "repos-logs-aggregate get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pull-request: string # Filter events by pull-request number. Repeatable to match several PRs at once (e.g. `?pull_request=1&pull_request=2`).
  --base-ref: string # Get events for PRs to the given base ref
  --event-type: string # The specific types of events to select
  --outcome: string # Filter events by derived outcome label (`success` / `failure` / `pending` / `neutral`). Repeatable to match several outcomes at once (e.g. `?outcome=success&outcome=failure`).
  --trigger: string # Include only events whose `trigger` matches one of the given values (exact match). Repeatable. Mirrors Datadog's facet behaviour after clicking `Only`: the URL switches from exclusion mode to inclusion mode with a positive list — shorter than `not_trigger=<everything else>`. Mutually exclusive with `not_trigger`.
  --not-trigger: string # Exclude events whose `trigger` matches any of the given values (exact match). Repeatable. Mirrors Datadog's facet semantics: the default state is `all triggers included`, and unchecking a trigger in the dashboard sidebar adds it to the exclusion list. Mutually exclusive with `trigger` (positive include).
  --received-from: string # Start of the time range (ISO 8601 with timezone). Defaults to `received_to - 1 day`.
  --received-to: string # End of the time range (ISO 8601 with timezone). Defaults to `now`.
]: nothing -> record<total: int, interval_size_seconds: int, histogram: table<start: string, end: string, count: int>, by_event_type: table<value: string, count: int>, by_outcome: table<value: string, count: int>, by_trigger: table<value: string, count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pull_request" $pull_request "scalar") (serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "outcome" $outcome "scalar") (serialize-qp "trigger" $trigger "scalar") (serialize-qp "not_trigger" $not_trigger "scalar") (serialize-qp "received_from" $received_from "scalar") (serialize-qp "received_to" $received_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/logs/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Time to merge statistics for every queues and partitions
#
# GET /repos/{owner}/{repository}/stats/time_to_merge
# DEPRECATED
# operationId: get_time_to_merge_stats_for_all_queues_and_partitions_endpoint_repos__owner___repository__stats_time_to_merge_get
@deprecated
export def "repos-stats-time-to-merge get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --at: string # Retrieve the time to merge at this timestamp (ISO 8601 with timezone, e.g. 2024-01-01T00:00:00Z)
  --branch: string # The name of the branch
]: nothing -> table<partition_name: string, queues: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "at" $at "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/time_to_merge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the queue checks outcome for the repository
#
# GET /repos/{owner}/{repository}/stats/merge_queue_checks_outcome
# DEPRECATED
# operationId: get_checks_outcome_repos__owner___repository__stats_merge_queue_checks_outcome_get
@deprecated
export def "repos-stats-merge-queue-checks-outcome get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Merge queue name(s) of the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/merge_queue_checks_outcome" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the count of queue checks outcomes
#
# GET /repos/{owner}/{repository}/stats/queues_checks_outcome_count
# operationId: get_checks_outcome_by_interval_repos__owner___repository__stats_queues_checks_outcome_count_get
export def "repos-stats-queues-checks-outcome-count get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Merge queue name(s) of the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/queues_checks_outcome_count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the count of pull requests entering the queues
#
# GET /repos/{owner}/{repository}/stats/queues_entered_count
# operationId: get_queues_pull_requests_entered_count_repos__owner___repository__stats_queues_entered_count_get
export def "repos-stats-queues-entered-count get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/queues_entered_count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the count of pull requests merged by queues
#
# GET /repos/{owner}/{repository}/stats/queues_merged_count
# operationId: get_queues_pull_requests_merged_count_repos__owner___repository__stats_queues_merged_count_get
export def "repos-stats-queues-merged-count get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_names: list, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/queues_merged_count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the average CI runtime
#
# GET /repos/{owner}/{repository}/stats/average_ci_runtime
# operationId: get_average_ci_runtime_repos__owner___repository__stats_average_ci_runtime_get
export def "repos-stats-average-ci-runtime get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/average_ci_runtime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the idle queue time
#
# GET /repos/{owner}/{repository}/stats/idle_queue_time
# operationId: get_average_idle_queue_time_repos__owner___repository__stats_idle_queue_time_get
export def "repos-stats-idle-queue-time get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/idle_queue_time" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the queue time
#
# GET /repos/{owner}/{repository}/stats/total_queue_time
# operationId: get_total_queue_time_repos__owner___repository__stats_total_queue_time_get
export def "repos-stats-total-queue-time get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/total_queue_time" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the queue size
#
# GET /repos/{owner}/{repository}/stats/queue_size
# operationId: get_queue_size_repos__owner___repository__stats_queue_size_get
export def "repos-stats-queue-size get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/queue_size" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of running speculative checks
#
# GET /repos/{owner}/{repository}/stats/running_speculative_checks
# operationId: get_total_running_checks_repos__owner___repository__stats_running_speculative_checks_get
export def "repos-stats-running-speculative-checks get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Merge queue name(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/running_speculative_checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the checks batch size
#
# GET /repos/{owner}/{repository}/stats/batch_size
# operationId: get_stats_batch_size_repos__owner___repository__stats_batch_size_get
export def "repos-stats-batch-size get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Merge queue rule name(s) of the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/batch_size" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get batch bisection statistics
#
# GET /repos/{owner}/{repository}/stats/batch_bisection
# operationId: get_stats_batch_bisection_repos__owner___repository__stats_batch_bisection_get
export def "repos-stats-batch-bisection get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Merge queue rule name(s) of the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<started: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>, completed: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/batch_bisection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the base refs in the repository
#
# GET /repos/{owner}/{repository}/stats/branches
# operationId: get_stats_branches_repos__owner___repository__stats_branches_get
export def "repos-stats-branches get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<base_refs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/branches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the queue checks retries statistics
#
# GET /repos/{owner}/{repository}/stats/checks_retries
# operationId: get_queue_checks_retries_repos__owner___repository__stats_checks_retries_get
export def "repos-stats-checks-retries get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/checks_retries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the queue failure rate
#
# GET /repos/{owner}/{repository}/stats/failure_rate
# operationId: get_queue_failure_rate_repos__owner___repository__stats_failure_rate_get
export def "repos-stats-failure-rate get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/failure_rate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get PR exit reasons by interval
#
# GET /repos/{owner}/{repository}/stats/queues_pr_exit_reasons
# operationId: get_pr_exit_reasons_repos__owner___repository__stats_queues_pr_exit_reasons_get
export def "repos-stats-queues-pr-exit-reasons get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-ref: string # Base reference(s) of the pull requests
  --partition-name: string # Partition name(s) of the pull requests
  --queue-name: string # Name of the merge queue(s) for the pull requests
  --priority-rule-name: string # Name of the priority rule(s) of the pull requests
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<groups: table<base_ref: string, partition_name: string, queue_name: string, priority_rule_name: any, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_ref" $base_ref "scalar") (serialize-qp "partition_name" $partition_name "scalar") (serialize-qp "queue_name" $queue_name "scalar") (serialize-qp "priority_rule_name" $priority_rule_name "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/queues_pr_exit_reasons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the queue names in the repository
#
# GET /repos/{owner}/{repository}/stats/queues
# operationId: get_stats_queues_repos__owner___repository__stats_queues_get
export def "repos-stats-queues get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-at: string # Get the stats until this date, default 1 day before end_at
  --end-at: string # Get the stats from this date, default now
]: nothing -> record<queue_names: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/stats/queues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the scopes for a pull request
#
# PUT /repos/{owner}/{repository}/pulls/{number}/scopes
# operationId: put_ci_scopes_repos__owner___repository__pulls__number__scopes_put
export def "repos-pulls-scopes put" [
  number: int
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/pulls/($number)/scopes")
  let body = {scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set the scopes for a pull request (deprecated, use PUT)
#
# POST /repos/{owner}/{repository}/pulls/{number}/scopes
# DEPRECATED
# operationId: set_ci_scopes_repos__owner___repository__pulls__number__scopes_post
@deprecated
export def "repos-pulls-scopes post" [
  number: int
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/pulls/($number)/scopes")
  let body = {scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search tests
#
# GET /ci/{owner}/repositories/{repository_name}/search/tests
# operationId: ci-search-tests
export def "ci-repositories-search-tests ci-search-tests" [
  repository_name: string
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --test-name: string # Filter by test name. Pass multiple times to combine matches. Supports glob patterns (`*`, `?`). Omit to return all test identities.
  --qp-sort: string@sort-completer # Sort field (default: executions_count)
  --direction: string@direction-completer # Sort direction (default: desc)
  --test-name-exclude: string # The test name to exclude
  --pipeline-name: string # The pipeline name to filter on
  --pipeline-name-exclude: string # The pipeline name to exclude
  --job-name: string # The job name to filter on
  --job-name-exclude: string # The job name to exclude
  --health-status: string # The health status to filter on
  --health-status-exclude: string # The health status to exclude
  --health-confidence: string # The health confidence to filter on
  --health-confidence-exclude: string # The health confidence to exclude
  --failed-executions-impact: string # The failed executions impact to filter on
  --failed-executions-impact-exclude: string # The failed executions impact to exclude
  --cursor: string # The opaque cursor of the current page. Must be extracted from RFC 5988 pagination links to get first/previous/next/last pages
  --per-page: int # The number of items per page (default: 10)
]: nothing -> record<size: int, per_page: int, tests: table<test_id: string, test_name: string, pipeline_name: string, job_name: string, metrics: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "test_name" $test_name "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "test_name_exclude" $test_name_exclude "scalar") (serialize-qp "pipeline_name" $pipeline_name "scalar") (serialize-qp "pipeline_name_exclude" $pipeline_name_exclude "scalar") (serialize-qp "job_name" $job_name "scalar") (serialize-qp "job_name_exclude" $job_name_exclude "scalar") (serialize-qp "health_status" $health_status "scalar") (serialize-qp "health_status_exclude" $health_status_exclude "scalar") (serialize-qp "health_confidence" $health_confidence "scalar") (serialize-qp "health_confidence_exclude" $health_confidence_exclude "scalar") (serialize-qp "failed_executions_impact" $failed_executions_impact "scalar") (serialize-qp "failed_executions_impact_exclude" $failed_executions_impact_exclude "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository_name)/search/tests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get detailed information about a test
#
# GET /ci/{owner}/repositories/{repository_name}/tests/{test_id}
# operationId: get_test_details_ci__owner__repositories__repository_name__tests__test_id__get
export def "ci-repositories-tests get" [
  repository_name: string
  test_id: string
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<repository: string, test_name: string, test_id: string, health_status: string, last_conclusion: string, failure_ratio: float, flakiness_ratio: float, success_ratio: float, flaky_detection_enabled: bool, first_failure_at: any, first_failure_commit: any, first_failure_pull: any, last_failure_at: any, last_success_at: any, test_framework: any, test_framework_version: any, test_programming_language: any, test_filepath: any, test_function_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository_name)/tests/($test_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single test stat as a time series
#
# GET /ci/{owner}/repositories/{repository_name}/tests/{test_id}/stats/{stat}
# Discriminator (response): stat = success_count, failure_count, flaky_count, mean_duration
# operationId: ci-test-stats
export def "ci-repositories-tests-stats ci-test-stats" [
  repository_name: string
  test_id: string
  stat: string
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Start of the time range. Defaults to `end - 1 day` when omitted.
  --end: string # End of the time range. Defaults to `start + 1 day` when only start is provided, or `now` otherwise.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository_name)/tests/($test_id)/stats/($stat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get test failures
#
# GET /ci/{owner}/repositories/{repository_name}/tests/{test_id}/failures
# operationId: ci-test-failures
export def "ci-repositories-tests-failures ci-test-failures" [
  repository_name: string
  test_id: string
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<failures: table<id: string, exception_type: string, exception_message: string, failure_count: int, first_failure_at: string, last_failure_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository_name)/tests/($test_id)/failures")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get test failure
#
# GET /ci/{owner}/repositories/{repository_name}/tests/{test_id}/failures/{failure_id}
# operationId: ci-test-failure
export def "ci-repositories-tests-failures ci-test-failure" [
  repository_name: string
  test_id: string
  failure_id: string
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, exception_type: string, exception_message: string, failure_count: int, first_failure_at: string, last_failure_at: string, latest_events: table<id: string, failed_at: string, exception_stacktrace: any, test_filepath: any, test_programming_language: any, job_url: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository_name)/tests/($test_id)/failures/($failure_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a test's executions
#
# GET /ci/{owner}/repositories/{repository_name}/tests/{test_id}/executions
# operationId: ci-test-executions
export def "ci-repositories-tests-executions ci-test-executions" [
  repository_name: string
  test_id: string
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer-1 # Sort field (default: executions_count)
  --direction: string@direction-completer # Sort direction (default: desc)
  --cursor: string # The opaque cursor of the current page. Must be extracted from RFC 5988 pagination links to get first/previous/next/last pages
  --per-page: int # The number of items per page (default: 10)
  --start: string # Start of the time range. Defaults to `end - 1 day` when omitted.
  --end: string # End of the time range. Defaults to `start + 1 day` when only start is provided, or `now` otherwise.
]: nothing -> record<size: int, per_page: int, executions: table<test_id: string, test_name: string, pipeline_name: string, job_name: string, executions_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository_name)/tests/($test_id)/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List quarantined tests
#
# GET /ci/{owner}/repositories/{repository}/quarantines
# operationId: get_quarantined_tests_with_params_token_auth_ci__owner__repositories__repository__quarantines_get
export def "ci-repositories-quarantines list" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  --test-id: string
  --qp-source: string
  --cursor: string # The opaque cursor of the current page. Must be extracted from RFC 5988 pagination links to get first/previous/next/last pages.
  --per-page: string # The number of items per page. Omit to receive the full list in a single response; pass a value to opt into RFC 5988 cursor pagination.
]: nothing -> record<size: int, per_page: any, quarantined_tests: table<id: string, test_name: string, test_id: string, reason: string, branch: any, created_at: string, source: string, is_recovered: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "test_id" $test_id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository)/quarantines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark a test as quarantined
#
# POST /ci/{owner}/repositories/{repository}/quarantines
# operationId: add_ci_quarantine_ci__owner__repositories__repository__quarantines_post
export def "ci-repositories-quarantines post" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  test_name: string # The fully qualified name of the test that needs to be quarantined
  reason: string # Reason for the test being added to the quarantine
  --branch: any # Branch name or pattern on which the test should be quarantined. If not specified, it will be quarantined on all branches.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository)/quarantines")
  let body = {test_name: $test_name, reason: $reason, branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a quarantined test
#
# GET /ci/{owner}/repositories/{repository}/quarantines/{quarantine_id}
# operationId: get_quarantine_by_id_ci__owner__repositories__repository__quarantines__quarantine_id__get
export def "ci-repositories-quarantines get" [
  quarantine_id: string
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, test_name: string, test_id: string, reason: string, branch: any, created_at: string, source: string, is_recovered: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository)/quarantines/($quarantine_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a quarantine
#
# DELETE /ci/{owner}/repositories/{repository}/quarantines/{quarantine_id}
# operationId: remove_quarantine_by_id_ci__owner__repositories__repository__quarantines__quarantine_id__delete
export def "ci-repositories-quarantines delete" [
  quarantine_id: string
  owner: string
  repository: string
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
  let full_url = (build-url $base $"/ci/($owner)/repositories/($repository)/quarantines/($quarantine_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get scheduled freezes
#
# GET /repos/{owner}/{repository}/scheduled_freeze
# operationId: get_scheduled_freezes_repos__owner___repository__scheduled_freeze_get
export def "repos-scheduled-freeze get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scheduled_freezes: table<id: string, reason: string, start: string, end: any, timezone: string, matching_conditions: list, exclude_conditions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/scheduled_freeze")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a scheduled freeze
#
# POST /repos/{owner}/{repository}/scheduled_freeze
# operationId: create_scheduled_freeze_repos__owner___repository__scheduled_freeze_post
export def "repos-scheduled-freeze post" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  reason: string # The reason for the scheduled freeze.
  start: any # When the scheduled freeze begins (date and time in ISO 8601 format without TZ). Begins now if the attribute is null.
  --end: any # When the scheduled freeze ends (date and time in ISO 8601 format without TZ).
  timezone: string # Timezone where the freeze is expected to happen.
  --matching-conditions: list # List of conditions used to match pull requests that need to be frozen during the scheduled freeze. Defaults to an empty list, which matches all pull requests.
  --exclude-conditions: list # List of conditions used to exclude pull requests from the scheduled freeze. Pull requests matching these conditions will not be frozen.
]: any -> record<id: string, reason: string, start: string, end: any, timezone: string, matching_conditions: list<any>, exclude_conditions: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/scheduled_freeze")
  let body = {reason: $reason, start: $start, end: $end, timezone: $timezone, matching_conditions: $matching_conditions, exclude_conditions: $exclude_conditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a scheduled freeze
#
# PATCH /repos/{owner}/{repository}/scheduled_freeze/{freeze_id}
# operationId: update_scheduled_freeze_repos__owner___repository__scheduled_freeze__freeze_id__patch
export def "repos-scheduled-freeze patch" [
  freeze_id: string
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reason: any # The reason for the scheduled freeze.
  --start: any # When the scheduled freeze begins (date and time in ISO 8601 format without TZ). Can only be updated if the scheduled freeze has not yet begun. Set to null to start now.
  --end: any # When the scheduled freeze ends (date and time in ISO 8601 format without TZ). Set to null for an indefinite freeze.
  --timezone: any # Timezone where the freeze is expected to happen.
  --matching-conditions: any # List of conditions used to match pull requests that need to be frozen during the scheduled freeze.
  --exclude-conditions: any # List of conditions used to exclude pull requests from the scheduled freeze. Pull requests matching these conditions will not be frozen.
]: any -> record<id: string, reason: string, start: string, end: any, timezone: string, matching_conditions: list<any>, exclude_conditions: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/scheduled_freeze/($freeze_id)")
  let body = {reason: $reason, start: $start, end: $end, timezone: $timezone, matching_conditions: $matching_conditions, exclude_conditions: $exclude_conditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a scheduled freeze
#
# DELETE /repos/{owner}/{repository}/scheduled_freeze/{freeze_id}
# DEPRECATED
# operationId: delete_scheduled_freeze_repos__owner___repository__scheduled_freeze__freeze_id__delete
@deprecated
export def "repos-scheduled-freeze delete" [
  freeze_id: string
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-reason: string # The reason for the deletion
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/scheduled_freeze/($freeze_id)")
  let body = {delete_reason: $delete_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a scheduled freeze
#
# POST /repos/{owner}/{repository}/scheduled_freeze/{freeze_id}/delete
# operationId: delete_scheduled_freeze_repos__owner___repository__scheduled_freeze__freeze_id__delete_post
export def "repos-scheduled-freeze-delete post" [
  freeze_id: string
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-reason: string # The reason for the deletion
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/scheduled_freeze/($freeze_id)/delete")
  let body = {delete_reason: $delete_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get branches with active merge queues
#
# GET /repos/{owner}/{repository}/merge-queue/branches
# operationId: get_merge_queue_branches_repos__owner___repository__merge_queue_branches_get
export def "repos-merge-queue-branches get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<branches: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/merge-queue/branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current status of the merge queue
#
# GET /repos/{owner}/{repository}/merge-queue/status
# operationId: get_merge_queue_status_endpoint_repos__owner___repository__merge_queue_status_get
export def "repos-merge-queue-status get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # The name of the branch
]: nothing -> record<batches: table<id: string, name: string, parent_ids: list, status: record, started_at: any, estimated_merge_at: any, estimated_ci_finish_at: any, ci_finished_at: any, scopes: list, queue_rule_name: string, checks_summary: record, pull_requests: list, checks_timeout_at: any, sub_batches: any>, waiting_pull_requests: table<number: int, title: string, url: string, author: record, queued_at: string, priority_alias: string, priority_rule_name: string, labels: list, scopes: list, github_labels: any, estimated_merge_at: any, estimated_ci_finish_at: any, conflict_with_pull_requests: any>, scope_queues: record, pause: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repository)/merge-queue/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a pull request in the merge queue
#
# GET /repos/{owner}/{repository}/merge-queue/pull/{pr_number}
# operationId: get_merge_queue_pull_request_repos__owner___repository__merge_queue_pull__pr_number__get
export def "repos-merge-queue-pull get" [
  pr_number: int
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<number: int, queued_at: string, estimated_time_of_merge: any, position: int, priority_rule_name: string, queue_rule_name: string, checks_timeout_at: any, queue_rule: record<name: string, config: record>, mergeability_check: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/merge-queue/pull/($pr_number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause the merge queue
#
# PUT /repos/{owner}/{repository}/merge-queue/pause
# operationId: create_merge_queue_pause_repos__owner___repository__merge_queue_pause_put
export def "repos-merge-queue-pause put" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  reason: string # The reason of the merge queue pause
]: any -> record<paused: bool, reason: any, paused_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/merge-queue/pause")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unpause merge queue
#
# DELETE /repos/{owner}/{repository}/merge-queue/pause
# operationId: delete_merge_queue_pause_repos__owner___repository__merge_queue_pause_delete
export def "repos-merge-queue-pause delete" [
  owner: string
  repository: string
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
  let full_url = (build-url $base $"/repos/($owner)/($repository)/merge-queue/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get merge queue pause data
#
# GET /repos/{owner}/{repository}/merge-queue/pause
# operationId: get_merge_queue_pause_repos__owner___repository__merge_queue_pause_get
export def "repos-merge-queue-pause get" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<paused: bool, reason: any, paused_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repository)/merge-queue/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manage enabled products
#
# PUT /products/{owner}/{repository}
# operationId: manage_products_on_a_github_repository_products__owner___repository__put
export def "products put" [
  owner: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  products: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($owner)/($repository)")
  let body = {products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get default enabled products
#
# GET /default_products/{owner}
# operationId: get_default_enabled_products_default_products__owner__get
export def "default-products get" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<products: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default_products/($owner)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manage default enabled products
#
# PUT /default_products/{owner}
# operationId: manage_default_enabled_products_default_products__owner__put
export def "default-products put" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  products: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/default_products/($owner)")
  let body = {products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
