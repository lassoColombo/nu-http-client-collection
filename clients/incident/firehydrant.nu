# Auto-generated client for FireHydrant API v0.0.1
# Source: https://raw.githubusercontent.com/firehydrant/firehydrant-go-sdk/main/openapi.yaml
# Auth: --token flag or $env.FIREHYDRANT_API_TOKEN

const BASE_URL = "https://api.firehydrant.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FIREHYDRANT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.firehydrant.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["down" "up"] }
def tag-match-strategy-completer [] { ["any" "exclude" "match_all"] }
def encoding-completer [] { ["application/json" "application/x-yaml" "text/yaml"] }
def sort-completer [] { ["asc" "desc"] }
def type-completer [] { ["access" "quota"] }
def vote-direction-completer [] { ["down" "up"] }
def direction-completer-1 [] { ["dig" "down" "up"] }
def bulk-completer [] { ["true"] }
def visibility-completer [] { ["internal_status_page" "open_to_public" "private_to_org"] }
def type-completer-1 [] { ["caused" "dismissed" "fixed" "suspect"] }
def status-completer [] { ["active" "inactive"] }
def bucket-size-completer [] { ["all_time" "day" "month" "week"] }
def by-completer [] { ["environment" "functionality" "priority" "service" "severity" "total" "user" "user_involvement"] }
def sort-field-completer [] { ["count" "mtta" "mttd" "mttm" "mttr" "total_time"] }
def sort-direction-completer [] { ["asc" "desc"] }
def sort-by-completer [] { ["count_asc" "count_desc" "healthiness_asc" "healthiness_desc" "mtta_asc" "mtta_desc" "mttd_asc" "mttd_desc" "mttm_asc" "mttm_desc" "mttr_asc" "mttr_desc"] }
def sort-field-completer-1 [] { ["incident_count" "time_spent" "user_count"] }
def of-level-completer [] { ["debug" "error" "fatal" "info" "unknown" "warn"] }
def exact-level-completer [] { ["debug" "error" "fatal" "info" "unknown" "warn"] }
def auditable-type-completer [] { ["Runbooks::Runbook" "Runbooks::Step"] }
def type-completer-2 [] { ["general" "incident" "incident_role" "infrastructure"] }
def service-tier-completer [] { ["0" "1" "2" "3" "4" "5"] }
def integration-completer [] { ["opsgenie" "pager_duty" "victorops"] }
def color-completer [] { ["blue" "grey" "orange" "red" "teal" "yellow"] }
def group-by-completer [] { ["environments" "services" "signal_rules" "tags" "teams"] }
def sort-by-completer-1 [] { ["acked_percentage" "incidents_percentage" "total_acked_alerts" "total_incidents" "total_opened_alerts"] }
def bucket-completer [] { ["day" "month" "week"] }
def rule-matching-strategy-completer [] { ["all" "any"] }
def target-type-completer [] { ["EscalationPolicy" "OnCallSchedule" "User" "Webhook"] }
def notification-priority-override-completer [] { ["" "HIGH" "LOW" "MEDIUM"] }
def state-completer [] { ["cancelled" "done" "in_progress" "open"] }
def state-completer-1 [] { ["active" "inactive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ai-preferences get" } } | get name | first)
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

# Get AI preferences
#
# GET /v1/ai/preferences
# operationId: getAiPreferences
export def "ai-preferences get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ai: bool, description: bool, followups: bool, impact: bool, retros: bool, similar_incidents: bool, summaries: bool, updates: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ai/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update AI preferences
#
# PATCH /v1/ai/preferences
# operationId: updateAiPreferences
export def "ai-preferences updateAiPreferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ai: oneof<nothing, bool> # Whether to enable AI features
  --summaries: oneof<nothing, bool> # Whether to enable incident summaries
  --description: oneof<nothing, bool> # Whether to enable incident descriptions
  --impact: oneof<nothing, bool> # Whether to enable incident impact
  --updates: oneof<nothing, bool> # Whether to enable incident updates
  --retros: oneof<nothing, bool> # Whether to enable incident retrospectives
  --followups: oneof<nothing, bool> # Whether to enable incident followups
  --similar-incidents: oneof<nothing, bool> # Whether to enable similar incidents
]: any -> record<ai: bool, description: bool, followups: bool, impact: bool, retros: bool, similar_incidents: bool, summaries: bool, updates: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ai/preferences")
  let body = {ai: $ai, summaries: $summaries, description: $description, impact: $impact, updates: $updates, retros: $retros, followups: $followups, similar_incidents: $similar_incidents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Vote on an AI-generated incident summary
#
# PUT /v1/ai/summarize_incident/{incident_id}/{generated_summary_id}/vote
# operationId: voteOnIncidentSummary
export def "ai-summarize-incident-vote voteOnIncidentSummary" [
  incident_id: string
  generated_summary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  direction: string@direction-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ai/summarize_incident/($incident_id)/($generated_summary_id)/vote")
  let body = {direction: $direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the vote status for an AI-generated incident summary
#
# GET /v1/ai/summarize_incident/{incident_id}/{generated_summary_id}/voted
# operationId: getIncidentAiSummaryVoteStatus
export def "ai-summarize-incident-voted get" [
  incident_id: string
  generated_summary_id: string
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
  let full_url = (build-url $base $"/v1/ai/summarize_incident/($incident_id)/($generated_summary_id)/voted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List alerts
#
# GET /v1/alerts
# operationId: listAlerts
export def "alerts listAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --qp-query: string # A text query for alerts
  --users: string # A comma separated list of user IDs. This currently only works for Signals alerts.
  --teams: string # A comma separated list of team IDs. This currently only works for Signals alerts.
  --signal-rules: string # A comma separated list of signals rule IDs. This currently only works for Signals alerts.
  --environments: string # A comma separated list of environment IDs. This currently only works for Signals alerts.
  --functionalities: string # A comma separated list of functionality IDs. This currently only works for Signals alerts.
  --services: string # A comma separated list of service IDs. This currently only works for Signals alerts.
  --tags: string # A comma separated list of tags. This currently only works for Signals alerts.
  --tag-match-strategy: string@tag-match-strategy-completer # The strategy to match tags. `any` will return alerts that have at least one of the supplied tags, `match_all` will return only alerts that have all of the supplied tags, and `exclude` will only return alerts that have none of the supplied tags. This currently only works for Signals alerts.
  --statuses: string # A comma separated list of statuses to filter by. Valid statuses are: opened, acknowledged, resolved, ignored, or expired
]: nothing -> record<data: table<id: string, summary: string, description: string, priority: string, integration_name: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, status: string, remote_id: string, remote_url: string, labels: record, environments: list, services: list, tags: list, source_icon: string, signal_id: string, signal_rule: record, team_name: string, team_id: string, position: int, incidents: list, events: list, is_expired: bool>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "signal_rules" $signal_rules "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "functionalities" $functionalities "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "tag_match_strategy" $tag_match_strategy "scalar") (serialize-qp "statuses" $statuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an alert
#
# GET /v1/alerts/{alert_id}
# operationId: getAlert
export def "alerts get" [
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, summary: string, description: string, priority: string, integration_name: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, status: string, remote_id: string, remote_url: string, labels: record, environments: table<id: string, name: string>, services: table<id: string, name: string>, tags: list<string>, source_icon: string, signal_id: string, signal_rule: record<id: string, name: string, expression: string, team_id: string, target: record<id: string, name: string, type: string, is_pageable: bool>, created_by: record<id: string, name: string, source: string, email: string>, created_at: string, updated_at: string, incident_type: record<id: string, name: string>, notification_priority_override: string>, team_name: string, team_id: string, position: int, incidents: table<id: string, name: string, number: string>, events: table<id: string, type: string, data: record, created_at: string>, is_expired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alerts/($alert_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get initial application configuration and settings
#
# GET /v1/bootstrap
# operationId: getBootstrap
export def "bootstrap get" [
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
  let full_url = (build-url $base "/v1/bootstrap")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ingest service catalog data
#
# POST /v1/catalogs/{catalog_id}/ingest
# operationId: ingestCatalogData
export def "catalogs-ingest ingestCatalogData" [
  catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  encoding: string@encoding-completer # Encoding for submitted data
  data: string # Service data
]: any -> record<state: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/catalogs/($catalog_id)/ingest")
  let body = {encoding: $encoding, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh a service catalog
#
# GET /v1/catalogs/{catalog_id}/refresh
# operationId: refreshCatalog
export def "catalogs-refresh refreshCatalog" [
  catalog_id: string
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
  let full_url = (build-url $base $"/v1/catalogs/($catalog_id)/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List change types
#
# GET /v1/change_types
# operationId: listChangeTypes
export def "change-types listChangeTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, name: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/change_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List changes
#
# GET /v1/changes
# operationId: listChanges
export def "changes listChanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --qp-query: string # Filter changes by summary
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a change
#
# POST /v1/changes
# operationId: createChange
export def "changes createChange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summary: string
  --description: string
  --labels: record # A labels hash of keys and values
]: any -> record<id: string, summary: string, created_at: string, updated_at: string, labels: record, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/changes")
  let body = {summary: $summary, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List change events
#
# GET /v1/changes/events
# operationId: listChangeEvents
export def "changes-events listChangeEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --saved-search-id: string # The id of a previously saved search.
  --qp-query: string # A text query for change events
  --labels: string # A comma separated list of label key / values in the format of "key=value,key2=value2". To filter change events that have a key (with no specific value), omit the value
  --environments: string # A comma separated list of environment IDs
  --services: string # A comma separated list of service IDs
  --starts-at: string # The start time to start returning change events from
  --ends-at: string # The end time to return change events up to (format: date-time)
]: nothing -> record<data: table<id: string, summary: string, description: string, external_id: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, environments: list, authors: list, labels: record, services: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "saved_search_id" $saved_search_id "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "starts_at" $starts_at "scalar") (serialize-qp "ends_at" $ends_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/changes/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a change event
#
# POST /v1/changes/events
# operationId: createChangeEvent
# --change_identities item shape: {type: string, value: string}
# --attachments item shape: {type: "link"}
# --authors item shape: {source: string, source_id: string, name: string}
export def "changes-events createChangeEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  summary: string
  --description: string
  --labels: record
  --starts-at: string # format: date-time
  --ends-at: string # format: date-time
  --environments: list # An array of environment IDs
  --services: list # An array of service IDs
  --changes: list # An array of change IDs
  --external-id: string # The ID of a change event as assigned by an external provider
  --change-identities: list # If provided and valid, the event will be linked to all changes that have the same identities. Identity *values* must be unique. — item shape: {type: string, value: string}
  --attachments: list # JSON objects representing attachments, see attachments documentation for the schema — item shape: {type: "link"}
  --authors: list # Array of additional authors to add to the change event, the creating actor will automatically be added as an author — item shape: {source: string, source_id: string, name: string}
]: any -> record<id: string, summary: string, description: string, external_id: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, environments: table<id: string, name: string, slug: string, description: string, updated_at: string, created_at: string, active_incidents: string, external_resources: list>, related_changes: table<id: string, summary: string, created_at: string, updated_at: string, labels: record, description: string>, identities: table<id: string, type: string, value: string, change_id: string, created_at: string, updated_at: string>, authors: table<id: string, name: string, source: string, email: string>, attachments: list<record>, labels: record, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/changes/events")
  let body = {summary: $summary, description: $description, labels: $labels, starts_at: $starts_at, ends_at: $ends_at, environments: $environments, services: $services, changes: $changes, external_id: $external_id, change_identities: $change_identities, attachments: $attachments, authors: $authors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a change event
#
# GET /v1/changes/events/{change_event_id}
# operationId: getChangeEvent
export def "changes-events get" [
  change_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, summary: string, description: string, external_id: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, environments: table<id: string, name: string, slug: string, description: string, updated_at: string, created_at: string, active_incidents: string, external_resources: list>, related_changes: table<id: string, summary: string, created_at: string, updated_at: string, labels: record, description: string>, identities: table<id: string, type: string, value: string, change_id: string, created_at: string, updated_at: string>, authors: table<id: string, name: string, source: string, email: string>, attachments: list<record>, labels: record, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/changes/events/($change_event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a change event
#
# DELETE /v1/changes/events/{change_event_id}
# operationId: deleteChangeEvent
export def "changes-events delete" [
  change_event_id: string
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
  let full_url = (build-url $base $"/v1/changes/events/($change_event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a change event
#
# PATCH /v1/changes/events/{change_event_id}
# operationId: updateChangeEvent
# --attachments item shape: {type: "link"}
export def "changes-events updateChangeEvent" [
  change_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summary: string
  --description: string
  --labels: record
  --starts-at: string # format: date-time
  --ends-at: string # format: date-time
  --environments: list # An array of environment IDs (setting this will overwrite the current environments)
  --services: list # An array of service IDs (setting this will overwrite the current services)
  --attachments: list # JSON objects representing attachments, see attachments documentation for the schema — item shape: {type: "link"}
]: any -> record<id: string, summary: string, description: string, external_id: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, environments: table<id: string, name: string, slug: string, description: string, updated_at: string, created_at: string, active_incidents: string, external_resources: list>, related_changes: table<id: string, summary: string, created_at: string, updated_at: string, labels: record, description: string>, identities: table<id: string, type: string, value: string, change_id: string, created_at: string, updated_at: string>, authors: table<id: string, name: string, source: string, email: string>, attachments: list<record>, labels: record, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/changes/events/($change_event_id)")
  let body = {summary: $summary, description: $description, labels: $labels, starts_at: $starts_at, ends_at: $ends_at, environments: $environments, services: $services, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive a change
#
# DELETE /v1/changes/{change_id}
# operationId: deleteChange
export def "changes delete" [
  change_id: string
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
  let full_url = (build-url $base $"/v1/changes/($change_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a change
#
# PATCH /v1/changes/{change_id}
# operationId: updateChange
export def "changes updateChange" [
  change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summary: string
  --description: string
  --labels: record
]: any -> record<id: string, summary: string, created_at: string, updated_at: string, labels: record, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/changes/($change_id)")
  let body = {summary: $summary, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List identities for a change
#
# GET /v1/changes/{change_id}/identities
# operationId: listChangeIdentities
export def "changes-identities listChangeIdentities" [
  change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, type: string, value: string, change_id: string, created_at: string, updated_at: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/changes/($change_id)/identities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an identity for a change
#
# POST /v1/changes/{change_id}/identities
# operationId: createChangeIdentity
export def "changes-identities createChangeIdentity" [
  change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  value: string
]: any -> record<id: string, type: string, value: string, change_id: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/changes/($change_id)/identities")
  let body = {type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an identity from a change
#
# DELETE /v1/changes/{change_id}/identities/{identity_id}
# operationId: deleteChangeIdentity
export def "changes-identities delete" [
  identity_id: string
  change_id: string
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
  let full_url = (build-url $base $"/v1/changes/($change_id)/identities/($identity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an identity for a change
#
# PATCH /v1/changes/{change_id}/identities/{identity_id}
# operationId: updateChangeIdentity
export def "changes-identities updateChangeIdentity" [
  identity_id: string
  change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string
  value: string
]: any -> record<id: string, type: string, value: string, change_id: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/changes/($change_id)/identities/($identity_id)")
  let body = {type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List checklist templates
#
# GET /v1/checklist_templates
# operationId: listChecklistTemplates
export def "checklist-templates listChecklistTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --qp-query: string # A query to search checklist templates by their name
]: nothing -> record<data: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checklist_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a checklist template
#
# POST /v1/checklist_templates
# operationId: createChecklistTemplate
# --checks item shape: {name: string, description?: string}
# --connected_services item shape: {id: string}
export def "checklist-templates createChecklistTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  checks: list # An array of checks for the checklist template — item shape: {name: string, description?: string}
  --description: string
  --team-id: string # The ID of the Team that owns the checklist template
  --connected-services: list # Array of service IDs to attach checklist template to — item shape: {id: string}
]: any -> record<id: string, name: string, description: string, created_at: string, updated_at: string, checks: table<id: string, name: string, description: string, status: bool>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, connected_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool, completed_checks: int, owner: record, service_checklist_updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/checklist_templates")
  let body = {name: $name, checks: $checks, description: $description, team_id: $team_id, connected_services: $connected_services} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a checklist template
#
# GET /v1/checklist_templates/{id}
# operationId: getChecklistTemplate
export def "checklist-templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, created_at: string, updated_at: string, checks: table<id: string, name: string, description: string, status: bool>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, connected_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool, completed_checks: int, owner: record, service_checklist_updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/checklist_templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive a checklist template
#
# DELETE /v1/checklist_templates/{id}
# operationId: deleteChecklistTemplate
export def "checklist-templates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, created_at: string, updated_at: string, checks: table<id: string, name: string, description: string, status: bool>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, connected_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool, completed_checks: int, owner: record, service_checklist_updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/checklist_templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a checklist template
#
# PATCH /v1/checklist_templates/{id}
# operationId: updateChecklistTemplate
# --checks item shape: {id?: string, description?: string, name: string}
# --connected_services item shape: {id: string, remove?: bool}
export def "checklist-templates updateChecklistTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --checks: list # An array of checks for the checklist template — item shape: {id?: string, description?: string, name: string}
  --team-id: string # The ID of the Team that owns the checklist template
  --connected-services: list # Array of service IDs to attach checklist template to — item shape: {id: string, remove?: bool}
  --remove-remaining-connected-services: oneof<nothing, bool> # If set to true, any services tagged on the checklist that are not included in the given array will be removed. Set this to true if you want to do a replacement operation for the services
]: any -> record<id: string, name: string, description: string, created_at: string, updated_at: string, checks: table<id: string, name: string, description: string, status: bool>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, connected_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool, completed_checks: int, owner: record, service_checklist_updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/checklist_templates/($id)")
  let body = {name: $name, description: $description, checks: $checks, team_id: $team_id, connected_services: $connected_services, remove_remaining_connected_services: $remove_remaining_connected_services} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List comments for a conversation
#
# GET /v1/conversations/{conversation_id}/comments
# operationId: listConversationComments
export def "conversations-comments listConversationComments" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # An ISO8601 timestamp that allows filtering for comments posted before the provided time. (format: date-time)
  --after: string # An ISO8601 timestamp that allows filtering for comments posted after the provided time. (format: date-time)
  --qp-sort: string@sort-completer # Allows sorting comments by the time they were posted, ascending or descending. (default: asc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a comment for a conversation
#
# POST /v1/conversations/{conversation_id}/comments
# operationId: createConversationComment
export def "conversations-comments createConversationComment" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # Text body of comment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/comments")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a conversation comment
#
# GET /v1/conversations/{conversation_id}/comments/{comment_id}
# operationId: getConversationComment
export def "conversations-comments get" [
  comment_id: string
  conversation_id: string
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
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a conversation comment
#
# DELETE /v1/conversations/{conversation_id}/comments/{comment_id}
# operationId: deleteConversationComment
export def "conversations-comments delete" [
  comment_id: string
  conversation_id: string
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
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a conversation comment
#
# PATCH /v1/conversations/{conversation_id}/comments/{comment_id}
# operationId: updateConversationComment
export def "conversations-comments updateConversationComment" [
  comment_id: string
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # Text body of comment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/comments/($comment_id)")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List reactions for a conversation comment
#
# GET /v1/conversations/{conversation_id}/comments/{comment_id}/reactions
# operationId: listConversationCommentReactions
export def "conversations-comments-reactions listConversationCommentReactions" [
  conversation_id: string
  comment_id: string
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
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/comments/($comment_id)/reactions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a reaction for a conversation comment
#
# POST /v1/conversations/{conversation_id}/comments/{comment_id}/reactions
# operationId: createConversationCommentReaction
export def "conversations-comments-reactions createConversationCommentReaction" [
  conversation_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reaction: string # CLDR short name of Unicode emojis
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/comments/($comment_id)/reactions")
  let body = {reaction: $reaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a reaction from a conversation comment
#
# DELETE /v1/conversations/{conversation_id}/comments/{comment_id}/reactions/{reaction_id}
# operationId: deleteConversationCommentReaction
export def "conversations-comments-reactions delete" [
  reaction_id: string
  conversation_id: string
  comment_id: string
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
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/comments/($comment_id)/reactions/($reaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the currently authenticated user
#
# GET /v1/current_user
# operationId: getCurrentUser
export def "current-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, source: string, email: string, role: string, teams: table<id: string, name: string>, organization_id: string, organization_name: string, account_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/current_user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List custom field definitions
#
# GET /v1/custom_fields/definitions
# operationId: listCustomFieldDefinitions
export def "custom-fields-definitions listCustomFieldDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<display_name: string, field_id: string, field_type: string, slug: string, description: string, required: bool, required_at_milestone_id: string, permissible_values: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/custom_fields/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a custom field definition
#
# POST /v1/custom_fields/definitions
# operationId: createCustomFieldDefinition
export def "custom-fields-definitions createCustomFieldDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  display_name: string
  --description: string
  field_type: string
  --permissible-values: list
  --required: oneof<nothing, bool>
  --required-at-milestone-id: string # An optional milestone ID to specify when the field should become required, if `required` is set to `true`. If not provided, required fields are always required.
]: any -> record<display_name: string, field_id: string, field_type: string, slug: string, description: string, required: bool, required_at_milestone_id: string, permissible_values: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/custom_fields/definitions")
  let body = {display_name: $display_name, description: $description, field_type: $field_type, permissible_values: $permissible_values, required: $required, required_at_milestone_id: $required_at_milestone_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a custom field definition
#
# DELETE /v1/custom_fields/definitions/{field_id}
# operationId: deleteCustomFieldDefinition
export def "custom-fields-definitions delete" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<display_name: string, field_id: string, field_type: string, slug: string, description: string, required: bool, required_at_milestone_id: string, permissible_values: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom_fields/definitions/($field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a custom field definition
#
# PATCH /v1/custom_fields/definitions/{field_id}
# operationId: updateCustomFieldDefinition
export def "custom-fields-definitions updateCustomFieldDefinition" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --display-name: string
  --permissible-values: list
  --required: oneof<nothing, bool>
  --required-at-milestone-id: string # An optional milestone ID to specify when the field should become required, if `required` is set to `true`. If not provided, required fields are always required.
]: any -> record<display_name: string, field_id: string, field_type: string, slug: string, description: string, required: bool, required_at_milestone_id: string, permissible_values: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/custom_fields/definitions/($field_id)")
  let body = {description: $description, display_name: $display_name, permissible_values: $permissible_values, required: $required, required_at_milestone_id: $required_at_milestone_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List select options for a custom field
#
# GET /v1/custom_fields/definitions/{field_id}/select_options
# operationId: getCustomFieldSelectOptions
export def "custom-fields-definitions-select-options get" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Text string of a query for filtering values.
  --all-versions: oneof<nothing, bool> # If true, return all versions of the custom field definition.
]: nothing -> record<display_name: string, field_id: string, field_type: string, slug: string, description: string, required: bool, required_at_milestone_id: string, permissible_values: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "all_versions" $all_versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/custom_fields/definitions/($field_id)/select_options" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List entitlements
#
# GET /v1/entitlements
# operationId: listEntitlements
export def "entitlements listEntitlements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of Entitlement
  --type: string@type-completer # Type of Entitlement
]: nothing -> record<data: table<current_count: int, errors: list, exists: bool, available: bool, maximum: int, name: string, slug: string, tier: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/entitlements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List environments
#
# GET /v1/environments
# operationId: listEnvironments
export def "environments listEnvironments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --qp-query: string # A query to search environments by their name or description
  --name: string # A query to search environments by their name
]: nothing -> record<data: table<id: string, name: string, slug: string, description: string, updated_at: string, created_at: string, active_incidents: string, external_resources: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an environment
#
# POST /v1/environments
# operationId: createEnvironment
export def "environments createEnvironment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
]: any -> record<id: string, name: string, slug: string, description: string, updated_at: string, created_at: string, active_incidents: string, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environments")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an environment
#
# GET /v1/environments/{environment_id}
# operationId: getEnvironment
export def "environments get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, slug: string, description: string, updated_at: string, created_at: string, active_incidents: string, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive an environment
#
# DELETE /v1/environments/{environment_id}
# operationId: deleteEnvironment
export def "environments delete" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, slug: string, description: string, updated_at: string, created_at: string, active_incidents: string, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an environment
#
# PATCH /v1/environments/{environment_id}
# operationId: updateEnvironment
export def "environments updateEnvironment" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
]: any -> record<id: string, name: string, slug: string, description: string, updated_at: string, created_at: string, active_incidents: string, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a form configuration
#
# GET /v1/form_configurations/{slug}
# operationId: getFormConfiguration
export def "form-configurations get" [
  slug: string
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
  let full_url = (build-url $base $"/v1/form_configurations/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List functionalities
#
# GET /v1/functionalities
# operationId: listFunctionalities
export def "functionalities listFunctionalities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query to search functionalities by their name or description
  --name: string # A query to search functionalities by their name
  --impacted: string # A query to search services by if they are impacted with active incidents
  --labels: string # A comma separated list of label key / values in the format of 'key=value,key2=value2'. To filter change events that have a key (with no specific value), omit the value
  --owner: string # A query to search functionalities by their owning team ID
  --lite: oneof<nothing, bool> # Boolean to determine whether to return a slimified version of the functionalities object
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record, services: list, external_resources: list, teams: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "impacted" $impacted "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "lite" $lite "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/functionalities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a functionality
#
# POST /v1/functionalities
# operationId: createFunctionality
# --services item shape: {id: string}
# --external_resources item shape: {remote_id: string, connection_type?: string}
# --links item shape: {name: string, href_url: string, icon_url?: string}
# --owner shape: {id: string}
# --teams item shape: {id: string}
export def "functionalities createFunctionality" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --services: list # item shape: {id: string}
  --labels: record # A hash of label keys and values
  --alert-on-add: oneof<nothing, bool>
  --auto-add-responding-team: oneof<nothing, bool>
  --external-resources: list # An array of external resources to attach to this service. — item shape: {remote_id: string, connection_type?: string}
  --links: list # An array of links to associate with this service — item shape: {name: string, href_url: string, icon_url?: string}
  --owner: record # An object representing a Team that owns the service — shape: {id: string}
  --teams: list # An array of teams to attach to this service. — item shape: {id: string}
]: any -> record<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list<string>, links: table<id: string, href_url: string, icon_url: string, name: string>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record<id: string, name: string, source: string, email: string>, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>, teams: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/functionalities")
  let body = {name: $name, description: $description, services: $services, labels: $labels, alert_on_add: $alert_on_add, auto_add_responding_team: $auto_add_responding_team, external_resources: $external_resources, links: $links, owner: $owner, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a functionality
#
# GET /v1/functionalities/{functionality_id}
# operationId: getFunctionality
export def "functionalities get" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list<string>, links: table<id: string, href_url: string, icon_url: string, name: string>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record<id: string, name: string, source: string, email: string>, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>, teams: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functionalities/($functionality_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive a functionality
#
# DELETE /v1/functionalities/{functionality_id}
# operationId: deleteFunctionality
export def "functionalities delete" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list<string>, links: table<id: string, href_url: string, icon_url: string, name: string>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record<id: string, name: string, source: string, email: string>, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>, teams: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functionalities/($functionality_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a functionality
#
# PATCH /v1/functionalities/{functionality_id}
# operationId: updateFunctionality
# --services item shape: {id: string, remove?: bool}
# --links item shape: {href_url: string, name: string, icon_url?: string, remove?: bool, id?: string}
# --owner shape: {id: string}
# --teams item shape: {id: string, remove?: bool}
# --external_resources item shape: {remote_id: string, connection_type?: string, remove?: bool}
export def "functionalities updateFunctionality" [
  functionality_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --services: list # item shape: {id: string, remove?: bool}
  --links: list # An array of links to associate with this functionality. This will remove all links not present in the patch. Only acts if 'links' key is included in the payload. — item shape: {href_url: string, name: string, icon_url?: string, remove?: bool, id?: string}
  --owner: record # An object representing a Team that owns the functionality — shape: {id: string}
  --remove-owner: oneof<nothing, bool> # If you are trying to remove a team as an owner from a functionality, set this to 'true'
  --teams: list # An array of teams to attach to this functionality. — item shape: {id: string, remove?: bool}
  --remove-remaining-teams: oneof<nothing, bool> # If set to true, any teams tagged on the service that are not included in the given array will be removed. Set this to true if you want to do a replacement operation for the teams
  --external-resources: list # An array of external resources to attach to this service. — item shape: {remote_id: string, connection_type?: string, remove?: bool}
  --remove-remaining-external-resources: oneof<nothing, bool> # If set to true, any external_resources tagged on the service that are not included in the given array will be removed. Set this to true if you want to do a replacement operation for the external_resources
  --labels: record # A hash of label keys and values
  --alert-on-add: oneof<nothing, bool>
  --auto-add-responding-team: oneof<nothing, bool>
  --remove-remaining-services: oneof<nothing, bool> # Set this to true if you want to remove all of the services that are not included in the services array from the functionality (default: false)
]: any -> record<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list<string>, links: table<id: string, href_url: string, icon_url: string, name: string>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record<id: string, name: string, source: string, email: string>, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>, teams: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functionalities/($functionality_id)")
  let body = {name: $name, description: $description, services: $services, links: $links, owner: $owner, remove_owner: $remove_owner, teams: $teams, remove_remaining_teams: $remove_remaining_teams, external_resources: $external_resources, remove_remaining_external_resources: $remove_remaining_external_resources, labels: $labels, alert_on_add: $alert_on_add, auto_add_responding_team: $auto_add_responding_team, remove_remaining_services: $remove_remaining_services} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List services for a functionality
#
# GET /v1/functionalities/{functionality_id}/services
# operationId: getFunctionalityServices
export def "functionalities-services get" [
  functionality_id: string
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
  let full_url = (build-url $base $"/v1/functionalities/($functionality_id)/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List incident roles
#
# GET /v1/incident_roles
# operationId: listIncidentRoles
export def "incident-roles listIncidentRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, discarded_at: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/incident_roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an incident role
#
# POST /v1/incident_roles
# operationId: createIncidentRole
export def "incident-roles createIncidentRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  summary: string
  --description: string
]: any -> record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, discarded_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_roles")
  let body = {name: $name, summary: $summary, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an incident role
#
# GET /v1/incident_roles/{incident_role_id}
# operationId: getIncidentRole
export def "incident-roles get" [
  incident_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, discarded_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_roles/($incident_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive an incident role
#
# DELETE /v1/incident_roles/{incident_role_id}
# operationId: deleteIncidentRole
export def "incident-roles delete" [
  incident_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, discarded_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_roles/($incident_role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an incident role
#
# PATCH /v1/incident_roles/{incident_role_id}
# operationId: updateIncidentRole
export def "incident-roles updateIncidentRole" [
  incident_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --summary: string
  --description: string
]: any -> record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, discarded_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_roles/($incident_role_id)")
  let body = {name: $name, summary: $summary, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List incident tags
#
# GET /v1/incident_tags
# operationId: listIncidentTags
export def "incident-tags listIncidentTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string
]: nothing -> record<data: table<name: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefix" $prefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/incident_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate incident tags
#
# POST /v1/incident_tags/validate
# operationId: validateIncidentTags
export def "incident-tags-validate validateIncidentTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_tags/validate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List incident types
#
# GET /v1/incident_types
# operationId: listIncidentTypes
export def "incident-types listIncidentTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query to search incident types by their name
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, name: string, template: record, template_values: record, created_at: string, updated_at: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/incident_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an incident type
#
# POST /v1/incident_types
# operationId: createIncidentType
# --template shape: {description?: string, customer_impact_summary?: string, labels?: record, severity?: string, priority?: string, tag_list?: list, runbook_ids?: list, private_incident?: bool, team_ids?: list, impacts?: list}
export def "incident-types createIncidentType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  template: record # shape: {description?: string, customer_impact_summary?: string, labels?: record, severity?: string, priority?: string, tag_list?: list, runbook_ids?: list, private_incident?: bool, team_ids?: list, impacts?: list}
]: any -> record<id: string, name: string, template: record<incident_name: string, summary: string, description: string, customer_impact_summary: string, labels: record, severity: string, priority: string, tag_list: list<string>, runbook_ids: list<string>, team_ids: list<string>, private_incident: bool, custom_fields: string, impacts: list<record>>, template_values: record<services: list<record>, functionalities: list<record>, environments: list<record>, runbooks: record, teams: list<record>>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incident_types")
  let body = {name: $name, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an incident type
#
# GET /v1/incident_types/{id}
# operationId: getIncidentType
export def "incident-types get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, template: record<incident_name: string, summary: string, description: string, customer_impact_summary: string, labels: record, severity: string, priority: string, tag_list: list<string>, runbook_ids: list<string>, team_ids: list<string>, private_incident: bool, custom_fields: string, impacts: list<record>>, template_values: record<services: list<record>, functionalities: list<record>, environments: list<record>, runbooks: record, teams: list<record>>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive an incident type
#
# DELETE /v1/incident_types/{id}
# operationId: archiveIncidentType
export def "incident-types archiveIncidentType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, template: record<incident_name: string, summary: string, description: string, customer_impact_summary: string, labels: record, severity: string, priority: string, tag_list: list<string>, runbook_ids: list<string>, team_ids: list<string>, private_incident: bool, custom_fields: string, impacts: list<record>>, template_values: record<services: list<record>, functionalities: list<record>, environments: list<record>, runbooks: record, teams: list<record>>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_types/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an incident type
#
# PATCH /v1/incident_types/{id}
# operationId: updateIncidentType
# --template shape: {description?: string, customer_impact_summary?: string, labels?: record, severity?: string, priority?: string, tag_list?: list, runbook_ids?: list, private_incident?: bool, team_ids?: list, impacts?: list}
export def "incident-types updateIncidentType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  template: record # shape: {description?: string, customer_impact_summary?: string, labels?: record, severity?: string, priority?: string, tag_list?: list, runbook_ids?: list, private_incident?: bool, team_ids?: list, impacts?: list}
]: any -> record<id: string, name: string, template: record<incident_name: string, summary: string, description: string, customer_impact_summary: string, labels: record, severity: string, priority: string, tag_list: list<string>, runbook_ids: list<string>, team_ids: list<string>, private_incident: bool, custom_fields: string, impacts: list<record>>, template_values: record<services: list<record>, functionalities: list<record>, environments: list<record>, runbooks: record, teams: list<record>>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incident_types/($id)")
  let body = {name: $name, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List incidents
#
# GET /v1/incidents
# operationId: listIncidents
export def "incidents listIncidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --conditions: string # A JSON string that defines 'logic' and 'user_data'
  --environments: string # A comma separated list of environment IDs or 'is_empty' to filter for incidents with no impacted environments
  --services: string # A comma separated list of service IDs or 'is_empty' to filter for incidents with no impacted services
  --functionalities: string # A comma separated list of functionality IDs or 'is_empty' to filter for incidents with no impacted functionalities
  --excluded-infrastructure-ids: string # A comma separated list of infrastructure IDs. Returns incidents that do not have the following infrastructure ids associated with them.
  --teams: string # A comma separated list of team IDs
  --assigned-teams: string # A comma separated list of IDs for assigned teams or 'is_empty' to filter for incidents with no active team assignments
  --status: string # Incident status
  --start-date: string # Filters for incidents that started on or after this date (format: date)
  --end-date: string # Filters for incidents that started on or before this date (format: date)
  --resolved-at-or-after: string # Filters for incidents that were resolved at or after this time. Combine this with the `current_milestones` parameter if you wish to omit incidents that were re-opened and are still active. (format: date-time)
  --resolved-at-or-before: string # Filters for incidents that were resolved at or before this time. Combine this with the `current_milestones` parameter if you wish to omit incidents that were re-opened and are still active. (format: date-time)
  --created-at-or-after: string # Filters for incidents that were created at or after this time (format: date-time)
  --created-at-or-before: string # Filters for incidents that were created at or before this time (format: date-time)
  --qp-query: string # A text query for an incident that searches on name, summary, and desciption
  --name: string # A query to search incidents by their name
  --saved-search-id: string # The id of a previously saved search.
  --priorities: string # A text value of priority
  --priority-not-set: oneof<nothing, bool> # Flag for including incidents where priority has not been set
  --severities: string # A text value of severity
  --severity-not-set: oneof<nothing, bool> # Flag for including incidents where severity has not been set
  --current-milestones: string # A comma separated list of current milestones
  --tags: string # A comma separated list of tags
  --tag-match-strategy: string@tag-match-strategy-completer # A matching strategy for the tags provided
  --archived: oneof<nothing, bool> # Return archived incidents
  --updated-after: string # Filters for incidents that were updated after this date (format: date-time)
  --updated-before: string # Filters for incidents that were updated before this date (format: date-time)
  --incident-type-id: string # A comma separated list of incident type IDs
]: nothing -> record<data: table<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list, severity_impact_object: record, severity_condition_object: record, private_id: string, organization_id: string, milestones: list, lifecycle_phases: list, lifecycle_measurements: list, active: bool, labels: record, role_assignments: list, status_pages: list, incident_url: string, private_status_page_url: string, organization: record, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record, report_id: string, ai_incident_summary: string, services: list, environments: list, functionalities: list, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list, ticket: record, impacts: list, conference_bridges: list, incident_channels: list, retro_exports: list, created_by: record, context_object: record, team_assignments: list, conversations: list, custom_fields: list, field_requirements: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "conditions" $conditions "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "functionalities" $functionalities "scalar") (serialize-qp "excluded_infrastructure_ids" $excluded_infrastructure_ids "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "assigned_teams" $assigned_teams "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "resolved_at_or_after" $resolved_at_or_after "scalar") (serialize-qp "resolved_at_or_before" $resolved_at_or_before "scalar") (serialize-qp "created_at_or_after" $created_at_or_after "scalar") (serialize-qp "created_at_or_before" $created_at_or_before "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "saved_search_id" $saved_search_id "scalar") (serialize-qp "priorities" $priorities "scalar") (serialize-qp "priority_not_set" $priority_not_set "scalar") (serialize-qp "severities" $severities "scalar") (serialize-qp "severity_not_set" $severity_not_set "scalar") (serialize-qp "current_milestones" $current_milestones "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "tag_match_strategy" $tag_match_strategy "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "incident_type_id" $incident_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an incident
#
# POST /v1/incidents
# operationId: createIncident
# --impacts item shape: {type: string, id: string, condition_id: string}
# --milestones item shape: {type: string, occurred_at: string}
# --custom_fields item shape: {field_id: string, value_string?: string, value_array?: list}
export def "incidents createIncident" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --summary: string
  --customer-impact-summary: string
  --description: string
  --priority: string
  --severity: string
  --severity-condition-id: string
  --severity-impact-id: string
  --alert-ids: list # List of alert IDs that this incident should be associated to
  --labels: record # Key:value pairs to track custom data for the incident
  --runbook-ids: list # List of ids of Runbooks to attach to this incident. Foregoes any conditions these Runbooks may have guarding automatic attachment.
  --tag-list: list # List of tags for the incident
  --impacts: list # An array of impacted infrastructure — item shape: {type: string, id: string, condition_id: string}
  --milestones: list # An array of milestones to set on an incident. This can be used to create an already-resolved incident. — item shape: {type: string, occurred_at: string}
  --restricted: oneof<nothing, bool>
  --team-ids: list # IDs of teams you wish to assign to this incident.
  --custom-fields: list # An array of custom fields to set on the incident. — item shape: {field_id: string, value_string?: string, value_array?: list}
  --external-links: string
  --skip-incident-type-values: oneof<nothing, bool> # If true, the incident type values will not be copied to the incident. This is useful when creating an incident from an incident type, but you want to set the values manually. (default: false)
]: any -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incidents")
  let body = {name: $name, summary: $summary, customer_impact_summary: $customer_impact_summary, description: $description, priority: $priority, severity: $severity, severity_condition_id: $severity_condition_id, severity_impact_id: $severity_impact_id, alert_ids: $alert_ids, labels: $labels, runbook_ids: $runbook_ids, tag_list: $tag_list, impacts: $impacts, milestones: $milestones, restricted: $restricted, team_ids: $team_ids, custom_fields: $custom_fields, external_links: $external_links, skip_incident_type_values: $skip_incident_type_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an incident
#
# GET /v1/incidents/{incident_id}
# operationId: getIncident
export def "incidents get" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive an incident
#
# DELETE /v1/incidents/{incident_id}
# operationId: archiveIncident
export def "incidents archiveIncident" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an incident
#
# PATCH /v1/incidents/{incident_id}
# operationId: updateIncident
export def "incidents updateIncident" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --summary: string
  --customer-impact-summary: string
  --description: string
  --labels: record # Key:value pairs to track custom data for the incident
  --priority: string
  --severity: string
  --severity-condition-id: string
  --severity-impact-id: string
  --tag-list: list # List of tags for the incident
]: any -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)")
  let body = {name: $name, summary: $summary, customer_impact_summary: $customer_impact_summary, description: $description, labels: $labels, priority: $priority, severity: $severity, severity_condition_id: $severity_condition_id, severity_impact_id: $severity_impact_id, tag_list: $tag_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List alerts for an incident
#
# GET /v1/incidents/{incident_id}/alerts
# operationId: listIncidentAlerts
export def "incidents-alerts listIncidentAlerts" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, alert: record, primary: bool>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/alerts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach alerts to an incident
#
# POST /v1/incidents/{incident_id}/alerts
# operationId: createIncidentAlerts
export def "incidents-alerts createIncidentAlerts" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/alerts")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an alert from an incident
#
# DELETE /v1/incidents/{incident_id}/alerts/{incident_alert_id}
# operationId: deleteIncidentAlert
export def "incidents-alerts delete" [
  incident_alert_id: string
  incident_id: string
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
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/alerts/($incident_alert_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set an alert as primary for an incident
#
# PATCH /v1/incidents/{incident_id}/alerts/{incident_alert_id}/primary
# operationId: setIncidentAlertAsPrimary
export def "incidents-alerts-primary setIncidentAlertAsPrimary" [
  incident_alert_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --primary: oneof<nothing, bool>
]: any -> record<id: string, alert: record<id: string, summary: string, description: string, priority: string, integration_name: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, status: string, remote_id: string, remote_url: string, labels: record, environments: list<record>, services: list<record>, tags: list<string>, source_icon: string, signal_id: string, signal_rule: record<id: string, name: string, expression: string, team_id: string, target: record, created_by: record, created_at: string, updated_at: string, incident_type: record, notification_priority_override: string>, team_name: string, team_id: string, position: int, incidents: list<record>, events: list<record>, is_expired: bool>, primary: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/alerts/($incident_alert_id)/primary")
  let body = {primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List attachments for an incident
#
# GET /v1/incidents/{incident_id}/attachments
# operationId: listIncidentAttachments
export def "incidents-attachments listIncidentAttachments" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachable-type: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachable_type" $attachable_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/attachments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an attachment for an incident
#
# POST /v1/incidents/{incident_id}/attachments
# operationId: createIncidentAttachment
export def "incidents-attachments createIncidentAttachment" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
  --description: string
  --occurred-at: string # format: date-time
  --vote-direction: string@vote-direction-completer
]: any -> record<file_name: string, file_content_type: string, signed_url: string, media_type: string, description: string, external_id: string, file_size: int, status: string, versions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/attachments")
  let body = {file: $file, description: $description, occurred_at: $occurred_at, vote_direction: $vote_direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get chat channel information for an incident
#
# GET /v1/incidents/{incident_id}/channel
# operationId: getIncidentChannel
export def "incidents-channel get" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/channel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Close an incident
#
# PUT /v1/incidents/{incident_id}/close
# operationId: closeIncident
export def "incidents-close closeIncident" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/close")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List events for an incident
#
# GET /v1/incidents/{incident_id}/events
# operationId: listIncidentEvents
export def "incidents-events listIncidentEvents" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --types: string # A comma separated list of types of events to filter by
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, incident_id: string, type: string, context: string, data: record, occurred_at: string, visibility: string, author: record, votes: record, conversations: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "types" $types "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an incident event
#
# GET /v1/incidents/{incident_id}/events/{event_id}
# operationId: getIncidentEvent
export def "incidents-events get" [
  incident_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, incident_id: string, type: string, context: string, data: record, occurred_at: string, visibility: string, author: record<id: string, name: string, source: string, email: string>, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an incident event
#
# DELETE /v1/incidents/{incident_id}/events/{event_id}
# operationId: deleteIncidentEvent
export def "incidents-events delete" [
  incident_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, incident_id: string, type: string, context: string, data: record, occurred_at: string, visibility: string, author: record<id: string, name: string, source: string, email: string>, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an incident event
#
# PATCH /v1/incidents/{incident_id}/events/{event_id}
# operationId: updateIncidentEvent
export def "incidents-events updateIncidentEvent" [
  incident_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, incident_id: string, type: string, context: string, data: record, occurred_at: string, visibility: string, author: record<id: string, name: string, source: string, email: string>, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update votes for an incident event
#
# PATCH /v1/incidents/{incident_id}/events/{event_id}/votes
# operationId: updateIncidentEventVotes
export def "incidents-events-votes updateIncidentEventVotes" [
  incident_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  direction: string@direction-completer-1 # The direction you would like to vote, or if you dig it
]: any -> record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/events/($event_id)/votes")
  let body = {direction: $direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get vote counts for an incident event
#
# GET /v1/incidents/{incident_id}/events/{event_id}/votes/status
# operationId: getIncidentEventVoteStatus
export def "incidents-events-votes-status get" [
  incident_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/events/($event_id)/votes/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a chat message for an incident
#
# POST /v1/incidents/{incident_id}/generic_chat_messages
# operationId: createIncidentGenericChatMessage
export def "incidents-generic-chat-messages createIncidentGenericChatMessage" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string
  --occurred-at: string # ISO8601 timestamp for when the chat message occurred (format: date-time)
  --vote-direction: string@vote-direction-completer
]: any -> record<id: string, body: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/generic_chat_messages")
  let body = {body: $body_body, occurred_at: $occurred_at, vote_direction: $vote_direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a chat message from an incident
#
# DELETE /v1/incidents/{incident_id}/generic_chat_messages/{message_id}
# operationId: deleteIncidentChatMessage
export def "incidents-generic-chat-messages delete" [
  message_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, body: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/generic_chat_messages/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a chat message in an incident
#
# PATCH /v1/incidents/{incident_id}/generic_chat_messages/{message_id}
# operationId: updateIncidentChatMessage
export def "incidents-generic-chat-messages updateIncidentChatMessage" [
  message_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string
]: any -> record<id: string, body: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/generic_chat_messages/($message_id)")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace all impacts for an incident
#
# PUT /v1/incidents/{incident_id}/impact
# operationId: updateIncidentImpacts
# --impact item shape: {id: string, condition_id: string}
# --status_pages item shape: {id: string, integration_slug: string}
export def "incidents-impact updateIncidentImpacts" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --note: string
  --milestone: string
  --impact: list # item shape: {id: string, condition_id: string}
  --status-pages: list # item shape: {id: string, integration_slug: string}
]: any -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/impact")
  let body = {note: $note, milestone: $milestone, impact: $impact, status_pages: $status_pages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update impacts for an incident
#
# PATCH /v1/incidents/{incident_id}/impact
# operationId: partialUpdateIncidentImpacts
# --impact item shape: {id: string, condition_id: string}
# --status_pages item shape: {id: string, integration_slug: string}
export def "incidents-impact partialUpdateIncidentImpacts" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --note: string
  --milestone: string
  --impact: list # item shape: {id: string, condition_id: string}
  --status-pages: list # item shape: {id: string, integration_slug: string}
]: any -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/impact")
  let body = {note: $note, milestone: $milestone, impact: $impact, status_pages: $status_pages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List impacted infrastructure for an incident
#
# GET /v1/incidents/{incident_id}/impact/{type}
# operationId: listIncidentImpact
export def "incidents-impact listIncidentImpact" [
  incident_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, type: string, infrastructure: record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/impact/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add impacted infrastructure to an incident
#
# POST /v1/incidents/{incident_id}/impact/{type}
# operationId: createIncidentImpact
export def "incidents-impact createIncidentImpact" [
  incident_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
  --condition-id: string
]: any -> record<id: string, type: string, infrastructure: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/impact/($type)")
  let body = {id: $id, condition_id: $condition_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove impacted infrastructure from an incident
#
# DELETE /v1/incidents/{incident_id}/impact/{type}/{id}
# operationId: deleteIncidentImpact
export def "incidents-impact delete" [
  incident_id: string
  type: string
  id: string
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
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/impact/($type)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List links for an incident
#
# GET /v1/incidents/{incident_id}/links
# operationId: listIncidentLinks
export def "incidents-links listIncidentLinks" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a link for an incident
#
# POST /v1/incidents/{incident_id}/links
# operationId: createIncidentLink
export def "incidents-links createIncidentLink" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-text: string
  --icon-url: string
  href: string
]: any -> record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/links")
  let body = {display_text: $display_text, icon_url: $icon_url, href: $href} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an external link for an incident
#
# PUT /v1/incidents/{incident_id}/links/{link_id}
# operationId: updateIncidentLink
export def "incidents-links updateIncidentLink" [
  link_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-text: string
  --icon-url: string
  --href-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/links/($link_id)")
  let body = {display_text: $display_text, icon_url: $icon_url, href_url: $href_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an external link from an incident
#
# DELETE /v1/incidents/{incident_id}/links/{link_id}
# operationId: deleteIncidentLink
export def "incidents-links delete" [
  link_id: string
  incident_id: string
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
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/links/($link_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List milestones for an incident
#
# GET /v1/incidents/{incident_id}/milestones
# operationId: listIncidentMilestones
export def "incidents-milestones listIncidentMilestones" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/milestones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk update milestone timestamps for an incident
#
# PUT /v1/incidents/{incident_id}/milestones/bulk_update
# operationId: updateIncidentMilestonesBulk
# --milestones item shape: {type: string, occurred_at: string, remove?: bool}
export def "incidents-milestones-bulk-update updateIncidentMilestonesBulk" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bulk: string@bulk-completer
  milestones: list # item shape: {type: string, occurred_at: string, remove?: bool}
]: any -> record<data: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/milestones/bulk_update")
  let body = {bulk: $bulk, milestones: $milestones} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a note for an incident
#
# POST /v1/incidents/{incident_id}/notes
# operationId: createIncidentNote
# --status_pages item shape: {id: string, integration_slug: string}
export def "incidents-notes createIncidentNote" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string
  --occurred-at: string # ISO8601 timestamp for when the note occurred (format: date-time)
  --visibility: string@visibility-completer # default: private_to_org
  --status-pages: list # item shape: {id: string, integration_slug: string}
]: any -> record<id: string, body: string, created_at: string, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/notes")
  let body = {body: $body_body, occurred_at: $occurred_at, visibility: $visibility, status_pages: $status_pages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a note for an incident
#
# PATCH /v1/incidents/{incident_id}/notes/{note_id}
# operationId: updateIncidentNote
export def "incidents-notes updateIncidentNote" [
  note_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string
]: any -> record<id: string, body: string, created_at: string, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/notes/($note_id)")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List related changes for an incident
#
# GET /v1/incidents/{incident_id}/related_change_events
# operationId: listIncidentRelatedChanges
export def "incidents-related-change-events listIncidentRelatedChanges" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --type: string@type-completer-1 # The type of the relation to the incident
]: nothing -> record<data: table<id: string, created_at: string, updated_at: string, why: string, type: string, change_event: record, incident_id: string, created_by: record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/related_change_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a related change to an incident
#
# POST /v1/incidents/{incident_id}/related_change_events
# operationId: createIncidentRelatedChange
export def "incidents-related-change-events createIncidentRelatedChange" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  change_event_id: string # The ID of the change event to associate
  type: string@type-completer-1
  --why: string # A short description about why this change event is related
]: any -> record<id: string, created_at: string, updated_at: string, why: string, type: string, change_event: record<id: string, summary: string, description: string, external_id: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, environments: list<record>, related_changes: list<record>, identities: list<record>, authors: list<record>, attachments: list<record>, labels: record, services: list<record>>, incident_id: string, created_by: record<id: string, name: string, source: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/related_change_events")
  let body = {change_event_id: $change_event_id, type: $type, why: $why} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a related change event for an incident
#
# PATCH /v1/incidents/{incident_id}/related_change_events/{related_change_event_id}
# operationId: updateIncidentRelatedChangeEvent
export def "incidents-related-change-events updateIncidentRelatedChangeEvent" [
  related_change_event_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1
  --why: string # A short description about why this change event is related
]: any -> record<id: string, created_at: string, updated_at: string, why: string, type: string, change_event: record<id: string, summary: string, description: string, external_id: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, duration_ms: int, duration_iso8601: string, environments: list<record>, related_changes: list<record>, identities: list<record>, authors: list<record>, attachments: list<record>, labels: record, services: list<record>>, incident_id: string, created_by: record<id: string, name: string, source: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/related_change_events/($related_change_event_id)")
  let body = {type: $type, why: $why} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List incident relationships
#
# GET /v1/incidents/{incident_id}/relationships
# operationId: getIncidentRelationships
export def "incidents-relationships get" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<parent: record<id: string, name: string, number: string>, children: table<id: string, name: string, number: string>, siblings: table<id: string, name: string, number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/relationships")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve an incident
#
# PUT /v1/incidents/{incident_id}/resolve
# operationId: resolveIncident
export def "incidents-resolve resolveIncident" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --milestone: string # The slug of any milestone in the post-incident or closed phase to set on the incident (and its children, if `resolve_children` os set). Must be one of the configured milestones available on this incident.
]: any -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/resolve")
  let body = {milestone: $milestone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List role assignments for an incident
#
# GET /v1/incidents/{incident_id}/role_assignments
# operationId: listIncidentRoleAssignments
export def "incidents-role-assignments listIncidentRoleAssignments" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Filter on status of the role assignment
]: nothing -> record<data: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/role_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role assignment for an incident
#
# POST /v1/incidents/{incident_id}/role_assignments
# operationId: createIncidentRoleAssignment
export def "incidents-role-assignments createIncidentRoleAssignment" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The user ID to assign the role to
  incident_role_id: string # The Incident Role ID to assign the role to
]: any -> record<id: string, status: string, created_at: string, updated_at: string, incident_role: record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, discarded_at: string>, user: record<id: string, name: string, email: string, slack_user_id: string, slack_linked_: bool, created_at: string, updated_at: string, signals_enabled_notification_types: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/role_assignments")
  let body = {user_id: $user_id, incident_role_id: $incident_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role assignment from an incident
#
# DELETE /v1/incidents/{incident_id}/role_assignments/{role_assignment_id}
# operationId: deleteIncidentRoleAssignment
export def "incidents-role-assignments delete" [
  incident_id: string
  role_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, created_at: string, updated_at: string, incident_role: record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, discarded_at: string>, user: record<id: string, name: string, email: string, slack_user_id: string, slack_linked_: bool, created_at: string, updated_at: string, signals_enabled_notification_types: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/role_assignments/($role_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List similar incidents
#
# GET /v1/incidents/{incident_id}/similar
# operationId: getSimilarIncidents
export def "incidents-similar get" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --threshold: float # format: float, default: 0.2
  --limit: int # format: int32, default: 5
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "threshold" $threshold "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/similar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List status pages for an incident
#
# GET /v1/incidents/{incident_id}/status_pages
# operationId: listIncidentStatusPages
export def "incidents-status-pages listIncidentStatusPages" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/status_pages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a status page to an incident
#
# POST /v1/incidents/{incident_id}/status_pages
# operationId: createIncidentStatusPage
export def "incidents-status-pages createIncidentStatusPage" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  integration_slug: string
  integration_id: string
  --title: string
]: any -> record<id: string, url: string, external_id: string, name: string, display_name: string, integration: record<id: string, integration_name: string, integration_slug: string, display_name: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/status_pages")
  let body = {integration_slug: $integration_slug, integration_id: $integration_id, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a status page from an incident
#
# DELETE /v1/incidents/{incident_id}/status_pages/{status_page_id}
# operationId: deleteIncidentStatusPage
export def "incidents-status-pages delete" [
  status_page_id: string
  incident_id: string
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
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/status_pages/($status_page_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add tasks from a task list to an incident
#
# POST /v1/incidents/{incident_id}/task_lists
# operationId: createIncidentTaskList
export def "incidents-task-lists createIncidentTaskList" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  task_list_id: string # The id of the task list.
  --assignee-id: string # The ID of the user assigned to the tasks in this list.
]: any -> record<id: string, title: string, description: string, state: string, assignee: record<id: string, name: string, source: string, email: string>, created_by: record<id: string, name: string, source: string, email: string>, created_at: string, updated_at: string, due_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/task_lists")
  let body = {task_list_id: $task_list_id, assignee_id: $assignee_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List tasks for an incident
#
# GET /v1/incidents/{incident_id}/tasks
# operationId: listIncidentTasks
export def "incidents-tasks listIncidentTasks" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, title: string, description: string, state: string, assignee: record, created_by: record, created_at: string, updated_at: string, due_at: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task for an incident
#
# POST /v1/incidents/{incident_id}/tasks
# operationId: createIncidentTask
export def "incidents-tasks createIncidentTask" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of the task.
  --state: string # The state of the task. One of: open, in_progress, cancelled, done
  --description: string # A description of what the task is for.
  --assignee-id: string # The ID of the user assigned to the task.
  --due-at: string # The due date of the task. Relative values are supported such as '5m'
]: any -> record<id: string, title: string, description: string, state: string, assignee: record<id: string, name: string, source: string, email: string>, created_by: record<id: string, name: string, source: string, email: string>, created_at: string, updated_at: string, due_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/tasks")
  let body = {title: $title, state: $state, description: $description, assignee_id: $assignee_id, due_at: $due_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a task for an incident
#
# GET /v1/incidents/{incident_id}/tasks/{task_id}
# operationId: getIncidentTask
export def "incidents-tasks get" [
  task_id: string
  incident_id: string
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
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a task from an incident
#
# DELETE /v1/incidents/{incident_id}/tasks/{task_id}
# operationId: deleteIncidentTask
export def "incidents-tasks delete" [
  task_id: string
  incident_id: string
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
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a task for an incident
#
# PATCH /v1/incidents/{incident_id}/tasks/{task_id}
# operationId: updateIncidentTask
export def "incidents-tasks updateIncidentTask" [
  task_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the task.
  --description: string # A description of what the task is for.
  --state: string # The state of the task. One of: open, in_progress, cancelled, done
  --assignee-id: string # The ID of the user assigned to the task.
  --due-at: string # The due date of the task. Relative values are supported such as '5m'
]: any -> record<id: string, title: string, description: string, state: string, assignee: record<id: string, name: string, source: string, email: string>, created_by: record<id: string, name: string, source: string, email: string>, created_at: string, updated_at: string, due_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/tasks/($task_id)")
  let body = {title: $title, description: $description, state: $state, assignee_id: $assignee_id, due_at: $due_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Convert a task to a follow-up
#
# POST /v1/incidents/{incident_id}/tasks/{task_id}/convert
# operationId: convertIncidentTaskToFollowup
export def "incidents-tasks-convert convertIncidentTaskToFollowup" [
  task_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summary: string
  --project-id: string
  --description: string
  --state: string
  --tag-list: list # List of tags for the ticket
]: any -> record<data: table<id: string, title: string, description: string, state: string, assignee: record, created_by: record, created_at: string, updated_at: string, due_at: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/tasks/($task_id)/convert")
  let body = {summary: $summary, project_id: $project_id, description: $description, state: $state, tag_list: $tag_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Assign a team to an incident
#
# POST /v1/incidents/{incident_id}/team_assignments
# operationId: createIncidentTeamAssignment
export def "incidents-team-assignments createIncidentTeamAssignment" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  team_id: string # The team ID to associate to the incident
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/team_assignments")
  let body = {team_id: $team_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a team assignment from an incident
#
# DELETE /v1/incidents/{incident_id}/team_assignments/{team_assignment_id}
# operationId: deleteIncidentTeamAssignment
export def "incidents-team-assignments delete" [
  incident_id: string
  team_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role-assignment-ids: list # Team role assignments to unassign from the incident
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/team_assignments/($team_assignment_id)")
  let body = {role_assignment_ids: $role_assignment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List transcript messages for an incident
#
# GET /v1/incidents/{incident_id}/transcript
# operationId: getIncidentTranscript
export def "incidents-transcript get" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # The ID of the transcript entry to start after.
  --before: string # The ID of the transcript entry to start before.
  --qp-sort: string@sort-completer # The order to sort the transcript entries. (default: asc)
]: nothing -> record<id: string, speaker: string, start: int, until: int, words: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/transcript" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a transcript from an incident
#
# DELETE /v1/incidents/{incident_id}/transcript/{transcript_id}
# operationId: deleteIncidentTranscript
export def "incidents-transcript delete" [
  transcript_id: string
  incident_id: string
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
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/transcript/($transcript_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive an incident
#
# POST /v1/incidents/{incident_id}/unarchive
# operationId: unarchiveIncident
export def "incidents-unarchive unarchiveIncident" [
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: table<id: string, type: string, duration: string, occurred_at: string, created_at: string, updated_at: string>, lifecycle_phases: table<id: string, name: string, description: string, type: string, position: int, milestones: list>, lifecycle_measurements: table<id: string, name: string, description: string, slug: string, starts_at_milestone: string, ends_at_milestone: string, value: string, calculated_at: string>, active: bool, labels: record, role_assignments: table<id: string, status: string, created_at: string, updated_at: string, incident_role: record, user: record>, status_pages: table<id: string, url: string, external_id: string, name: string, display_name: string, integration: record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list<record>, conversations: list<record>>, report_id: string, ai_incident_summary: string, services: table<id: string, name: string>, environments: table<id: string, name: string>, functionalities: table<id: string, name: string>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: table<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list<record>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>>, impacts: table<id: string, type: string, impact: record, condition: record, conversations: list>, conference_bridges: table<id: string, attachments: list>, incident_channels: table<id: string, name: string, source: string, source_name: string, source_id: string, url: string, icon_url: string, status: string>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: table<id: string, status: string, created_at: string, updated_at: string, team: record>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>, custom_fields: table<name: string, value_type: string, display_name: string, description: string, slug: string, field_id: string, value_array: string, value_string: string, value: string>, field_requirements: table<field_id: string, required_at_milestone_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user's role in an incident
#
# GET /v1/incidents/{incident_id}/users/{user_id}
# operationId: getIncidentUserRole
export def "incidents-users get" [
  incident_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, created_at: string, updated_at: string, incident_role: record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, discarded_at: string>, user: record<id: string, name: string, email: string, slack_user_id: string, slack_linked_: bool, created_at: string, updated_at: string, signals_enabled_notification_types: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incident_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List catalog entries
#
# GET /v1/infrastructures
# operationId: listInfrastructures
export def "infrastructures listInfrastructures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query to search infrastructures by their name
  --omit-for: string # Omit for any infrastructure that is added to an incident using the format "incident/{incident_id}"
  --type: string # Restrict infrastructure search to given type.
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<type: string, infrastructure: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "omit_for" $omit_for "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/infrastructures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all available integrations
#
# GET /v1/integrations
# operationId: listIntegrations
export def "integrations listIntegrations" [
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
  let full_url = (build-url $base "/v1/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List AWS CloudTrail batches
#
# GET /v1/integrations/aws/cloudtrail_batches
# operationId: listAwsCloudtrailBatches
export def "integrations-aws-cloudtrail-batches listAwsCloudtrailBatches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --connection-id: string # AWS connection ID
]: nothing -> record<data: table<id: string, events_created: int, status: string, starts_at: string, ends_at: string, connection: record, created_at: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "connection_id" $connection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/aws/cloudtrail_batches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an AWS CloudTrail batch
#
# GET /v1/integrations/aws/cloudtrail_batches/{id}
# operationId: getAwsCloudTrailBatch
export def "integrations-aws-cloudtrail-batches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, events_created: int, status: string, starts_at: string, ends_at: string, connection: record<id: string, aws_account_id: string, target_arn: string, external_id: string, connection_status: string, status_text: string, status_description: string, environment_id: string, environment_name: string, regions: list<string>>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/aws/cloudtrail_batches/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an AWS CloudTrail batch
#
# PATCH /v1/integrations/aws/cloudtrail_batches/{id}
# operationId: updateAwsCloudTrailBatch
export def "integrations-aws-cloudtrail-batches updateAwsCloudTrailBatch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --events-created: int # format: int32
  --status: string
  --body-error: string
  --ends-at: string # format: date-time
]: any -> record<id: string, events_created: int, status: string, starts_at: string, ends_at: string, connection: record<id: string, aws_account_id: string, target_arn: string, external_id: string, connection_status: string, status_text: string, status_description: string, environment_id: string, environment_name: string, regions: list<string>>, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/aws/cloudtrail_batches/($id)")
  let body = {events_created: $events_created, status: $status, error: $body_error, ends_at: $ends_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List events for an AWS CloudTrail batch
#
# GET /v1/integrations/aws/cloudtrail_batches/{id}/events
# operationId: getAwsCloudtrailBatchEvents
export def "integrations-aws-cloudtrail-batches-events get" [
  id: string
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
  let full_url = (build-url $base $"/v1/integrations/aws/cloudtrail_batches/($id)/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List AWS integration connections
#
# GET /v1/integrations/aws/connections
# operationId: listAwsConnections
export def "integrations-aws-connections listAwsConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --aws-account-id: string # AWS account ID containing the role to be assumed
  --target-arn: string # ARN of the role to be assumed
  --external-id: string # The external ID supplied when assuming the role
]: nothing -> record<data: table<id: string, aws_account_id: string, target_arn: string, external_id: string, connection_status: string, status_text: string, status_description: string, environment_id: string, environment_name: string, regions: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "aws_account_id" $aws_account_id "scalar") (serialize-qp "target_arn" $target_arn "scalar") (serialize-qp "external_id" $external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/aws/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an AWS connection
#
# GET /v1/integrations/aws/connections/{id}
# operationId: getAwsConnection
export def "integrations-aws-connections get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, aws_account_id: string, target_arn: string, external_id: string, connection_status: string, status_text: string, status_description: string, environment_id: string, environment_name: string, regions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/aws/connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an AWS connection
#
# PATCH /v1/integrations/aws/connections/{id}
# operationId: updateAwsConnection
export def "integrations-aws-connections updateAwsConnection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-account-id: string
  --target-arn: string
  --connection-status: string
]: any -> record<id: string, aws_account_id: string, target_arn: string, external_id: string, connection_status: string, status_text: string, status_description: string, environment_id: string, environment_name: string, regions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/aws/connections/($id)")
  let body = {aws_account_id: $aws_account_id, target_arn: $target_arn, connection_status: $connection_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Confluence spaces
#
# GET /v1/integrations/confluence_cloud/connections/{id}/space/search
# operationId: listConfluenceSpaces
export def "integrations-confluence-cloud-connections-space-search listConfluenceSpaces" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyword: string # Space Key
]: nothing -> record<key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyword" $keyword "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/confluence_cloud/connections/($id)/space/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List integration connections
#
# GET /v1/integrations/connections
# operationId: listIntegrationConnections
export def "integrations-connections listIntegrationConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --integration-slug: string # Only return installed integrations with the supplied slugs (types).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "integration_slug" $integration_slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new integration connection
#
# POST /v1/integrations/connections/{slug}
# operationId: createIntegrationConnection
export def "integrations-connections createIntegrationConnection" [
  slug: string
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
  let full_url = (build-url $base $"/v1/integrations/connections/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an integration connection
#
# PATCH /v1/integrations/connections/{slug}/{connection_id}
# operationId: updateIntegrationConnection
export def "integrations-connections updateIntegrationConnection" [
  slug: string
  connection_id: string
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
  let full_url = (build-url $base $"/v1/integrations/connections/($slug)/($connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh an integration connection
#
# PATCH /v1/integrations/connections/{slug}/{connection_id}/refresh
# operationId: refreshIntegrationConnection
export def "integrations-connections-refresh refreshIntegrationConnection" [
  slug: string
  connection_id: string
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
  let full_url = (build-url $base $"/v1/integrations/connections/($slug)/($connection_id)/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a field mapping configuration
#
# PATCH /v1/integrations/field_maps/{field_map_id}
# operationId: updateIntegrationFieldMap
export def "integrations-field-maps updateIntegrationFieldMap" [
  field_map_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_id: string, connection_type: string, entity_id: string, entity_type: string, body: record, available_fields_url: string, data_bag_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/field_maps/($field_map_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available fields for field mapping
#
# GET /v1/integrations/field_maps/{field_map_id}/available_fields
# operationId: getIntegrationFieldMapAvailableFields
export def "integrations-field-maps-available-fields get" [
  field_map_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string, label: string, type: string, allowed_values: string, required: string, help_text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/field_maps/($field_map_id)/available_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Slack emoji actions
#
# GET /v1/integrations/slack/connections/{connection_id}/emoji_actions
# operationId: listSlackEmojiActions
export def "integrations-slack-connections-emoji-actions listSlackEmojiActions" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/integrations/slack/connections/($connection_id)/emoji_actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Slack emoji action
#
# POST /v1/integrations/slack/connections/{connection_id}/emoji_actions
# operationId: createSlackEmojiAction
export def "integrations-slack-connections-emoji-actions createSlackEmojiAction" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  emoji_name: string # The name of the emoji to associate with this action
  --incident-type-id: string # The ID of the incident type to associate with this emoji action
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/slack/connections/($connection_id)/emoji_actions")
  let body = {emoji_name: $emoji_name, incident_type_id: $incident_type_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Slack emoji action
#
# GET /v1/integrations/slack/connections/{connection_id}/emoji_actions/{emoji_action_id}
# operationId: getSlackEmojiAction
export def "integrations-slack-connections-emoji-actions get" [
  connection_id: string
  emoji_action_id: string
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
  let full_url = (build-url $base $"/v1/integrations/slack/connections/($connection_id)/emoji_actions/($emoji_action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Slack emoji action
#
# DELETE /v1/integrations/slack/connections/{connection_id}/emoji_actions/{emoji_action_id}
# operationId: deleteSlackEmojiAction
export def "integrations-slack-connections-emoji-actions delete" [
  connection_id: string
  emoji_action_id: string
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
  let full_url = (build-url $base $"/v1/integrations/slack/connections/($connection_id)/emoji_actions/($emoji_action_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Slack emoji action
#
# PATCH /v1/integrations/slack/connections/{connection_id}/emoji_actions/{emoji_action_id}
# operationId: updateSlackEmojiAction
export def "integrations-slack-connections-emoji-actions updateSlackEmojiAction" [
  connection_id: string
  emoji_action_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emoji-name: string # The name of the emoji to associate with this action
  --incident-type-id: string # The ID of the incident type to associate with this emoji action
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/slack/connections/($connection_id)/emoji_actions/($emoji_action_id)")
  let body = {emoji_name: $emoji_name, incident_type_id: $incident_type_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Slack workspaces for a connection
#
# GET /v1/integrations/slack/connections/{connection_id}/workspaces
# operationId: getSlackWorkspaces
export def "integrations-slack-connections-workspaces get" [
  connection_id: string
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
  let full_url = (build-url $base $"/v1/integrations/slack/connections/($connection_id)/workspaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Slack usergroups
#
# GET /v1/integrations/slack/usergroups
# operationId: listSlackUsergroups
export def "integrations-slack-usergroups listSlackUsergroups" [
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
  let full_url = (build-url $base "/v1/integrations/slack/usergroups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an integration status
#
# GET /v1/integrations/statuses/{slug}
# operationId: getIntegrationStatus
export def "integrations-statuses get" [
  slug: string
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
  let full_url = (build-url $base $"/v1/integrations/statuses/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Statuspage connections
#
# GET /v1/integrations/statuspage/connections
# operationId: listStatuspageConnections
export def "integrations-statuspage-connections listStatuspageConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, page_name: string, page_id: string, conditions: list, severities: list, milestone_mappings: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/statuspage/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Statuspage connection
#
# GET /v1/integrations/statuspage/connections/{connection_id}
# operationId: getStatuspageConnection
export def "integrations-statuspage-connections get" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, page_name: string, page_id: string, conditions: table<condition_id: string, condition_name: string, statuspageio_condition: string>, severities: table<severity_slug: string, remote_status: string>, milestone_mappings: table<milestone_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/statuspage/connections/($connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Statuspage connection
#
# DELETE /v1/integrations/statuspage/connections/{connection_id}
# operationId: deleteStatuspageConnection
export def "integrations-statuspage-connections delete" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, page_name: string, page_id: string, conditions: table<condition_id: string, condition_name: string, statuspageio_condition: string>, severities: table<severity_slug: string, remote_status: string>, milestone_mappings: table<milestone_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/statuspage/connections/($connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Statuspage connection
#
# PATCH /v1/integrations/statuspage/connections/{connection_id}
# operationId: updateStatuspageConnection
# --severities item shape: {severity_slug: string, remote_status: string}
# --conditions item shape: {condition_id: string, statuspageio_condition: string}
# --milestone_mappings item shape: {milestone_id: string, status: "investigating"|"identified"|"monitoring"|"resolved"}
export def "integrations-statuspage-connections updateStatuspageConnection" [
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-id: string
  --severities: list # item shape: {severity_slug: string, remote_status: string}
  --conditions: list # item shape: {condition_id: string, statuspageio_condition: string}
  --milestone-mappings: list # item shape: {milestone_id: string, status: "investigating"|"identified"|"monitoring"|"resolved"}
]: any -> record<id: string, page_name: string, page_id: string, conditions: table<condition_id: string, condition_name: string, statuspageio_condition: string>, severities: table<severity_slug: string, remote_status: string>, milestone_mappings: table<milestone_id: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/statuspage/connections/($connection_id)")
  let body = {page_id: $page_id, severities: $severities, conditions: $conditions, milestone_mappings: $milestone_mappings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List StatusPage pages for a connection
#
# GET /v1/integrations/statuspage/connections/{connection_id}/pages
# operationId: listStatuspagePages
export def "integrations-statuspage-connections-pages listStatuspagePages" [
  connection_id: string
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
  let full_url = (build-url $base $"/v1/integrations/statuspage/connections/($connection_id)/pages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for Zendesk tickets
#
# GET /v1/integrations/zendesk/search
# operationId: searchZendeskTickets
export def "integrations-zendesk-search searchZendeskTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ticket-id: string # Zendesk ticket ID
  --include: string # Use to include attached_incidents
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ticket_id" $ticket_id "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/integrations/zendesk/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an integration
#
# GET /v1/integrations/{integration_id}
# operationId: getIntegration
export def "integrations get" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, slug: string, name: string, description: string, setup_url: string, created_at: string, connections: record<id: string, integration_slug: string, integration_id: string, display_name: string, configuration_url: string, authorized_by: string, authorized_by_id: string, created_at: string, updated_at: string, details: record, default_authorized_actor: record<id: string, name: string, source: string, email: string>>, enabled: bool, installed: bool, deprecated: bool, logo: record<logo_url: string>, nat_ip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List measurement definitions
#
# GET /v1/lifecycles/measurement_definitions
# operationId: listMeasurementDefinitions
export def "lifecycles-measurement-definitions listMeasurementDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/lifecycles/measurement_definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a measurement definition
#
# POST /v1/lifecycles/measurement_definitions
# operationId: createMeasurementDefinition
export def "lifecycles-measurement-definitions createMeasurementDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --slug: string
  --description: string
  starts_at_milestone_id: string
  ends_at_milestone_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/lifecycles/measurement_definitions")
  let body = {name: $name, slug: $slug, description: $description, starts_at_milestone_id: $starts_at_milestone_id, ends_at_milestone_id: $ends_at_milestone_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a measurement definition
#
# GET /v1/lifecycles/measurement_definitions/{measurement_definition_id}
# operationId: getMeasurementDefinition
export def "lifecycles-measurement-definitions get" [
  measurement_definition_id: string
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
  let full_url = (build-url $base $"/v1/lifecycles/measurement_definitions/($measurement_definition_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive a measurement definition
#
# DELETE /v1/lifecycles/measurement_definitions/{measurement_definition_id}
# operationId: deleteMeasurementDefinition
export def "lifecycles-measurement-definitions delete" [
  measurement_definition_id: string
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
  let full_url = (build-url $base $"/v1/lifecycles/measurement_definitions/($measurement_definition_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a measurement definition
#
# PATCH /v1/lifecycles/measurement_definitions/{measurement_definition_id}
# operationId: updateMeasurementDefinition
export def "lifecycles-measurement-definitions updateMeasurementDefinition" [
  measurement_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --slug: string
  --description: string
  --starts-at-milestone-id: string
  --ends-at-milestone-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lifecycles/measurement_definitions/($measurement_definition_id)")
  let body = {name: $name, slug: $slug, description: $description, starts_at_milestone_id: $starts_at_milestone_id, ends_at_milestone_id: $ends_at_milestone_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a milestone for an incident lifecycle
#
# POST /v1/lifecycles/milestones
# operationId: createLifecycleMilestone
export def "lifecycles-milestones createLifecycleMilestone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the milestone
  description: string # A long-form description of the milestone's purpose
  --slug: string # A unique identifier for the milestone. If not provided, one will be generated from the name.
  phase_id: string # The ID of the phase to which the milestone should belong
  --position: int # The position of the milestone within the phase. If not provided, the milestone will be added as the last milestone in the phase. (format: int32)
  --required-at-milestone-id: string # The ID of a later milestone that cannot be started until this milestone has a timestamp populated
]: any -> record<data: table<id: string, name: string, description: string, type: string, position: int, milestones: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/lifecycles/milestones")
  let body = {name: $name, description: $description, slug: $slug, phase_id: $phase_id, position: $position, required_at_milestone_id: $required_at_milestone_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a lifecycle milestone
#
# DELETE /v1/lifecycles/milestones/{milestone_id}
# operationId: deleteLifecycleMilestone
export def "lifecycles-milestones delete" [
  milestone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, type: string, position: int, milestones: table<id: string, name: string, description: string, slug: string, position: int, created_by: record, updated_by: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lifecycles/milestones/($milestone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a lifecycle milestone
#
# PATCH /v1/lifecycles/milestones/{milestone_id}
# operationId: updateLifecycleMilestone
export def "lifecycles-milestones updateLifecycleMilestone" [
  milestone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the milestone
  --description: string # A long-form description of the milestone's purpose
  --slug: string # A unique identifier for the milestone. If not provided, one will be generated from the name.
  --position: int # The position of the milestone within the phase. If not provided, the milestone will be added as the last milestone in the phase. (format: int32)
  --required-at-milestone-id: string # The ID of a later milestone that cannot be started until this milestone has a timestamp populated
]: any -> record<id: string, name: string, description: string, type: string, position: int, milestones: table<id: string, name: string, description: string, slug: string, position: int, created_by: record, updated_by: record, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/lifecycles/milestones/($milestone_id)")
  let body = {name: $name, description: $description, slug: $slug, position: $position, required_at_milestone_id: $required_at_milestone_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List lifecycle phases and milestones
#
# GET /v1/lifecycles/phases
# operationId: listLifecyclePhases
export def "lifecycles-phases listLifecyclePhases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, name: string, description: string, type: string, position: int, milestones: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/lifecycles/phases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List incident metrics and analytics
#
# GET /v1/metrics/incidents
# operationId: listIncidentMetrics
export def "metrics-incidents listIncidentMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The start date to return metrics from (format: date)
  --end-date: string # The end date to return metrics from (format: date)
  --bucket-size: string@bucket-size-completer
  --by: string@by-completer
  --sort-field: string@sort-field-completer
  --sort-direction: string@sort-direction-completer
  --sort-limit: int # format: int32
  --conditions: string
]: nothing -> record<type: string, by: string, bucket_size: int, display_information: record, keys: list<string>, buckets: list<record>, sort: record<field: string, direction: string, limit: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "bucket_size" $bucket_size "scalar") (serialize-qp "by" $by "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_limit" $sort_limit "scalar") (serialize-qp "conditions" $conditions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List milestone funnel metrics
#
# GET /v1/metrics/milestone_funnel
# operationId: getMilestoneFunnelMetrics
export def "metrics-milestone-funnel get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conditions: string # A JSON string that defines 'logic' and 'user_data'
  --environments: string # A comma separated list of environment IDs or 'is_empty' to filter for incidents with no impacted environments
  --services: string # A comma separated list of service IDs or 'is_empty' to filter for incidents with no impacted services
  --functionalities: string # A comma separated list of functionality IDs or 'is_empty' to filter for incidents with no impacted functionalities
  --excluded-infrastructure-ids: string # A comma separated list of infrastructure IDs. Returns incidents that do not have the following infrastructure ids associated with them.
  --teams: string # A comma separated list of team IDs
  --assigned-teams: string # A comma separated list of IDs for assigned teams or 'is_empty' to filter for incidents with no active team assignments
  --status: string # Incident status
  --start-date: string # Filters for incidents that started on or after this date (format: date)
  --end-date: string # Filters for incidents that started on or before this date (format: date)
  --resolved-at-or-after: string # Filters for incidents that were resolved at or after this time. Combine this with the `current_milestones` parameter if you wish to omit incidents that were re-opened and are still active. (format: date-time)
  --resolved-at-or-before: string # Filters for incidents that were resolved at or before this time. Combine this with the `current_milestones` parameter if you wish to omit incidents that were re-opened and are still active. (format: date-time)
  --created-at-or-after: string # Filters for incidents that were created at or after this time (format: date-time)
  --created-at-or-before: string # Filters for incidents that were created at or before this time (format: date-time)
  --qp-query: string # A text query for an incident that searches on name, summary, and desciption
  --name: string # A query to search incidents by their name
  --saved-search-id: string # The id of a previously saved search.
  --priorities: string # A text value of priority
  --priority-not-set: oneof<nothing, bool> # Flag for including incidents where priority has not been set
  --severities: string # A text value of severity
  --severity-not-set: oneof<nothing, bool> # Flag for including incidents where severity has not been set
  --current-milestones: string # A comma separated list of current milestones
  --tags: string # A comma separated list of tags
  --tag-match-strategy: string@tag-match-strategy-completer # A matching strategy for the tags provided
  --archived: oneof<nothing, bool> # Return archived incidents
  --updated-after: string # Filters for incidents that were updated after this date (format: date-time)
  --updated-before: string # Filters for incidents that were updated before this date (format: date-time)
  --incident-type-id: string # A comma separated list of incident type IDs
  --group-by: list
]: any -> record<data: table<time_bucket: string, filter_params: record, milestone_counts: list>, columns: table<name: string, label: string, tooltip: string, id: string>, groupings: record<bucket_size: string>, meta: record<deleted_milestones: list<string>, added_milestones: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conditions" $conditions "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "functionalities" $functionalities "scalar") (serialize-qp "excluded_infrastructure_ids" $excluded_infrastructure_ids "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "assigned_teams" $assigned_teams "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "resolved_at_or_after" $resolved_at_or_after "scalar") (serialize-qp "resolved_at_or_before" $resolved_at_or_before "scalar") (serialize-qp "created_at_or_after" $created_at_or_after "scalar") (serialize-qp "created_at_or_before" $created_at_or_before "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "saved_search_id" $saved_search_id "scalar") (serialize-qp "priorities" $priorities "scalar") (serialize-qp "priority_not_set" $priority_not_set "scalar") (serialize-qp "severities" $severities "scalar") (serialize-qp "severity_not_set" $severity_not_set "scalar") (serialize-qp "current_milestones" $current_milestones "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "tag_match_strategy" $tag_match_strategy "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "incident_type_id" $incident_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics/milestone_funnel" $qp)
  let body = {group_by: $group_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Fetch infrastructure metrics based on custom query
#
# GET /v1/metrics/mttx
# operationId: getV1MetricsMttx
export def "metrics-mttx get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --conditions: string # A JSON string that defines 'logic' and 'user_data'
  --environments: string # A comma separated list of environment IDs or 'is_empty' to filter for incidents with no impacted environments
  --services: string # A comma separated list of service IDs or 'is_empty' to filter for incidents with no impacted services
  --functionalities: string # A comma separated list of functionality IDs or 'is_empty' to filter for incidents with no impacted functionalities
  --excluded-infrastructure-ids: string # A comma separated list of infrastructure IDs. Returns incidents that do not have the following infrastructure ids associated with them.
  --teams: string # A comma separated list of team IDs
  --assigned-teams: string # A comma separated list of IDs for assigned teams or 'is_empty' to filter for incidents with no active team assignments
  --status: string # Incident status
  --start-date: string # Filters for incidents that started on or after this date (format: date)
  --end-date: string # Filters for incidents that started on or before this date (format: date)
  --resolved-at-or-after: string # Filters for incidents that were resolved at or after this time. Combine this with the `current_milestones` parameter if you wish to omit incidents that were re-opened and are still active. (format: date-time)
  --resolved-at-or-before: string # Filters for incidents that were resolved at or before this time. Combine this with the `current_milestones` parameter if you wish to omit incidents that were re-opened and are still active. (format: date-time)
  --created-at-or-after: string # Filters for incidents that were created at or after this time (format: date-time)
  --created-at-or-before: string # Filters for incidents that were created at or before this time (format: date-time)
  --qp-query: string # A text query for an incident that searches on name, summary, and desciption
  --name: string # A query to search incidents by their name
  --saved-search-id: string # The id of a previously saved search.
  --priorities: string # A text value of priority
  --priority-not-set: oneof<nothing, bool> # Flag for including incidents where priority has not been set
  --severities: string # A text value of severity
  --severity-not-set: oneof<nothing, bool> # Flag for including incidents where severity has not been set
  --current-milestones: string # A comma separated list of current milestones
  --tags: string # A comma separated list of tags
  --tag-match-strategy: string@tag-match-strategy-completer # A matching strategy for the tags provided
  --archived: oneof<nothing, bool> # Return archived incidents
  --updated-after: string # Filters for incidents that were updated after this date (format: date-time)
  --updated-before: string # Filters for incidents that were updated before this date (format: date-time)
  --incident-type-id: string # A comma separated list of incident type IDs
  --custom-field-id: string
  --sort-by: string@sort-by-completer
  --measurements: string # Comma-separated list of measurements to include in the response
  --group-by: list
]: any -> record<groupings: table<type: string, id_attribute: string, name_attribute: string>, data: table<group_attributes: string, filter_params: record, count: int, mttd: float, mtta: float, mttm: float, mttr: float, count_diff: int, count_percent_diff: float, mttd_diff: float, mtta_diff: float, mttm_diff: float, mttr_diff: float, mttd_percent_diff: float, mtta_percent_diff: float, mttm_percent_diff: float, mttr_percent_diff: float, healthiness: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "conditions" $conditions "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "functionalities" $functionalities "scalar") (serialize-qp "excluded_infrastructure_ids" $excluded_infrastructure_ids "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "assigned_teams" $assigned_teams "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "resolved_at_or_after" $resolved_at_or_after "scalar") (serialize-qp "resolved_at_or_before" $resolved_at_or_before "scalar") (serialize-qp "created_at_or_after" $created_at_or_after "scalar") (serialize-qp "created_at_or_before" $created_at_or_before "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "saved_search_id" $saved_search_id "scalar") (serialize-qp "priorities" $priorities "scalar") (serialize-qp "priority_not_set" $priority_not_set "scalar") (serialize-qp "severities" $severities "scalar") (serialize-qp "severity_not_set" $severity_not_set "scalar") (serialize-qp "current_milestones" $current_milestones "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "tag_match_strategy" $tag_match_strategy "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "incident_type_id" $incident_type_id "scalar") (serialize-qp "custom_field_id" $custom_field_id "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "measurements" $measurements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics/mttx" $qp)
  let body = {group_by: $group_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List retrospective metrics for a date range
#
# GET /v1/metrics/retrospectives
# operationId: listRetrospectiveMetrics
export def "metrics-retrospectives listRetrospectiveMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The start date to return metrics from (format: date)
  --end-date: string # The end date to return metrics from (format: date)
]: nothing -> record<data: table<x: string, y: float>, summary: record<completed: int, total: int, incomplete: int, mean: float, shortest: float, longest: float, completion_percentage: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics/retrospectives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ticket funnel metrics
#
# GET /v1/metrics/ticket_funnel
# operationId: getTicketFunnelMetrics
export def "metrics-ticket-funnel get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conditions: string # A JSON string that defines 'logic' and 'user_data'
  --environments: string # A comma separated list of environment IDs or 'is_empty' to filter for incidents with no impacted environments
  --services: string # A comma separated list of service IDs or 'is_empty' to filter for incidents with no impacted services
  --functionalities: string # A comma separated list of functionality IDs or 'is_empty' to filter for incidents with no impacted functionalities
  --excluded-infrastructure-ids: string # A comma separated list of infrastructure IDs. Returns incidents that do not have the following infrastructure ids associated with them.
  --teams: string # A comma separated list of team IDs
  --assigned-teams: string # A comma separated list of IDs for assigned teams or 'is_empty' to filter for incidents with no active team assignments
  --status: string # Incident status
  --start-date: string # Filters for incidents that started on or after this date (format: date)
  --end-date: string # Filters for incidents that started on or before this date (format: date)
  --resolved-at-or-after: string # Filters for incidents that were resolved at or after this time. Combine this with the `current_milestones` parameter if you wish to omit incidents that were re-opened and are still active. (format: date-time)
  --resolved-at-or-before: string # Filters for incidents that were resolved at or before this time. Combine this with the `current_milestones` parameter if you wish to omit incidents that were re-opened and are still active. (format: date-time)
  --created-at-or-after: string # Filters for incidents that were created at or after this time (format: date-time)
  --created-at-or-before: string # Filters for incidents that were created at or before this time (format: date-time)
  --qp-query: string # A text query for an incident that searches on name, summary, and desciption
  --name: string # A query to search incidents by their name
  --saved-search-id: string # The id of a previously saved search.
  --priorities: string # A text value of priority
  --priority-not-set: oneof<nothing, bool> # Flag for including incidents where priority has not been set
  --severities: string # A text value of severity
  --severity-not-set: oneof<nothing, bool> # Flag for including incidents where severity has not been set
  --current-milestones: string # A comma separated list of current milestones
  --tags: string # A comma separated list of tags
  --tag-match-strategy: string@tag-match-strategy-completer # A matching strategy for the tags provided
  --archived: oneof<nothing, bool> # Return archived incidents
  --updated-after: string # Filters for incidents that were updated after this date (format: date-time)
  --updated-before: string # Filters for incidents that were updated before this date (format: date-time)
  --incident-type-id: string # A comma separated list of incident type IDs
  --group-by: list
]: any -> record<data: table<time_bucket: string, filter_params: record, tasks_created: int, tasks_done: int, follow_ups_created: int, follow_ups_done: int>, groupings: record<bucket_size: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conditions" $conditions "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "functionalities" $functionalities "scalar") (serialize-qp "excluded_infrastructure_ids" $excluded_infrastructure_ids "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "assigned_teams" $assigned_teams "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "resolved_at_or_after" $resolved_at_or_after "scalar") (serialize-qp "resolved_at_or_before" $resolved_at_or_before "scalar") (serialize-qp "created_at_or_after" $created_at_or_after "scalar") (serialize-qp "created_at_or_before" $created_at_or_before "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "saved_search_id" $saved_search_id "scalar") (serialize-qp "priorities" $priorities "scalar") (serialize-qp "priority_not_set" $priority_not_set "scalar") (serialize-qp "severities" $severities "scalar") (serialize-qp "severity_not_set" $severity_not_set "scalar") (serialize-qp "current_milestones" $current_milestones "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "tag_match_strategy" $tag_match_strategy "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "incident_type_id" $incident_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics/ticket_funnel" $qp)
  let body = {group_by: $group_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List user involvement metrics
#
# GET /v1/metrics/user_involvements
# operationId: listUserInvolvementMetrics
export def "metrics-user-involvements listUserInvolvementMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The start date to return metrics from (format: date)
  --end-date: string # The end date to return metrics from (format: date)
  --bucket-size: string
  --by: string
  --sort-field: string@sort-field-completer-1
  --sort-direction: string@sort-direction-completer
  --sort-limit: int # format: int32
]: nothing -> record<type: string, by: string, bucket_size: int, display_information: record, keys: list<string>, buckets: list<record>, sort: record<field: string, direction: string, limit: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "bucket_size" $bucket_size "scalar") (serialize-qp "by" $by "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_limit" $sort_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/metrics/user_involvements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List metrics for all services, environments, functionalities, or customers
#
# GET /v1/metrics/{infra_type}
# operationId: listInfrastructureMetrics
export def "metrics listInfrastructureMetrics" [
  infra_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The start date to return metrics from; defaults to 30 days ago (format: date)
  --end-date: string # The end date to return metrics from, defaults to today (format: date)
]: nothing -> record<data: table<id: string, name: string, mttd: int, mtta: int, mttm: int, mttr: int, count: int, total_time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/metrics/($infra_type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics for a specific catalog entry
#
# GET /v1/metrics/{infra_type}/{infra_id}
# operationId: getInfrastructureMetrics
export def "metrics get" [
  infra_type: string
  infra_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The start date to return metrics from; defaults to 30 days ago (format: date)
  --end-date: string # The end date to return metrics from, defaults to today (format: date)
]: nothing -> record<id: string, name: string, mttd: int, mtta: int, mttm: int, mttr: int, count: int, total_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/metrics/($infra_type)/($infra_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check API connectivity
#
# GET /v1/noauth/ping
# operationId: apiPingNoAuth
export def "noauth-ping apiPingNoAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<response: string, actor: record<id: string, name: string, email: string, type: string>, organization: record<name: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/noauth/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a status page subscription
#
# POST /v1/nunc/subscriptions
# operationId: createStatusPageSubscription
export def "nunc-subscriptions createStatusPageSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
]: any -> record<response: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/nunc/subscriptions")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unsubscribe from status page notifications
#
# DELETE /v1/nunc/subscriptions/{unsubscribe_token}
# operationId: deleteNuncSubscription
export def "nunc-subscriptions delete" [
  unsubscribe_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<response: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc/subscriptions/($unsubscribe_token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List status pages
#
# GET /v1/nunc_connections
# operationId: listStatusPages
export def "nunc-connections listStatusPages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record, components: record, component_groups: record, logo: record, cover_image: record, favicon: record, open_graph_image: record, dark_logo: record, enable_histogram: bool, ui_version: int, links: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/nunc_connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a status page
#
# POST /v1/nunc_connections
# operationId: createStatusPage
export def "nunc-connections createStatusPage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  domain: string
  --company-name: string
  --company-website: string
  --company-tos-url: string
  --greeting-title: string
  --greeting-body: string
  --operational-message: string
  --title: string
  conditionsnunc_condition: list # Status page condition to map your severity matrix condition to
  conditionscondition_id: list # Severity matrix condition id
  componentsinfrastructure_type: list
  componentsinfrastructure_id: list
  --primary-color: string
  --secondary-color: string
  --exposed-fields: list
  --enable-histogram: oneof<nothing, bool>
  --ui-version: int # format: int32
]: any -> record<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record<nunc_condition: string, condition_name: string, condition_id: string>, components: record<infrastructure_type: string, infrastructure_id: string, label: string, position: int, component_group_id: string>, component_groups: record<id: string, component_group_id: string, name: string, position: int>, logo: record<original_url: string, versions_urls: record>, cover_image: record<original_url: string, versions_urls: record>, favicon: record<original_url: string, versions_urls: record>, open_graph_image: record<original_url: string, versions_urls: record>, dark_logo: record<original_url: string, versions_urls: record>, enable_histogram: bool, ui_version: int, links: table<id: string, href_url: string, icon_url: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/nunc_connections")
  let body = {domain: $domain, company_name: $company_name, company_website: $company_website, company_tos_url: $company_tos_url, greeting_title: $greeting_title, greeting_body: $greeting_body, operational_message: $operational_message, title: $title, conditions[nunc_condition]: $conditionsnunc_condition, conditions[condition_id]: $conditionscondition_id, components[infrastructure_type]: $componentsinfrastructure_type, components[infrastructure_id]: $componentsinfrastructure_id, primary_color: $primary_color, secondary_color: $secondary_color, exposed_fields: $exposed_fields, enable_histogram: $enable_histogram, ui_version: $ui_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a status page
#
# GET /v1/nunc_connections/{nunc_connection_id}
# operationId: getStatusPage
export def "nunc-connections get" [
  nunc_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record<nunc_condition: string, condition_name: string, condition_id: string>, components: record<infrastructure_type: string, infrastructure_id: string, label: string, position: int, component_group_id: string>, component_groups: record<id: string, component_group_id: string, name: string, position: int>, logo: record<original_url: string, versions_urls: record>, cover_image: record<original_url: string, versions_urls: record>, favicon: record<original_url: string, versions_urls: record>, open_graph_image: record<original_url: string, versions_urls: record>, dark_logo: record<original_url: string, versions_urls: record>, enable_histogram: bool, ui_version: int, links: table<id: string, href_url: string, icon_url: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a status page
#
# PUT /v1/nunc_connections/{nunc_connection_id}
# operationId: updateStatusPage
export def "nunc-connections updateStatusPage" [
  nunc_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-name: string
  --company-website: string
  --company-tos-url: string
  --greeting-title: string
  --greeting-body: string
  --operational-message: string
  --title: string
  conditionsnunc_condition: list # Status page condition to map your severity matrix condition to
  conditionscondition_id: list # Severity matrix condition id
  componentsinfrastructure_type: list
  componentsinfrastructure_id: list
  --primary-color: string
  --secondary-color: string
  --exposed-fields: list
  --enable-histogram: oneof<nothing, bool>
  --ui-version: int # format: int32
]: any -> record<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record<nunc_condition: string, condition_name: string, condition_id: string>, components: record<infrastructure_type: string, infrastructure_id: string, label: string, position: int, component_group_id: string>, component_groups: record<id: string, component_group_id: string, name: string, position: int>, logo: record<original_url: string, versions_urls: record>, cover_image: record<original_url: string, versions_urls: record>, favicon: record<original_url: string, versions_urls: record>, open_graph_image: record<original_url: string, versions_urls: record>, dark_logo: record<original_url: string, versions_urls: record>, enable_histogram: bool, ui_version: int, links: table<id: string, href_url: string, icon_url: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)")
  let body = {company_name: $company_name, company_website: $company_website, company_tos_url: $company_tos_url, greeting_title: $greeting_title, greeting_body: $greeting_body, operational_message: $operational_message, title: $title, conditions[nunc_condition]: $conditionsnunc_condition, conditions[condition_id]: $conditionscondition_id, components[infrastructure_type]: $componentsinfrastructure_type, components[infrastructure_id]: $componentsinfrastructure_id, primary_color: $primary_color, secondary_color: $secondary_color, exposed_fields: $exposed_fields, enable_histogram: $enable_histogram, ui_version: $ui_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a status page
#
# DELETE /v1/nunc_connections/{nunc_connection_id}
# operationId: deleteStatusPage
export def "nunc-connections delete" [
  nunc_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record<nunc_condition: string, condition_name: string, condition_id: string>, components: record<infrastructure_type: string, infrastructure_id: string, label: string, position: int, component_group_id: string>, component_groups: record<id: string, component_group_id: string, name: string, position: int>, logo: record<original_url: string, versions_urls: record>, cover_image: record<original_url: string, versions_urls: record>, favicon: record<original_url: string, versions_urls: record>, open_graph_image: record<original_url: string, versions_urls: record>, dark_logo: record<original_url: string, versions_urls: record>, enable_histogram: bool, ui_version: int, links: table<id: string, href_url: string, icon_url: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a component group for a status page
#
# POST /v1/nunc_connections/{nunc_connection_id}/component_groups
# operationId: createStatusPageComponentGroup
export def "nunc-connections-component-groups createStatusPageComponentGroup" [
  nunc_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --component-group-id: string
  --position: int # format: int32
]: any -> record<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record<nunc_condition: string, condition_name: string, condition_id: string>, components: record<infrastructure_type: string, infrastructure_id: string, label: string, position: int, component_group_id: string>, component_groups: record<id: string, component_group_id: string, name: string, position: int>, logo: record<original_url: string, versions_urls: record>, cover_image: record<original_url: string, versions_urls: record>, favicon: record<original_url: string, versions_urls: record>, open_graph_image: record<original_url: string, versions_urls: record>, dark_logo: record<original_url: string, versions_urls: record>, enable_histogram: bool, ui_version: int, links: table<id: string, href_url: string, icon_url: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/component_groups")
  let body = {name: $name, component_group_id: $component_group_id, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a status page component group
#
# DELETE /v1/nunc_connections/{nunc_connection_id}/component_groups/{group_id}
# operationId: deleteStatusPageComponentGroup
export def "nunc-connections-component-groups delete" [
  nunc_connection_id: string
  group_id: string
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
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/component_groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a status page component group
#
# PATCH /v1/nunc_connections/{nunc_connection_id}/component_groups/{group_id}
# operationId: updateStatusPageComponentGroup
export def "nunc-connections-component-groups updateStatusPageComponentGroup" [
  nunc_connection_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --component-group-id: string
  --position: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/component_groups/($group_id)")
  let body = {name: $name, component_group_id: $component_group_id, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload an image for a status page
#
# PUT /v1/nunc_connections/{nunc_connection_id}/images/{type}
# operationId: updateStatusPageImage
export def "nunc-connections-images updateStatusPageImage" [
  nunc_connection_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> record<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record<nunc_condition: string, condition_name: string, condition_id: string>, components: record<infrastructure_type: string, infrastructure_id: string, label: string, position: int, component_group_id: string>, component_groups: record<id: string, component_group_id: string, name: string, position: int>, logo: record<original_url: string, versions_urls: record>, cover_image: record<original_url: string, versions_urls: record>, favicon: record<original_url: string, versions_urls: record>, open_graph_image: record<original_url: string, versions_urls: record>, dark_logo: record<original_url: string, versions_urls: record>, enable_histogram: bool, ui_version: int, links: table<id: string, href_url: string, icon_url: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/images/($type)")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete an image from a status page
#
# DELETE /v1/nunc_connections/{nunc_connection_id}/images/{type}
# operationId: deleteStatusPageImage
export def "nunc-connections-images delete" [
  nunc_connection_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record<nunc_condition: string, condition_name: string, condition_id: string>, components: record<infrastructure_type: string, infrastructure_id: string, label: string, position: int, component_group_id: string>, component_groups: record<id: string, component_group_id: string, name: string, position: int>, logo: record<original_url: string, versions_urls: record>, cover_image: record<original_url: string, versions_urls: record>, favicon: record<original_url: string, versions_urls: record>, open_graph_image: record<original_url: string, versions_urls: record>, dark_logo: record<original_url: string, versions_urls: record>, enable_histogram: bool, ui_version: int, links: table<id: string, href_url: string, icon_url: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/images/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a link for a status page
#
# POST /v1/nunc_connections/{nunc_connection_id}/links
# operationId: createStatusPageLink
export def "nunc-connections-links createStatusPageLink" [
  nunc_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, domain: string, company_name: string, company_website: string, cname: string, greeting_title: string, greeting_body: string, operational_message: string, company_tos_url: string, primary_color: string, secondary_color: string, button_background_color: string, button_text_color: string, link_color: string, title: string, exposed_fields: string, conditions: record<nunc_condition: string, condition_name: string, condition_id: string>, components: record<infrastructure_type: string, infrastructure_id: string, label: string, position: int, component_group_id: string>, component_groups: record<id: string, component_group_id: string, name: string, position: int>, logo: record<original_url: string, versions_urls: record>, cover_image: record<original_url: string, versions_urls: record>, favicon: record<original_url: string, versions_urls: record>, open_graph_image: record<original_url: string, versions_urls: record>, dark_logo: record<original_url: string, versions_urls: record>, enable_histogram: bool, ui_version: int, links: table<id: string, href_url: string, icon_url: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/links")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a status page link
#
# DELETE /v1/nunc_connections/{nunc_connection_id}/links/{link_id}
# operationId: deleteStatusPageLink
export def "nunc-connections-links delete" [
  nunc_connection_id: string
  link_id: string
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
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/links/($link_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a status page link
#
# PATCH /v1/nunc_connections/{nunc_connection_id}/links/{link_id}
# operationId: updateStatusPageLink
export def "nunc-connections-links updateStatusPageLink" [
  nunc_connection_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-text: string
  --icon-url: string
  --href-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/links/($link_id)")
  let body = {display_text: $display_text, icon_url: $icon_url, href_url: $href_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List status page subscribers
#
# GET /v1/nunc_connections/{nunc_connection_id}/subscribers
# operationId: listStatusPageSubscribers
export def "nunc-connections-subscribers listStatusPageSubscribers" [
  nunc_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, email: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/subscribers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add subscribers to a status page
#
# POST /v1/nunc_connections/{nunc_connection_id}/subscribers
# operationId: createStatusPageSubscribers
export def "nunc-connections-subscribers createStatusPageSubscribers" [
  nunc_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  emails: string # A comma-separated list of emails to subscribe.
]: any -> record<id: string, email: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/subscribers")
  let body = {emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove subscribers from a status page
#
# DELETE /v1/nunc_connections/{nunc_connection_id}/subscribers
# operationId: deleteStatusPageSubscribers
export def "nunc-connections-subscribers delete" [
  nunc_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscriber-ids: string # A list of subscriber IDs to unsubscribe.
]: nothing -> record<id: string, email: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscriber_ids" $subscriber_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/nunc_connections/($nunc_connection_id)/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check API connectivity
#
# GET /v1/ping
# operationId: apiPing
export def "ping apiPing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<response: string, actor: record<id: string, name: string, email: string, type: string>, organization: record<name: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List retrospective questions
#
# GET /v1/post_mortems/questions
# operationId: listRetrospectiveQuestions
export def "post-mortems-questions listRetrospectiveQuestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, title: string, tooltip: string, kind: string, is_required: bool, available_options: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/post_mortems/questions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update retrospective questions
#
# PUT /v1/post_mortems/questions
# operationId: updateRetrospectiveQuestions
# --questions item shape: {id?: string, title?: string, tooltip?: string}
export def "post-mortems-questions updateRetrospectiveQuestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --make-swagger-work: string
  --questions: list # item shape: {id?: string, title?: string, tooltip?: string}
]: any -> record<id: string, title: string, tooltip: string, kind: string, is_required: bool, available_options: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/post_mortems/questions")
  let body = {_make_swagger_work_: $make_swagger_work, questions: $questions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a retrospective question
#
# GET /v1/post_mortems/questions/{question_id}
# operationId: getRetrospectiveQuestion
export def "post-mortems-questions get" [
  question_id: string
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
  let full_url = (build-url $base $"/v1/post_mortems/questions/($question_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List retrospective reports
#
# GET /v1/post_mortems/reports
# operationId: listRetrospectiveReports
export def "post-mortems-reports listRetrospectiveReports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --incident-id: string # Filter the reports by an incident ID
  --updated-since: string # Filter for reports updated after the given ISO8601 timestamp (format: date-time)
]: nothing -> record<data: table<id: string, name: string, summary: string, incident_id: string, created_at: string, updated_at: string, tag_list: list, additional_details: list, incident: record, questions: record, calendar_events: record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "incident_id" $incident_id "scalar") (serialize-qp "updated_since" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/post_mortems/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a retrospective report
#
# POST /v1/post_mortems/reports
# operationId: createRetrospectiveReport
export def "post-mortems-reports createRetrospectiveReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  incident_id: string
]: any -> record<id: string, name: string, summary: string, incident_id: string, created_at: string, updated_at: string, tag_list: list<string>, additional_details: list<string>, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: list<record>, lifecycle_phases: list<record>, lifecycle_measurements: list<record>, active: bool, labels: record, role_assignments: list<record>, status_pages: list<record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list, conversations: list>, report_id: string, ai_incident_summary: string, services: list<record>, environments: list<record>, functionalities: list<record>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list<record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, impacts: list<record>, conference_bridges: list<record>, incident_channels: list<record>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: list<record>, conversations: list<record>, custom_fields: list<record>, field_requirements: list<record>>, questions: record<id: string, title: string, body: string, tooltip: string, kind: string, question_type_id: string, is_required: bool, available_options: list<string>, conversations: list<record>>, calendar_events: record<id: string, summary: string, description: string, starts_at: string, ends_at: string, created_at: string, updated_at: string, provider_url: string, provider_icon_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/post_mortems/reports")
  let body = {incident_id: $incident_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a retrospective report
#
# GET /v1/post_mortems/reports/{report_id}
# operationId: getPostMortemReport
export def "post-mortems-reports get" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, summary: string, incident_id: string, created_at: string, updated_at: string, tag_list: list<string>, additional_details: list<string>, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: list<record>, lifecycle_phases: list<record>, lifecycle_measurements: list<record>, active: bool, labels: record, role_assignments: list<record>, status_pages: list<record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list, conversations: list>, report_id: string, ai_incident_summary: string, services: list<record>, environments: list<record>, functionalities: list<record>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list<record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, impacts: list<record>, conference_bridges: list<record>, incident_channels: list<record>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: list<record>, conversations: list<record>, custom_fields: list<record>, field_requirements: list<record>>, questions: record<id: string, title: string, body: string, tooltip: string, kind: string, question_type_id: string, is_required: bool, available_options: list<string>, conversations: list<record>>, calendar_events: record<id: string, summary: string, description: string, starts_at: string, ends_at: string, created_at: string, updated_at: string, provider_url: string, provider_icon_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a retrospective report
#
# PATCH /v1/post_mortems/reports/{report_id}
# operationId: updatePostMortemReport
# --questions item shape: {id?: string, body?: string}
export def "post-mortems-reports updatePostMortemReport" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --summary: string
  --additional-details: string
  --questions: list # item shape: {id?: string, body?: string}
]: any -> record<id: string, name: string, summary: string, incident_id: string, created_at: string, updated_at: string, tag_list: list<string>, additional_details: list<string>, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: list<record>, lifecycle_phases: list<record>, lifecycle_measurements: list<record>, active: bool, labels: record, role_assignments: list<record>, status_pages: list<record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list, conversations: list>, report_id: string, ai_incident_summary: string, services: list<record>, environments: list<record>, functionalities: list<record>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list<record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, impacts: list<record>, conference_bridges: list<record>, incident_channels: list<record>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: list<record>, conversations: list<record>, custom_fields: list<record>, field_requirements: list<record>>, questions: record<id: string, title: string, body: string, tooltip: string, kind: string, question_type_id: string, is_required: bool, available_options: list<string>, conversations: list<record>>, calendar_events: record<id: string, summary: string, description: string, starts_at: string, ends_at: string, created_at: string, updated_at: string, provider_url: string, provider_icon_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)")
  let body = {name: $name, summary: $summary, additional_details: $additional_details, questions: $questions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a retrospective field
#
# PATCH /v1/post_mortems/reports/{report_id}/fields/{field_id}
# operationId: updateRetrospectiveField
export def "post-mortems-reports-fields updateRetrospectiveField" [
  field_id: string
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  value: string
]: any -> record<id: string, name: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)/fields/($field_id)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Publish a retrospective report
#
# POST /v1/post_mortems/reports/{report_id}/publish
# operationId: publishRetrospectiveReport
export def "post-mortems-reports-publish publishRetrospectiveReport" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-ids: list # An array of user IDs with whom to share the report
  --team-ids: list # An array of team IDs with whom to share the report
]: any -> record<id: string, name: string, summary: string, incident_id: string, created_at: string, updated_at: string, tag_list: list<string>, additional_details: list<string>, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: list<record>, lifecycle_phases: list<record>, lifecycle_measurements: list<record>, active: bool, labels: record, role_assignments: list<record>, status_pages: list<record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list, conversations: list>, report_id: string, ai_incident_summary: string, services: list<record>, environments: list<record>, functionalities: list<record>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list<record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, impacts: list<record>, conference_bridges: list<record>, incident_channels: list<record>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: list<record>, conversations: list<record>, custom_fields: list<record>, field_requirements: list<record>>, questions: record<id: string, title: string, body: string, tooltip: string, kind: string, question_type_id: string, is_required: bool, available_options: list<string>, conversations: list<record>>, calendar_events: record<id: string, summary: string, description: string, starts_at: string, ends_at: string, created_at: string, updated_at: string, provider_url: string, provider_icon_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)/publish")
  let body = {user_ids: $user_ids, team_ids: $team_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List contributing factors for a retrospective report
#
# GET /v1/post_mortems/reports/{report_id}/reasons
# operationId: listRetrospectiveReportReasons
export def "post-mortems-reports-reasons listRetrospectiveReportReasons" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, summary: string, position: int, created_by: record, conversations: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)/reasons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a contributing factor for a retrospective report
#
# POST /v1/post_mortems/reports/{report_id}/reasons
# operationId: createRetrospectiveReportReason
export def "post-mortems-reports-reasons createRetrospectiveReportReason" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  summary: string
]: any -> record<id: string, summary: string, position: int, created_by: record<id: string, name: string, source: string, email: string>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)/reasons")
  let body = {summary: $summary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the order of contributing factors in a retrospective report
#
# PUT /v1/post_mortems/reports/{report_id}/reasons/order
# operationId: updateRetrospectiveReportReasonOrder
export def "post-mortems-reports-reasons-order updateRetrospectiveReportReasonOrder" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  old_position: int # format: int32
  new_position: int # format: int32
]: any -> record<id: string, summary: string, position: int, created_by: record<id: string, name: string, source: string, email: string>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)/reasons/order")
  let body = {old_position: $old_position, new_position: $new_position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a contributing factor from a retrospective report
#
# DELETE /v1/post_mortems/reports/{report_id}/reasons/{reason_id}
# operationId: deleteRetrospectiveReason
export def "post-mortems-reports-reasons delete" [
  report_id: string
  reason_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, summary: string, position: int, created_by: record<id: string, name: string, source: string, email: string>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)/reasons/($reason_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a contributing factor in a retrospective report
#
# PATCH /v1/post_mortems/reports/{report_id}/reasons/{reason_id}
# operationId: updateRetrospectiveReason
export def "post-mortems-reports-reasons updateRetrospectiveReason" [
  report_id: string
  reason_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summary: string
]: any -> record<id: string, summary: string, position: int, created_by: record<id: string, name: string, source: string, email: string>, conversations: table<id: string, resource_class: string, resource_id: string, field: string, comments_url: string, channel: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/post_mortems/reports/($report_id)/reasons/($reason_id)")
  let body = {summary: $summary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List priorities
#
# GET /v1/priorities
# operationId: listPriorities
export def "priorities listPriorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<slug: string, description: string, position: int, created_at: string, updated_at: string, default: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/priorities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a priority
#
# POST /v1/priorities
# operationId: createPriority
export def "priorities createPriority" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  slug: string
  --description: string
  --default: oneof<nothing, bool>
]: any -> record<slug: string, description: string, position: int, created_at: string, updated_at: string, default: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/priorities")
  let body = {slug: $slug, description: $description, default: $default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a priority
#
# GET /v1/priorities/{priority_slug}
# operationId: getPriority
export def "priorities get" [
  priority_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<slug: string, description: string, position: int, created_at: string, updated_at: string, default: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/priorities/($priority_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a priority
#
# DELETE /v1/priorities/{priority_slug}
# operationId: deletePriority
export def "priorities delete" [
  priority_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<slug: string, description: string, position: int, created_at: string, updated_at: string, default: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/priorities/($priority_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a priority
#
# PATCH /v1/priorities/{priority_slug}
# operationId: updatePriority
export def "priorities updatePriority" [
  priority_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --slug: string
  --description: string
  --default: oneof<nothing, bool>
]: any -> record<slug: string, description: string, position: int, created_at: string, updated_at: string, default: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/priorities/($priority_slug)")
  let body = {slug: $slug, description: $description, default: $default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List alert processing log entries
#
# GET /v1/processing_log_entries
# operationId: listAlertProcessingLogs
export def "processing-log-entries listAlertProcessingLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --integration-slug: string # Scopes returned log entries to a specific integration ID
  --connection-id: string # Scopes returned log entries to a specific connection ID
  --of-level: string@of-level-completer # Returns logs of all levels equal to or above the provided level
  --exact-level: string@exact-level-completer # Returns log entries of all levels equal to the provided level
]: nothing -> record<data: table<id: string, context: record, created_at: string, level: string, message: string, message_type: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "integration_slug" $integration_slug "scalar") (serialize-qp "connection_id" $connection_id "scalar") (serialize-qp "of_level" $of_level "scalar") (serialize-qp "exact_level" $exact_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/processing_log_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mean time metrics for incidents
#
# GET /v1/reports/mean_time
# operationId: getMeanTimeReport
export def "reports-mean-time get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environments: string # A comma separated list of environment IDs
  --teams: string # A comma separated list of team IDs
  --services: string # A comma separated list of service IDs
  --status: string # Incident status
  --start-date: string # The start date to return incidents from (format: date)
  --end-date: string # The end date to return incidents from (format: date)
  --qp-query: string # A text query for an incident that searches on name, summary, and desciption
  --saved-search-id: string # The id of a previously saved search.
  --priorities: string # A comma separated list of priorities
  --priority-not-set: oneof<nothing, bool> # Flag for including incidents where priority has not been set
  --severities: string # A comma separated list of severities
  --severity-not-set: oneof<nothing, bool> # Flag for including incidents where severity has not been set
  --current-milestones: string # A comma separated list of current milestones
]: nothing -> record<data: table<bucket: string, points: list>, start_date: string, end_date: string, bucket_period: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environments" $environments "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "saved_search_id" $saved_search_id "scalar") (serialize-qp "priorities" $priorities "scalar") (serialize-qp "priority_not_set" $priority_not_set "scalar") (serialize-qp "severities" $severities "scalar") (serialize-qp "severity_not_set" $severity_not_set "scalar") (serialize-qp "current_milestones" $current_milestones "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reports/mean_time" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List runbook audits
#
# GET /v1/runbook_audits
# operationId: listRunbookAudits
export def "runbook-audits listRunbookAudits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --auditable-type: string@auditable-type-completer # A query to filter audits by type (default: Runbooks::Step)
  --qp-sort: string # A query to sort audits by their created_at timestamp. Options are 'asc' or 'desc'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "auditable_type" $auditable_type "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/runbook_audits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List runbooks
#
# GET /v1/runbooks
# operationId: listRunbooks
export def "runbooks listRunbooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --name: string # A query to search runbooks by their name
  --owners: string # A query to search runbooks by their owners
  --qp-sort: string@sort-completer # Sort runbooks by their updated date. Accepts 'asc', 'desc'
]: nothing -> record<id: string, name: string, summary: string, description: string, type: string, runbook_template_id: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, updated_by: record<id: string, name: string, source: string, email: string>, steps: record<name: string, action_id: string, step_id: string, config: record, action_elements: list<record>, step_elements: list<record>, automatic: bool, delay_duration: string, action: record<id: string, name: string, slug: string, description: string, config: record, category: string, prerequisites: record, integration: record, supported_runbook_types: list, created_at: string, updated_at: string, automatable: bool, rerunnable: bool, repeatable: bool, default_logic: record, default_rule_data: record>, reruns: bool, repeats: bool, repeats_duration: string, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, rule: record<logic: record, user_data: record>>, attachment_rule: record<logic: record, user_data: record<type: string, value: string, label: string>>, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, is_editable: bool, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, categories: string, auto_attach_to_restricted_incidents: bool, tutorial: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "owners" $owners "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/runbooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a runbook
#
# POST /v1/runbooks
# operationId: createRunbook
# --owner shape: {id: string}
# --attachment_rule shape: {logic: string, user_data?: string}
# --steps item shape: {name: string, action_id: string, rule?: record}
export def "runbooks createRunbook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  type: string@type-completer-2 # Deprecated, but still required. Please just use 'incident'
  --summary: string # Deprecated. Use description
  --description: string # A longer description about the Runbook. Supports markdown format
  --auto-attach-to-restricted-incidents: oneof<nothing, bool> # Whether or not this runbook should be automatically attached to restricted incidents. Note that setting this to `true` will prevent it from being attached to public incidents, even manually. Defaults to `false`.
  --tutorial: oneof<nothing, bool> # Whether or not this runbook is a tutorial runbook
  --owner: record # An object representing a Team that owns the runbook — shape: {id: string}
  --attachment-rule: record # shape: {logic: string, user_data?: string}
  --steps: list # item shape: {name: string, action_id: string, rule?: record}
]: any -> record<id: string, name: string, summary: string, description: string, type: string, runbook_template_id: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, updated_by: record<id: string, name: string, source: string, email: string>, steps: record<name: string, action_id: string, step_id: string, config: record, action_elements: list<record>, step_elements: list<record>, automatic: bool, delay_duration: string, action: record<id: string, name: string, slug: string, description: string, config: record, category: string, prerequisites: record, integration: record, supported_runbook_types: list, created_at: string, updated_at: string, automatable: bool, rerunnable: bool, repeatable: bool, default_logic: record, default_rule_data: record>, reruns: bool, repeats: bool, repeats_duration: string, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, rule: record<logic: record, user_data: record>>, attachment_rule: record<logic: record, user_data: record<type: string, value: string, label: string>>, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, is_editable: bool, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, categories: string, auto_attach_to_restricted_incidents: bool, tutorial: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/runbooks")
  let body = {name: $name, type: $type, summary: $summary, description: $description, auto_attach_to_restricted_incidents: $auto_attach_to_restricted_incidents, tutorial: $tutorial, owner: $owner, attachment_rule: $attachment_rule, steps: $steps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List runbook actions
#
# GET /v1/runbooks/actions
# operationId: listRunbookActions
export def "runbooks-actions listRunbookActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --type: string # List actions supporting this specific Runbook type
  --lite: oneof<nothing, bool> # Boolean to determine whether to return a slimified version of the action object's integration
]: nothing -> record<data: table<id: string, name: string, slug: string, description: string, config: record, category: string, prerequisites: record, integration: record, supported_runbook_types: list, created_at: string, updated_at: string, automatable: bool, rerunnable: bool, repeatable: bool, default_logic: record, default_rule_data: record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "lite" $lite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/runbooks/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List runbook executions
#
# GET /v1/runbooks/executions
# operationId: listRunbookExecutions
export def "runbooks-executions listRunbookExecutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, status: string, status_reason: string, status_reason_message: string, has_been_rerun: bool, created_at: string, updated_at: string, created_by: string, runbook: record, steps: record, executed_for: record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/runbooks/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a runbook execution
#
# POST /v1/runbooks/executions
# operationId: createRunbookExecution
export def "runbooks-executions createRunbookExecution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  execute_for: string # The incident to attach the runbook to. Format must be: `incident/${incidentId}`
  runbook_id: string # ID of runbook to attach
]: any -> record<id: string, status: string, status_reason: string, status_reason_message: string, has_been_rerun: bool, created_at: string, updated_at: string, created_by: string, runbook: record<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record<logic: record, user_data: record>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, categories: string>, steps: record<id: string, name: string, action_slug: string, action_type: string, integration_name: string, integration_slug: string, automatic: bool, config: record, step_elements: list<record>, executable: bool, repeats: bool, repeats_duration: string, repeats_at: string, has_been_rerun: bool, has_been_retried: bool, execution: record<state: string, data: record, performed_by: record, performed_at: string, scheduled_for: string, error: string, webhook_delivery: record>, repeatable: bool, rule: record<logic: record, user_data: record>>, executed_for: record<id: string, type: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/runbooks/executions")
  let body = {execute_for: $execute_for, runbook_id: $runbook_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a runbook execution
#
# GET /v1/runbooks/executions/{execution_id}
# operationId: getRunbookExecution
export def "runbooks-executions get" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, status_reason: string, status_reason_message: string, has_been_rerun: bool, created_at: string, updated_at: string, created_by: string, runbook: record<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record<logic: record, user_data: record>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, categories: string>, steps: record<id: string, name: string, action_slug: string, action_type: string, integration_name: string, integration_slug: string, automatic: bool, config: record, step_elements: list<record>, executable: bool, repeats: bool, repeats_duration: string, repeats_at: string, has_been_rerun: bool, has_been_retried: bool, execution: record<state: string, data: record, performed_by: record, performed_at: string, scheduled_for: string, error: string, webhook_delivery: record>, repeatable: bool, rule: record<logic: record, user_data: record>>, executed_for: record<id: string, type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Terminate a runbook execution
#
# DELETE /v1/runbooks/executions/{execution_id}
# operationId: deleteRunbookExecution
export def "runbooks-executions delete" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # The reason for terminating the runbook execution
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a runbook execution step
#
# PUT /v1/runbooks/executions/{execution_id}/steps/{step_id}
# operationId: updateRunbookExecutionStep
export def "runbooks-executions-steps updateRunbookExecutionStep" [
  execution_id: string
  step_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  state: string
  --schedule-for: string # format: date-time
  --data: record # Data for execution of this step
  --repeats-at: string # format: date-time
]: any -> record<id: string, status: string, status_reason: string, status_reason_message: string, has_been_rerun: bool, created_at: string, updated_at: string, created_by: string, runbook: record<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record<logic: record, user_data: record>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, categories: string>, steps: record<id: string, name: string, action_slug: string, action_type: string, integration_name: string, integration_slug: string, automatic: bool, config: record, step_elements: list<record>, executable: bool, repeats: bool, repeats_duration: string, repeats_at: string, has_been_rerun: bool, has_been_retried: bool, execution: record<state: string, data: record, performed_by: record, performed_at: string, scheduled_for: string, error: string, webhook_delivery: record>, repeatable: bool, rule: record<logic: record, user_data: record>>, executed_for: record<id: string, type: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)/steps/($step_id)")
  let body = {state: $state, schedule_for: $schedule_for, data: $data, repeats_at: $repeats_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a runbook execution step script
#
# GET /v1/runbooks/executions/{execution_id}/steps/{step_id}/script
# operationId: getRunbookExecutionStepScript
export def "runbooks-executions-steps-script get" [
  execution_id: string
  step_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, status_reason: string, status_reason_message: string, has_been_rerun: bool, created_at: string, updated_at: string, created_by: string, runbook: record<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record<logic: record, user_data: record>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, categories: string>, steps: record<id: string, name: string, action_slug: string, action_type: string, integration_name: string, integration_slug: string, automatic: bool, config: record, step_elements: list<record>, executable: bool, repeats: bool, repeats_duration: string, repeats_at: string, has_been_rerun: bool, has_been_retried: bool, execution: record<state: string, data: record, performed_by: record, performed_at: string, scheduled_for: string, error: string, webhook_delivery: record>, repeatable: bool, rule: record<logic: record, user_data: record>>, executed_for: record<id: string, type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)/steps/($step_id)/script")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the script state for a runbook execution step
#
# PUT /v1/runbooks/executions/{execution_id}/steps/{step_id}/script/{state}
# operationId: updateRunbookExecutionStepScriptState
export def "runbooks-executions-steps-script updateRunbookExecutionStepScriptState" [
  execution_id: string
  step_id: string
  state: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, status: string, status_reason: string, status_reason_message: string, has_been_rerun: bool, created_at: string, updated_at: string, created_by: string, runbook: record<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record<logic: record, user_data: record>, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, categories: string>, steps: record<id: string, name: string, action_slug: string, action_type: string, integration_name: string, integration_slug: string, automatic: bool, config: record, step_elements: list<record>, executable: bool, repeats: bool, repeats_duration: string, repeats_at: string, has_been_rerun: bool, has_been_retried: bool, execution: record<state: string, data: record, performed_by: record, performed_at: string, scheduled_for: string, error: string, webhook_delivery: record>, repeatable: bool, rule: record<logic: record, user_data: record>>, executed_for: record<id: string, type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)/steps/($step_id)/script/($state)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update votes for a runbook execution step
#
# PATCH /v1/runbooks/executions/{execution_id}/steps/{step_id}/votes
# operationId: updateRunbookExecutionStepVotes
export def "runbooks-executions-steps-votes updateRunbookExecutionStepVotes" [
  execution_id: string
  step_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  direction: string@direction-completer-1 # The direction you would like to vote, or if you dig it
]: any -> record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)/steps/($step_id)/votes")
  let body = {direction: $direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get vote counts for a runbook step
#
# GET /v1/runbooks/executions/{execution_id}/steps/{step_id}/votes/status
# operationId: getRunbookStepVoteStatus
export def "runbooks-executions-steps-votes-status get" [
  execution_id: string
  step_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)/steps/($step_id)/votes/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Vote on a runbook execution
#
# PATCH /v1/runbooks/executions/{execution_id}/votes
# operationId: updateRunbookExecutionVotes
export def "runbooks-executions-votes updateRunbookExecutionVotes" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  direction: string@direction-completer-1 # The direction you would like to vote, or if you dig it
]: any -> record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)/votes")
  let body = {direction: $direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get vote counts for a runbook execution
#
# GET /v1/runbooks/executions/{execution_id}/votes/status
# operationId: getRunbookExecutionVoteStatus
export def "runbooks-executions-votes-status get" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/executions/($execution_id)/votes/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List select options for a runbook integration action field
#
# GET /v1/runbooks/select_options/{integration_slug}/{action_slug}/{field}
# operationId: getRunbookSelectOptions
export def "runbooks-select-options get" [
  integration_slug: string
  action_slug: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Text string of a query for filtering values.
  --scope: string # Generic params used to add specificity (eg an id of some kind) to the select options request
  --per-page: int # Maximum number of items to return. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/runbooks/select_options/($integration_slug)/($action_slug)/($field)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a runbook
#
# GET /v1/runbooks/{runbook_id}
# operationId: getRunbook
export def "runbooks get" [
  runbook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, summary: string, description: string, type: string, runbook_template_id: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, updated_by: record<id: string, name: string, source: string, email: string>, steps: record<name: string, action_id: string, step_id: string, config: record, action_elements: list<record>, step_elements: list<record>, automatic: bool, delay_duration: string, action: record<id: string, name: string, slug: string, description: string, config: record, category: string, prerequisites: record, integration: record, supported_runbook_types: list, created_at: string, updated_at: string, automatable: bool, rerunnable: bool, repeatable: bool, default_logic: record, default_rule_data: record>, reruns: bool, repeats: bool, repeats_duration: string, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, rule: record<logic: record, user_data: record>>, attachment_rule: record<logic: record, user_data: record<type: string, value: string, label: string>>, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, is_editable: bool, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, categories: string, auto_attach_to_restricted_incidents: bool, tutorial: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/($runbook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a runbook
#
# PUT /v1/runbooks/{runbook_id}
# operationId: updateRunbook
# --owner shape: {id?: string}
# --severities item shape: {id?: string}
# --services item shape: {id?: string}
# --environments item shape: {id?: string}
# --attachment_rule shape: {logic: string, user_data?: string}
# --steps item shape: {step_id?: string, name: string, action_id: string, rule?: record}
export def "runbooks updateRunbook" [
  runbook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --summary: string
  --description: string
  --tutorial: oneof<nothing, bool> # Whether or not this runbook is a tutorial runbook
  --owner: record # An object representing a Team that owns the runbook — shape: {id?: string}
  --severities: list # item shape: {id?: string}
  --services: list # item shape: {id?: string}
  --environments: list # item shape: {id?: string}
  --attachment-rule: record # shape: {logic: string, user_data?: string}
  --steps: list # item shape: {step_id?: string, name: string, action_id: string, rule?: record}
  --auto-attach-to-restricted-incidents: oneof<nothing, bool> # Whether or not this runbook should be automatically attached to restricted incidents. Note that setting this to `true` will prevent it from being attached to public incidents, even manually. Defaults to `false`.
]: any -> record<id: string, name: string, summary: string, description: string, type: string, runbook_template_id: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, updated_by: record<id: string, name: string, source: string, email: string>, steps: record<name: string, action_id: string, step_id: string, config: record, action_elements: list<record>, step_elements: list<record>, automatic: bool, delay_duration: string, action: record<id: string, name: string, slug: string, description: string, config: record, category: string, prerequisites: record, integration: record, supported_runbook_types: list, created_at: string, updated_at: string, automatable: bool, rerunnable: bool, repeatable: bool, default_logic: record, default_rule_data: record>, reruns: bool, repeats: bool, repeats_duration: string, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, rule: record<logic: record, user_data: record>>, attachment_rule: record<logic: record, user_data: record<type: string, value: string, label: string>>, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, is_editable: bool, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, categories: string, auto_attach_to_restricted_incidents: bool, tutorial: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/($runbook_id)")
  let body = {name: $name, summary: $summary, description: $description, tutorial: $tutorial, owner: $owner, severities: $severities, services: $services, environments: $environments, attachment_rule: $attachment_rule, steps: $steps, auto_attach_to_restricted_incidents: $auto_attach_to_restricted_incidents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a runbook
#
# DELETE /v1/runbooks/{runbook_id}
# operationId: deleteRunbook
export def "runbooks delete" [
  runbook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, summary: string, description: string, type: string, runbook_template_id: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, updated_by: record<id: string, name: string, source: string, email: string>, steps: record<name: string, action_id: string, step_id: string, config: record, action_elements: list<record>, step_elements: list<record>, automatic: bool, delay_duration: string, action: record<id: string, name: string, slug: string, description: string, config: record, category: string, prerequisites: record, integration: record, supported_runbook_types: list, created_at: string, updated_at: string, automatable: bool, rerunnable: bool, repeatable: bool, default_logic: record, default_rule_data: record>, reruns: bool, repeats: bool, repeats_duration: string, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, rule: record<logic: record, user_data: record>>, attachment_rule: record<logic: record, user_data: record<type: string, value: string, label: string>>, votes: record<voted: bool, liked: bool, disliked: bool, likes: int, dislikes: int>, is_editable: bool, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, categories: string, auto_attach_to_restricted_incidents: bool, tutorial: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runbooks/($runbook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List saved searches
#
# GET /v1/saved_searches/{resource_type}
# operationId: listSavedSearches
export def "saved-searches listSavedSearches" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The user ID used to filter saved searches.
  --qp-query: string # Filter saved searches with a query on their name
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<id: string, name: string, resource_type: string, user_id: string, is_private: bool, created_at: string, updated_at: string, filter_values: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/saved_searches/($resource_type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a saved search
#
# POST /v1/saved_searches/{resource_type}
# operationId: createSavedSearch
export def "saved-searches createSavedSearch" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --is-private: oneof<nothing, bool>
  filter_values: record
]: any -> record<id: string, name: string, resource_type: string, user_id: string, is_private: bool, created_at: string, updated_at: string, filter_values: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved_searches/($resource_type)")
  let body = {name: $name, is_private: $is_private, filter_values: $filter_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a saved search
#
# GET /v1/saved_searches/{resource_type}/{saved_search_id}
# operationId: getSavedSearch
export def "saved-searches get" [
  resource_type: string
  saved_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, resource_type: string, user_id: string, is_private: bool, created_at: string, updated_at: string, filter_values: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved_searches/($resource_type)/($saved_search_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a saved search
#
# DELETE /v1/saved_searches/{resource_type}/{saved_search_id}
# operationId: deleteSavedSearch
export def "saved-searches delete" [
  resource_type: string
  saved_search_id: string
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
  let full_url = (build-url $base $"/v1/saved_searches/($resource_type)/($saved_search_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a saved search
#
# PATCH /v1/saved_searches/{resource_type}/{saved_search_id}
# operationId: updateSavedSearch
export def "saved-searches updateSavedSearch" [
  resource_type: string
  saved_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-private: oneof<nothing, bool>
  --name: string
  --filter-values: record
]: any -> record<id: string, name: string, resource_type: string, user_id: string, is_private: bool, created_at: string, updated_at: string, filter_values: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/saved_searches/($resource_type)/($saved_search_id)")
  let body = {is_private: $is_private, name: $name, filter_values: $filter_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List scheduled maintenance events
#
# GET /v1/scheduled_maintenances
# operationId: listScheduledMaintenances
export def "scheduled-maintenances listScheduledMaintenances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Filter scheduled_maintenances with a query on their name
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: list<record>, lifecycle_phases: list<record>, lifecycle_measurements: list<record>, active: bool, labels: record, role_assignments: list<record>, status_pages: list<record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list, conversations: list>, report_id: string, ai_incident_summary: string, services: list<record>, environments: list<record>, functionalities: list<record>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list<record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, impacts: list<record>, conference_bridges: list<record>, incident_channels: list<record>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: list<record>, conversations: list<record>, custom_fields: list<record>, field_requirements: list<record>>, status_pages: table<id: string, integration_id: string, integration_slug: string, integration_name: string>, impacts: table<id: string, type: string, impact: record, condition: record>, labels: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/scheduled_maintenances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a scheduled maintenance event
#
# POST /v1/scheduled_maintenances
# operationId: createScheduledMaintenance
# --status_pages item shape: {integration_slug?: string, connection_id: string}
# --impacts item shape: {type: string, id: string, condition_id: string}
export def "scheduled-maintenances createScheduledMaintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  starts_at: string # ISO8601 timestamp for the start time of the scheduled maintenance (format: date-time)
  ends_at: string # ISO8601 timestamp for the end time of the scheduled maintenance (format: date-time)
  --summary: string
  --description: string
  --labels: record # A json object of label keys and values
  --status-pages: list # An array of status pages to display this maintenance on — item shape: {integration_slug?: string, connection_id: string}
  --impacts: list # An array of impact/condition combinations — item shape: {type: string, id: string, condition_id: string}
]: any -> record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: list<record>, lifecycle_phases: list<record>, lifecycle_measurements: list<record>, active: bool, labels: record, role_assignments: list<record>, status_pages: list<record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list, conversations: list>, report_id: string, ai_incident_summary: string, services: list<record>, environments: list<record>, functionalities: list<record>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list<record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, impacts: list<record>, conference_bridges: list<record>, incident_channels: list<record>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: list<record>, conversations: list<record>, custom_fields: list<record>, field_requirements: list<record>>, status_pages: table<id: string, integration_id: string, integration_slug: string, integration_name: string>, impacts: table<id: string, type: string, impact: record, condition: record>, labels: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scheduled_maintenances")
  let body = {name: $name, starts_at: $starts_at, ends_at: $ends_at, summary: $summary, description: $description, labels: $labels, status_pages: $status_pages, impacts: $impacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a scheduled maintenance event
#
# GET /v1/scheduled_maintenances/{scheduled_maintenance_id}
# operationId: getScheduledMaintenance
export def "scheduled-maintenances get" [
  scheduled_maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: list<record>, lifecycle_phases: list<record>, lifecycle_measurements: list<record>, active: bool, labels: record, role_assignments: list<record>, status_pages: list<record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list, conversations: list>, report_id: string, ai_incident_summary: string, services: list<record>, environments: list<record>, functionalities: list<record>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list<record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, impacts: list<record>, conference_bridges: list<record>, incident_channels: list<record>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: list<record>, conversations: list<record>, custom_fields: list<record>, field_requirements: list<record>>, status_pages: table<id: string, integration_id: string, integration_slug: string, integration_name: string>, impacts: table<id: string, type: string, impact: record, condition: record>, labels: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scheduled_maintenances/($scheduled_maintenance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a scheduled maintenance event
#
# DELETE /v1/scheduled_maintenances/{scheduled_maintenance_id}
# operationId: deleteScheduledMaintenance
export def "scheduled-maintenances delete" [
  scheduled_maintenance_id: string
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
  let full_url = (build-url $base $"/v1/scheduled_maintenances/($scheduled_maintenance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a scheduled maintenance event
#
# PATCH /v1/scheduled_maintenances/{scheduled_maintenance_id}
# operationId: updateScheduledMaintenance
# --status_pages item shape: {integration_slug?: string, connection_id: string}
# --impacts item shape: {type: string, id: string, condition_id: string}
export def "scheduled-maintenances updateScheduledMaintenance" [
  scheduled_maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --summary: string
  --starts-at: string # ISO8601 timestamp for the start time of the scheduled maintenance (format: date-time)
  --ends-at: string # ISO8601 timestamp for the end time of the scheduled maintenance (format: date-time)
  --description: string
  --labels: record # A json object of label keys and values
  --status-pages: list # An array of status pages to display this maintenance on — item shape: {integration_slug?: string, connection_id: string}
  --impacts: list # An array of impact/condition combinations — item shape: {type: string, id: string, condition_id: string}
]: any -> record<id: string, name: string, summary: string, description: string, created_at: string, updated_at: string, starts_at: string, ends_at: string, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list<string>, severity_impact_object: record<id: string, name: string, type: string, affects_id: string, position: int>, severity_condition_object: record<id: string, name: string, position: int>, private_id: string, organization_id: string, milestones: list<record>, lifecycle_phases: list<record>, lifecycle_measurements: list<record>, active: bool, labels: record, role_assignments: list<record>, status_pages: list<record>, incident_url: string, private_status_page_url: string, organization: record<name: string, id: string>, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record<id: string, body: string, created_at: string, status_pages: list, conversations: list>, report_id: string, ai_incident_summary: string, services: list<record>, environments: list<record>, functionalities: list<record>, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list<record>, ticket: record<id: string, summary: string, description: string, state: string, type: string, assignees: list, priority: record, created_by: record, attachments: list, created_at: string, updated_at: string, tag_list: list, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record>, impacts: list<record>, conference_bridges: list<record>, incident_channels: list<record>, retro_exports: list<record>, created_by: record<id: string, name: string, source: string, email: string>, context_object: record<object_type: string, object_id: string, context_tag: string, context_description: string>, team_assignments: list<record>, conversations: list<record>, custom_fields: list<record>, field_requirements: list<record>>, status_pages: table<id: string, integration_id: string, integration_slug: string, integration_name: string>, impacts: table<id: string, type: string, impact: record, condition: record>, labels: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scheduled_maintenances/($scheduled_maintenance_id)")
  let body = {name: $name, summary: $summary, starts_at: $starts_at, ends_at: $ends_at, description: $description, labels: $labels, status_pages: $status_pages, impacts: $impacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List schedules
#
# GET /v1/schedules
# operationId: listSchedules
export def "schedules listSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Filter schedules with a query on their name
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<id: string, name: string, integration: string, discarded: bool>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List teams via SCIM
#
# GET /v1/scim/v2/Groups
# operationId: getScimGroups
export def "scim-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startIndex: int # format: int32
  --count: int # format: int32
  --filter: string # This is a string used to query groups by displayName.         Proper example syntax for this would be `?filter=displayName eq "My Team Name"`.         Currently we only support the `eq` operator
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/scim/v2/Groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a team via SCIM
#
# POST /v1/scim/v2/Groups
# operationId: createScimGroup
export def "scim-groups createScimGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scim/v2/Groups")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Get a SCIM group
#
# GET /v1/scim/v2/Groups/{id}
# operationId: getScimGroup
export def "scim-groups get" [
  id: string
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
  let full_url = (build-url $base $"/v1/scim/v2/Groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a SCIM group
#
# PUT /v1/scim/v2/Groups/{id}
# operationId: updateScimGroup
export def "scim-groups updateScimGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Groups/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Delete a SCIM group
#
# DELETE /v1/scim/v2/Groups/{id}
# operationId: deleteScimGroup
export def "scim-groups delete" [
  id: string
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
  let full_url = (build-url $base $"/v1/scim/v2/Groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List users via SCIM
#
# GET /v1/scim/v2/Users
# operationId: getScimUsers
export def "scim-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # This is a string used to query users by either userName or email.         Proper example syntax for this would be `?filter=userName eq john` or `?filter=userName eq "john@firehydrant.com"`.         Currently we only support the `eq` operator
  --startIndex: int # This is an integer which represents a pagination offset (format: int32)
  --count: int # This is an integer which represents the number of items per page in the response (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/scim/v2/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a user via SCIM
#
# POST /v1/scim/v2/Users
# operationId: createScimUser
export def "scim-users createScimUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/scim/v2/Users")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Get a SCIM user
#
# GET /v1/scim/v2/Users/{id}
# operationId: getScimUser
export def "scim-users get" [
  id: string
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
  let full_url = (build-url $base $"/v1/scim/v2/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace a SCIM user
#
# PUT /v1/scim/v2/Users/{id}
# operationId: replaceScimUser
export def "scim-users replaceScimUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Users/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Delete a SCIM user
#
# DELETE /v1/scim/v2/Users/{id}
# operationId: deleteScimUser
export def "scim-users delete" [
  id: string
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
  let full_url = (build-url $base $"/v1/scim/v2/Users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a SCIM user
#
# PATCH /v1/scim/v2/Users/{id}
# operationId: updateScimUser
export def "scim-users updateScimUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/scim/v2/Users/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/scim+json" $body
}

# Create a dependency relationship between services
#
# POST /v1/service_dependencies
# operationId: createServiceDependency
export def "service-dependencies createServiceDependency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  service_id: string
  connected_service_id: string
  --notes: string # A note to describe the service dependency relationship
]: any -> record<id: string, notes: string, created_at: string, updated_at: string, service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: list<record>, completed_checks: int, external_resources: list<record>, functionalities: list<record>, last_import: record<import_errors: list, imported_at: string, remote_id: string, state: string>, links: list<record>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, service_checklist_updated_at: string, teams: list<record>, updated_by: record<id: string, name: string, source: string, email: string>>, connected_service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: list<record>, completed_checks: int, external_resources: list<record>, functionalities: list<record>, last_import: record<import_errors: list, imported_at: string, remote_id: string, state: string>, links: list<record>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, service_checklist_updated_at: string, teams: list<record>, updated_by: record<id: string, name: string, source: string, email: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/service_dependencies")
  let body = {service_id: $service_id, connected_service_id: $connected_service_id, notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a service dependency
#
# GET /v1/service_dependencies/{service_dependency_id}
# operationId: getServiceDependency
export def "service-dependencies get" [
  service_dependency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, notes: string, created_at: string, updated_at: string, service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: list<record>, completed_checks: int, external_resources: list<record>, functionalities: list<record>, last_import: record<import_errors: list, imported_at: string, remote_id: string, state: string>, links: list<record>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, service_checklist_updated_at: string, teams: list<record>, updated_by: record<id: string, name: string, source: string, email: string>>, connected_service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: list<record>, completed_checks: int, external_resources: list<record>, functionalities: list<record>, last_import: record<import_errors: list, imported_at: string, remote_id: string, state: string>, links: list<record>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, service_checklist_updated_at: string, teams: list<record>, updated_by: record<id: string, name: string, source: string, email: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/service_dependencies/($service_dependency_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service dependency
#
# DELETE /v1/service_dependencies/{service_dependency_id}
# operationId: deleteServiceDependency
export def "service-dependencies delete" [
  service_dependency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, notes: string, created_at: string, updated_at: string, service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: list<record>, completed_checks: int, external_resources: list<record>, functionalities: list<record>, last_import: record<import_errors: list, imported_at: string, remote_id: string, state: string>, links: list<record>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, service_checklist_updated_at: string, teams: list<record>, updated_by: record<id: string, name: string, source: string, email: string>>, connected_service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: list<record>, completed_checks: int, external_resources: list<record>, functionalities: list<record>, last_import: record<import_errors: list, imported_at: string, remote_id: string, state: string>, links: list<record>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, service_checklist_updated_at: string, teams: list<record>, updated_by: record<id: string, name: string, source: string, email: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/service_dependencies/($service_dependency_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service dependency
#
# PATCH /v1/service_dependencies/{service_dependency_id}
# operationId: updateServiceDependency
export def "service-dependencies updateServiceDependency" [
  service_dependency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # A note to describe the service dependency relationship
]: any -> record<id: string, notes: string, created_at: string, updated_at: string, service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: list<record>, completed_checks: int, external_resources: list<record>, functionalities: list<record>, last_import: record<import_errors: list, imported_at: string, remote_id: string, state: string>, links: list<record>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, service_checklist_updated_at: string, teams: list<record>, updated_by: record<id: string, name: string, source: string, email: string>>, connected_service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: list<record>, completed_checks: int, external_resources: list<record>, functionalities: list<record>, last_import: record<import_errors: list, imported_at: string, remote_id: string, state: string>, links: list<record>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, service_checklist_updated_at: string, teams: list<record>, updated_by: record<id: string, name: string, source: string, email: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/service_dependencies/($service_dependency_id)")
  let body = {notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List services
#
# GET /v1/services
# operationId: listServices
export def "services listServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --labels: string # A comma separated list of label key / values in the format of 'key=value,key2=value2'. To filter change events that have a key (with no specific value), omit the value
  --qp-query: string # A query to search services by their name or description
  --name: string # A query to search services by their name
  --tiers: string # A query to search services by their tier
  --impacted: string # A query to search services by if they are impacted with active incidents
  --owner: string # A query to search services by their owner
  --responding-teams: string # A comma separated list of team ids
  --functionalities: string # A comma separated list of functionality ids
  --available-downstream-dependencies-for-id: string # A query to find services that are available to be downstream dependencies for the passed service ID
  --available-upstream-dependencies-for-id: string # A query to find services that are available to be upstream dependencies for the passed service ID
  --lite: oneof<nothing, bool> # Boolean to determine whether to return a slimified version of the services object
  --include: list # Use in conjunction with lite param to specify additional attributes to include
]: nothing -> record<data: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list, checklists: list, completed_checks: int, external_resources: list, functionalities: list, last_import: record, links: list, managed_by: string, managed_by_settings: record, owner: record, service_checklist_updated_at: string, teams: list, updated_by: record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "tiers" $tiers "scalar") (serialize-qp "impacted" $impacted "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "responding_teams" $responding_teams "scalar") (serialize-qp "functionalities" $functionalities "scalar") (serialize-qp "available_downstream_dependencies_for_id" $available_downstream_dependencies_for_id "scalar") (serialize-qp "available_upstream_dependencies_for_id" $available_upstream_dependencies_for_id "scalar") (serialize-qp "lite" $lite "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a service
#
# POST /v1/services
# operationId: createService
# --functionalities item shape: {summary?: string, id?: string}
# --links item shape: {name: string, href_url: string, icon_url?: string}
# --owner shape: {id: string}
# --teams item shape: {id: string}
# --external_resources item shape: {remote_id: string, connection_type?: string}
export def "services createService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --labels: record # A hash of label keys and values
  --service-tier: int@service-tier-completer # Integer representing service tier. Lower values represent higher criticality. If not specified the default value will be 5. (format: int32)
  --functionalities: list # An array of functionalities — item shape: {summary?: string, id?: string}
  --links: list # An array of links to associate with this service — item shape: {name: string, href_url: string, icon_url?: string}
  --owner: record # An object representing a Team that owns the service — shape: {id: string}
  --teams: list # An array of teams to attach to this service. — item shape: {id: string}
  --alert-on-add: oneof<nothing, bool>
  --auto-add-responding-team: oneof<nothing, bool>
  --external-resources: list # An array of external resources to attach to this service. — item shape: {remote_id: string, connection_type?: string}
]: any -> record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, completed_checks: int, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>, functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record, services: list, external_resources: list, teams: list>, last_import: record<import_errors: list<record>, imported_at: string, remote_id: string, state: string>, links: table<id: string, href_url: string, icon_url: string, name: string>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, service_checklist_updated_at: string, teams: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, updated_by: record<id: string, name: string, source: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/services")
  let body = {name: $name, description: $description, labels: $labels, service_tier: $service_tier, functionalities: $functionalities, links: $links, owner: $owner, teams: $teams, alert_on_add: $alert_on_add, auto_add_responding_team: $auto_add_responding_team, external_resources: $external_resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create multiple services and link them to external services
#
# POST /v1/services/service_links
# operationId: createServiceLinks
export def "services-service-links createServiceLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  external_service_ids: string # ID of the service
  connection_id: string # ID for the integration. This can be found by going to the edit page for the integration
  integration: string@integration-completer # The name of the service
]: any -> table<status_code: int, service: record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list, checklists: list, completed_checks: int, external_resources: list, functionalities: list, last_import: record, links: list, managed_by: string, managed_by_settings: record, owner: record, service_checklist_updated_at: string, teams: list, updated_by: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/services/service_links")
  let body = {external_service_ids: $external_service_ids, connection_id: $connection_id, integration: $integration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a service
#
# GET /v1/services/{service_id}
# operationId: getService
export def "services get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, completed_checks: int, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>, functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record, services: list, external_resources: list, teams: list>, last_import: record<import_errors: list<record>, imported_at: string, remote_id: string, state: string>, links: table<id: string, href_url: string, icon_url: string, name: string>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, service_checklist_updated_at: string, teams: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, updated_by: record<id: string, name: string, source: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/services/($service_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service
#
# DELETE /v1/services/{service_id}
# operationId: deleteService
export def "services delete" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, completed_checks: int, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>, functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record, services: list, external_resources: list, teams: list>, last_import: record<import_errors: list<record>, imported_at: string, remote_id: string, state: string>, links: table<id: string, href_url: string, icon_url: string, name: string>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, service_checklist_updated_at: string, teams: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, updated_by: record<id: string, name: string, source: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/services/($service_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service
#
# PATCH /v1/services/{service_id}
# operationId: updateService
# --checklists item shape: {id: string, remove?: bool}
# --external_resources item shape: {remote_id: string, connection_type?: string, remove?: bool}
# --functionalities item shape: {id?: string, remove?: bool, summary?: string}
# --links item shape: {href_url: string, name: string, icon_url?: string, remove?: bool, id?: string}
# --owner shape: {id: string}
# --teams item shape: {id: string, remove?: bool}
export def "services updateService" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alert-on-add: oneof<nothing, bool>
  --auto-add-responding-team: oneof<nothing, bool>
  --checklists: list # Array of checklist IDs to attach to the service — item shape: {id: string, remove?: bool}
  --description: string
  --external-resources: list # An array of external resources to attach to this service. — item shape: {remote_id: string, connection_type?: string, remove?: bool}
  --functionalities: list # An array of functionalities — item shape: {id?: string, remove?: bool, summary?: string}
  --labels: record # A hash of label keys and values
  --links: list # An array of links to associate with this service. This will remove all links not present in the patch. Only acts if 'links' key is included in the payload. — item shape: {href_url: string, name: string, icon_url?: string, remove?: bool, id?: string}
  --name: string
  --owner: record # An object representing a Team that owns the service — shape: {id: string}
  --remove-owner: oneof<nothing, bool> # If you are trying to remove a team as an owner from a service, set this to 'true'
  --remove-remaining-checklists: oneof<nothing, bool> # If set to true, any checklists tagged on the service that are not included in the given array will be removed. Set this to true if you want to do a replacement operation for the checklists
  --remove-remaining-external-resources: oneof<nothing, bool> # If set to true, any external_resources tagged on the service that are not included in the given array will be removed. Set this to true if you want to do a replacement operation for the external_resources
  --remove-remaining-functionalities: oneof<nothing, bool> # If set to true, any functionalities tagged on the service that are not included in the given array will be removed. Set this to true if you want to do a replacement operation for the functionalities
  --remove-remaining-teams: oneof<nothing, bool> # If set to true, any teams tagged on the service that are not included in the given array will be removed. Set this to true if you want to do a replacement operation for the teams
  --service-tier: int@service-tier-completer # Integer representing service tier (format: int32)
  --teams: list # An array of teams to attach to this service. — item shape: {id: string, remove?: bool}
]: any -> record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool, active_incidents: list<string>, checklists: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, completed_checks: int, external_resources: table<connection_type: string, connection_name: string, connection_id: string, remote_id: string, remote_url: string, created_at: string, updated_at: string, name: string>, functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record, services: list, external_resources: list, teams: list>, last_import: record<import_errors: list<record>, imported_at: string, remote_id: string, state: string>, links: table<id: string, href_url: string, icon_url: string, name: string>, managed_by: string, managed_by_settings: record, owner: record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool>, service_checklist_updated_at: string, teams: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool>, updated_by: record<id: string, name: string, source: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/services/($service_id)")
  let body = {alert_on_add: $alert_on_add, auto_add_responding_team: $auto_add_responding_team, checklists: $checklists, description: $description, external_resources: $external_resources, functionalities: $functionalities, labels: $labels, links: $links, name: $name, owner: $owner, remove_owner: $remove_owner, remove_remaining_checklists: $remove_remaining_checklists, remove_remaining_external_resources: $remove_remaining_external_resources, remove_remaining_functionalities: $remove_remaining_functionalities, remove_remaining_teams: $remove_remaining_teams, service_tier: $service_tier, teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List available downstream service dependencies
#
# GET /v1/services/{service_id}/available_downstream_dependencies
# operationId: listServiceAvailableDownstreamDependencies
export def "services-available-downstream-dependencies listServiceAvailableDownstreamDependencies" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/services/($service_id)/available_downstream_dependencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available upstream service dependencies
#
# GET /v1/services/{service_id}/available_upstream_dependencies
# operationId: listServiceAvailableUpstreamDependencies
export def "services-available-upstream-dependencies listServiceAvailableUpstreamDependencies" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list<string>, labels: record, alert_on_add: bool, auto_add_responding_team: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/services/($service_id)/available_upstream_dependencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a checklist response for a service
#
# POST /v1/services/{service_id}/checklist_response/{checklist_id}
# operationId: createServiceChecklistResponse
export def "services-checklist-response createServiceChecklistResponse" [
  service_id: string
  checklist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  check_id: string
  --status: oneof<nothing, bool> # Status of the check. 'true' if it's complete, 'false' if incomplete, or blank if not yet interacted with
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/services/($service_id)/checklist_response/($checklist_id)")
  let body = {check_id: $check_id, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List dependencies for a service
#
# GET /v1/services/{service_id}/dependencies
# operationId: getServiceDependencies
export def "services-dependencies get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # If true, returns all dependencies in one array. If false, splits dependencies into different arrays for child and parent dependencies
]: nothing -> record<child_service_dependencies: table<id: string, notes: string, created_at: string, updated_at: string, service: record, type: string>, parent_service_dependencies: table<id: string, notes: string, created_at: string, updated_at: string, service: record, type: string>, service_dependencies: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/services/($service_id)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service link
#
# DELETE /v1/services/{service_id}/service_links/{remote_id}
# operationId: deleteServiceLink
export def "services-service-links delete" [
  service_id: string
  remote_id: string
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
  let full_url = (build-url $base $"/v1/services/($service_id)/service_links/($remote_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List severities
#
# GET /v1/severities
# operationId: listSeverities
export def "severities listSeverities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<data: table<slug: string, description: string, type: string, position: int, created_at: string, updated_at: string, system_record: bool, color: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/severities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a severity
#
# POST /v1/severities
# operationId: createSeverity
export def "severities createSeverity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  slug: string
  --description: string
  --position: int # format: int32
  --color: string@color-completer
]: any -> record<slug: string, description: string, type: string, position: int, created_at: string, updated_at: string, system_record: bool, color: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/severities")
  let body = {slug: $slug, description: $description, position: $position, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a severity
#
# GET /v1/severities/{severity_slug}
# operationId: getSeverity
export def "severities get" [
  severity_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<slug: string, description: string, type: string, position: int, created_at: string, updated_at: string, system_record: bool, color: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severities/($severity_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a severity
#
# DELETE /v1/severities/{severity_slug}
# operationId: deleteSeverity
export def "severities delete" [
  severity_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<slug: string, description: string, type: string, position: int, created_at: string, updated_at: string, system_record: bool, color: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severities/($severity_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a severity
#
# PATCH /v1/severities/{severity_slug}
# operationId: updateSeverity
export def "severities updateSeverity" [
  severity_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --slug: string
  --description: string
  --position: int # format: int32
  --color: string@color-completer
]: any -> record<slug: string, description: string, type: string, position: int, created_at: string, updated_at: string, system_record: bool, color: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severities/($severity_slug)")
  let body = {slug: $slug, description: $description, position: $position, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get severity matrix
#
# GET /v1/severity_matrix
# operationId: getSeverityMatrix
export def "severity-matrix get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<matrix: table<severity: string, condition_id: string, impact_id: string, impact_type: string>, impacts: table<id: string, name: string, type: string, affects_id: string, position: int>, conditions: table<id: string, name: string, position: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/severity_matrix")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update severity matrix
#
# PATCH /v1/severity_matrix
# operationId: updateSeverityMatrix
# --data item shape: {severity: string, impact_id: string, condition_id: string}
export def "severity-matrix updateSeverityMatrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summary: string
  data: list # item shape: {severity: string, impact_id: string, condition_id: string}
]: any -> record<matrix: table<severity: string, condition_id: string, impact_id: string, impact_type: string>, impacts: table<id: string, name: string, type: string, affects_id: string, position: int>, conditions: table<id: string, name: string, position: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/severity_matrix")
  let body = {summary: $summary, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List severity matrix conditions
#
# GET /v1/severity_matrix/conditions
# operationId: listSeverityMatrixConditions
export def "severity-matrix-conditions listSeverityMatrixConditions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<id: string, name: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/severity_matrix/conditions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a severity matrix condition
#
# POST /v1/severity_matrix/conditions
# operationId: createSeverityMatrixCondition
export def "severity-matrix-conditions createSeverityMatrixCondition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --position: int # Position is used to determine ordering of conditions in API responses and dropdowns. The condition with the lowest position (typically 0) will be considered the Default Condition (format: int32)
]: any -> record<id: string, name: string, position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/severity_matrix/conditions")
  let body = {name: $name, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a severity matrix condition
#
# GET /v1/severity_matrix/conditions/{condition_id}
# operationId: getSeverityMatrixCondition
export def "severity-matrix-conditions get" [
  condition_id: string
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
  let full_url = (build-url $base $"/v1/severity_matrix/conditions/($condition_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a severity matrix condition
#
# DELETE /v1/severity_matrix/conditions/{condition_id}
# operationId: deleteSeverityMatrixCondition
export def "severity-matrix-conditions delete" [
  condition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severity_matrix/conditions/($condition_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a severity matrix condition
#
# PATCH /v1/severity_matrix/conditions/{condition_id}
# operationId: updateSeverityMatrixCondition
export def "severity-matrix-conditions updateSeverityMatrixCondition" [
  condition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --position: int # Position is used to determine ordering of conditions in API responses and dropdowns. The condition with the lowest position (typically 0) will be considered the Default Condition (format: int32)
]: any -> record<id: string, name: string, position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severity_matrix/conditions/($condition_id)")
  let body = {name: $name, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List severity matrix impacts
#
# GET /v1/severity_matrix/impacts
# operationId: listSeverityMatrixImpacts
export def "severity-matrix-impacts listSeverityMatrixImpacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<id: string, name: string, type: string, affects_id: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/severity_matrix/impacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a severity matrix impact
#
# POST /v1/severity_matrix/impacts
# operationId: createSeverityMatrixImpact
export def "severity-matrix-impacts createSeverityMatrixImpact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  affects_type: string
  affects_id: string
  --position: int # format: int32
]: any -> record<id: string, name: string, type: string, affects_id: string, position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/severity_matrix/impacts")
  let body = {affects_type: $affects_type, affects_id: $affects_id, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an impact from the severity matrix
#
# DELETE /v1/severity_matrix/impacts/{impact_id}
# operationId: deleteSeverityMatrixImpact
export def "severity-matrix-impacts delete" [
  impact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, type: string, affects_id: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severity_matrix/impacts/($impact_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an impact in the severity matrix
#
# PATCH /v1/severity_matrix/impacts/{impact_id}
# operationId: updateSeverityMatrixImpact
export def "severity-matrix-impacts updateSeverityMatrixImpact" [
  impact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --position: int # format: int32
]: any -> record<id: string, name: string, type: string, affects_id: string, position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/severity_matrix/impacts/($impact_id)")
  let body = {name: $name, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List grouped signal alert metrics
#
# GET /v1/signals/analytics/grouped_metrics
# operationId: getSignalGroupedMetrics
export def "signals-analytics-grouped-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --signal-rules: string # A comma separated list of signal rule IDs
  --teams: string # A comma separated list of team IDs
  --environments: string # A comma separated list of environment IDs
  --services: string # A comma separated list of service IDs
  --tags: string # A comma separated list of tags
  --users: string # A comma separated list of user IDs
  --group-by: string@group-by-completer # String that determines how records are grouped
  --sort-by: string@sort-by-completer-1 # String that determines how records are sorted
  --sort-direction: string@sort-direction-completer # String that determines how records are sorted
  --start-date: string # The start date to return metrics from (format: date-time)
  --end-date: string # The end date to return metrics from (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal_rules" $signal_rules "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/signals/analytics/grouped_metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get MTTX analytics for signals
#
# GET /v1/signals/analytics/mttx
# operationId: getSignalsMttxAnalytics
export def "signals-analytics-mttx get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --signal-rules: string # A comma separated list of signal rule IDs
  --teams: string # A comma separated list of team IDs
  --environments: string # A comma separated list of environment IDs
  --services: string # A comma separated list of service IDs
  --tags: string # A comma separated list of tags
  --users: string # A comma separated list of user IDs
  --group-by: string@group-by-completer # String that determines how records are grouped
  --sort-by: string@sort-by-completer-1 # String that determines how records are sorted
  --sort-direction: string@sort-direction-completer # String that determines how records are sorted
  --start-date: string # The start date to return metrics from (format: date-time)
  --end-date: string # The end date to return metrics from (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal_rules" $signal_rules "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/signals/analytics/mttx" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List timeseries metrics for signal alerts
#
# GET /v1/signals/analytics/timeseries
# operationId: getSignalsAnalyticsTimeseries
export def "signals-analytics-timeseries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bucket: string@bucket-completer # String that determines how records are grouped
  --signal-rules: string # A comma separated list of signal rule IDs
  --teams: string # A comma separated list of team IDs
  --environments: string # A comma separated list of environment IDs
  --services: string # A comma separated list of service IDs
  --tags: string # A comma separated list of tags
  --users: string # A comma separated list of user IDs
  --group-by: string@group-by-completer # String that determines how records are grouped
  --sort-by: string@sort-by-completer-1 # String that determines how records are sorted
  --sort-direction: string@sort-direction-completer # String that determines how records are sorted
  --start-date: string # The start date to return metrics from (format: date-time)
  --end-date: string # The end date to return metrics from (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucket" $bucket "scalar") (serialize-qp "signal_rules" $signal_rules "scalar") (serialize-qp "teams" $teams "scalar") (serialize-qp "environments" $environments "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "users" $users "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/signals/analytics/timeseries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Debug a signal
#
# POST /v1/signals/debugger
# operationId: debugSignal
# --signals item shape: {summary?: string, body?: string, level?: string, images?: list, links?: list}
export def "signals-debugger debugSignal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  expression: string # CEL expression
  signals: list # List of signals to evaluate rule expression against — item shape: {summary?: string, body?: string, level?: string, images?: list, links?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/signals/debugger")
  let body = {expression: $expression, signals: $signals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List email targets for signals
#
# GET /v1/signals/email_targets
# operationId: listSignalEmailTargets
export def "signals-email-targets listSignalEmailTargets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query string to search the list of targets by.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/signals/email_targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an email target for signals
#
# POST /v1/signals/email_targets
# operationId: createSignalEmailTarget
# --target shape: {type: "Team"|"EntireTeam"|"EscalationPolicy"|"OnCallSchedule"|"User"|"SlackChannel"|"Webhook", id: string}
export def "signals-email-targets createSignalEmailTarget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The email target's name.
  --slug: string # The email address that will be listening to events.
  --description: string # A detailed description of the email target.
  --target: record # The target that the email target will notify. This object must contain a `type` field that specifies the type of target and an `id` field that specifies the ID of the target. The `type` field must be one of "escalation_policy", "on_call_schedule", "team", "user", or "slack_channel". — shape: {type: "Team"|"EntireTeam"|"EscalationPolicy"|"OnCallSchedule"|"User"|"SlackChannel"|"Webhook", id: string}
  --allowed-senders: list # A list of email addresses that are allowed to send events to the target. Must be exact match.
  --rules: list # A list of CEL expressions that should be evaluated and matched to determine if the target should be notified.
  --rule-matching-strategy: string@rule-matching-strategy-completer # Whether or not all rules must match, or if only one rule must match.
  --status-cel: string # The CEL expression that defines the status of an incoming email that is sent to the target.
  --level-cel: string # The CEL expression that defines the level of an incoming email that is sent to the target.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/signals/email_targets")
  let body = {name: $name, slug: $slug, description: $description, target: $target, allowed_senders: $allowed_senders, rules: $rules, rule_matching_strategy: $rule_matching_strategy, status_cel: $status_cel, level_cel: $level_cel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a signal email target
#
# GET /v1/signals/email_targets/{id}
# operationId: getSignalEmailTarget
export def "signals-email-targets get" [
  id: string
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
  let full_url = (build-url $base $"/v1/signals/email_targets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a signal email target
#
# DELETE /v1/signals/email_targets/{id}
# operationId: deleteSignalEmailTarget
export def "signals-email-targets delete" [
  id: string
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
  let full_url = (build-url $base $"/v1/signals/email_targets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a signal email target
#
# PATCH /v1/signals/email_targets/{id}
# operationId: updateSignalEmailTarget
# --target shape: {type: "Team"|"EntireTeam"|"EscalationPolicy"|"OnCallSchedule"|"User"|"SlackChannel"|"Webhook", id: string}
export def "signals-email-targets updateSignalEmailTarget" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The email target's name.
  --slug: string # The email address that will be listening to events.
  --description: string # A detailed description of the email target.
  --target: record # The target that the email target will notify. This object must contain a `type` field that specifies the type of target and an `id` field that specifies the ID of the target. The `type` field must be one of "escalation_policy", "on_call_schedule", "team", "user", or "slack_channel". — shape: {type: "Team"|"EntireTeam"|"EscalationPolicy"|"OnCallSchedule"|"User"|"SlackChannel"|"Webhook", id: string}
  --allowed-senders: list # A list of email addresses that are allowed to send events to the target. Must be exact match.
  --status-cel: string # The CEL expression that defines the status of an incoming email that is sent to the target.
  --level-cel: string # The CEL expression that defines the level of an incoming email that is sent to the target.
  --rules: list # A list of CEL expressions that should be evaluated and matched to determine if the target should be notified.
  --rule-matching-strategy: string@rule-matching-strategy-completer # Whether or not all rules must match, or if only one rule must match.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/signals/email_targets/($id)")
  let body = {name: $name, slug: $slug, description: $description, target: $target, allowed_senders: $allowed_senders, status_cel: $status_cel, level_cel: $level_cel, rules: $rules, rule_matching_strategy: $rule_matching_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List event sources for signals
#
# GET /v1/signals/event_sources
# operationId: listSignalEventSources
export def "signals-event-sources listSignalEventSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # Team ID to send signals to directly
  --escalation-policy-id: string # Escalation policy ID to send signals to directly. `team_id` is required if this is provided.
  --on-call-schedule-id: string # On-call schedule ID to send signals to directly. `team_id` is required if this is provided.
  --user-id: string # User ID to send signals to directly
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "escalation_policy_id" $escalation_policy_id "scalar") (serialize-qp "on_call_schedule_id" $on_call_schedule_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/signals/event_sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get signal ingestion URL
#
# GET /v1/signals/ingest_url
# operationId: getSignalIngestUrl
export def "signals-ingest-url get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # Team ID to send signals to directly
  --escalation-policy-id: string # Escalation policy ID to send signals to directly. `team_id` is required if this is provided.
  --on-call-schedule-id: string # On-call schedule ID to send signals to directly. `team_id` is required if this is provided.
  --user-id: string # User ID to send signals to directly
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar") (serialize-qp "escalation_policy_id" $escalation_policy_id "scalar") (serialize-qp "on_call_schedule_id" $on_call_schedule_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/signals/ingest_url" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List signal transposers
#
# GET /v1/signals/transposers
# operationId: listSignalTransposers
export def "signals-transposers listSignalTransposers" [
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
  let full_url = (build-url $base "/v1/signals/transposers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List webhook targets for signals
#
# GET /v1/signals/webhook_targets
# operationId: listSignalWebhookTargets
export def "signals-webhook-targets listSignalWebhookTargets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query string for searching through the list of webhook targets.
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/signals/webhook_targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a webhook target for signals
#
# POST /v1/signals/webhook_targets
# operationId: createSignalWebhookTarget
export def "signals-webhook-targets createSignalWebhookTarget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The webhook target's name.
  --description: string # An optional detailed description of the webhook target.
  --body-url: string # The URL that the webhook target will notify.
  --signing-key: string # An optional secret we will provide in the `FH-Signature` header when sending a payload to the webhook target. This key will not be shown in any response once configured.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/signals/webhook_targets")
  let body = {name: $name, description: $description, url: $body_url, signing_key: $signing_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a webhook target
#
# GET /v1/signals/webhook_targets/{id}
# operationId: getSignalsWebhookTarget
export def "signals-webhook-targets get" [
  id: string
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
  let full_url = (build-url $base $"/v1/signals/webhook_targets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a webhook target
#
# DELETE /v1/signals/webhook_targets/{id}
# operationId: deleteSignalsWebhookTarget
export def "signals-webhook-targets delete" [
  id: string
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
  let full_url = (build-url $base $"/v1/signals/webhook_targets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook target
#
# PATCH /v1/signals/webhook_targets/{id}
# operationId: updateSignalsWebhookTarget
export def "signals-webhook-targets updateSignalsWebhookTarget" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The webhook target's name.
  --description: string # An optional detailed description of the webhook target.
  --body-url: string # The URL that the webhook target will notify.
  --signing-key: string # An optional secret we will provide in the `FH-Signature` header when sending a payload to the webhook target. This key will not be shown in any response once configured.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/signals/webhook_targets/($id)")
  let body = {name: $name, description: $description, url: $body_url, signing_key: $signing_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List on-call schedules
#
# GET /v1/signals_on_call
# operationId: listSignalsOnCall
export def "signals-on-call listSignalsOnCall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --team-id: string # An optional comma separated list of team IDs to filter currently on-call users by
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/signals_on_call" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List status update templates
#
# GET /v1/status_update_templates
# operationId: listStatusUpdateTemplates
export def "status-update-templates listStatusUpdateTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<id: string, name: string, body: string, created_at: string, updated_at: string, discarded_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/status_update_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a status update template
#
# POST /v1/status_update_templates
# operationId: createStatusUpdateTemplate
export def "status-update-templates createStatusUpdateTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --body-body: string
]: any -> record<id: string, name: string, body: string, created_at: string, updated_at: string, discarded_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/status_update_templates")
  let body = {name: $name, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a status update template
#
# GET /v1/status_update_templates/{status_update_template_id}
# operationId: getStatusUpdateTemplate
export def "status-update-templates get" [
  status_update_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, body: string, created_at: string, updated_at: string, discarded_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status_update_templates/($status_update_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a status update template
#
# DELETE /v1/status_update_templates/{status_update_template_id}
# operationId: deleteStatusUpdateTemplate
export def "status-update-templates delete" [
  status_update_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, body: string, created_at: string, updated_at: string, discarded_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status_update_templates/($status_update_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a status update template
#
# PATCH /v1/status_update_templates/{status_update_template_id}
# operationId: updateStatusUpdateTemplate
export def "status-update-templates updateStatusUpdateTemplate" [
  status_update_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --body-body: string
]: any -> record<id: string, name: string, body: string, created_at: string, updated_at: string, discarded_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status_update_templates/($status_update_template_id)")
  let body = {name: $name, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List task lists
#
# GET /v1/task_lists
# operationId: listTaskLists
export def "task-lists listTaskLists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<id: string, name: string, description: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, task_list_items: record<summary: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/task_lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task list
#
# POST /v1/task_lists
# operationId: createTaskList
# --task_list_items item shape: {summary: string, description?: string}
export def "task-lists createTaskList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  task_list_items: list # item shape: {summary: string, description?: string}
]: any -> record<id: string, name: string, description: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, task_list_items: record<summary: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/task_lists")
  let body = {name: $name, description: $description, task_list_items: $task_list_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a task list
#
# GET /v1/task_lists/{task_list_id}
# operationId: getTaskList
export def "task-lists get" [
  task_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, task_list_items: record<summary: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/task_lists/($task_list_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a task list
#
# DELETE /v1/task_lists/{task_list_id}
# operationId: deleteTaskList
export def "task-lists delete" [
  task_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, task_list_items: record<summary: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/task_lists/($task_list_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a task list
#
# PATCH /v1/task_lists/{task_list_id}
# operationId: updateTaskList
# --task_list_items item shape: {summary: string, description?: string}
export def "task-lists updateTaskList" [
  task_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --task-list-items: list # item shape: {summary: string, description?: string}
]: any -> record<id: string, name: string, description: string, created_at: string, updated_at: string, created_by: record<id: string, name: string, source: string, email: string>, task_list_items: record<summary: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/task_lists/($task_list_id)")
  let body = {name: $name, description: $description, task_list_items: $task_list_items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List teams
#
# GET /v1/teams
# operationId: listTeams
export def "teams listTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --qp-query: string # A query to search teams by their name or description
  --name: string # A query to search teams by their name
  --services: string # A comma separated list of service IDs
  --default-incident-role: string # Filter by teams that have or do not have members with a default incident role asssigned. Value may be 'present', 'blank', or the ID of an incident role.
  --lite: oneof<nothing, bool> # Boolean to determine whether to return a slimified version of the teams object
]: nothing -> record<data: table<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record, in_support_hours: bool, slack_channel: record, ms_teams_channel: record, memberships: list, owned_checklist_templates: list, owned_functionalities: list, owned_services: list, owned_runbooks: list, responding_services: list, services: list, functionalities: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "services" $services "scalar") (serialize-qp "default_incident_role" $default_incident_role "scalar") (serialize-qp "lite" $lite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /v1/teams
# operationId: createTeam
# --ms_teams_channel shape: {channel_id: string, ms_team_id: string}
# --memberships item shape: {user_id?: string, schedule_id?: string, incident_role_id?: string}
export def "teams createTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string
  --slug: string
  --slack-channel-id: string # The Slack channel ID that this team is associated with
  --ms-teams-channel: record # MS Teams channel identity for channel associated with this team — shape: {channel_id: string, ms_team_id: string}
  --memberships: list # item shape: {user_id?: string, schedule_id?: string, incident_role_id?: string}
]: any -> record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool, slack_channel: record<id: string, name: string, slack_channel_id: string>, ms_teams_channel: record<id: string, channel_id: string, channel_name: string, ms_team_id: string, team_name: string, channel_url: string, status: string, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list, severity_impact_object: record, severity_condition_object: record, private_id: string, organization_id: string, milestones: list, lifecycle_phases: list, lifecycle_measurements: list, active: bool, labels: record, role_assignments: list, status_pages: list, incident_url: string, private_status_page_url: string, organization: record, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record, report_id: string, ai_incident_summary: string, services: list, environments: list, functionalities: list, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list, ticket: record, impacts: list, conference_bridges: list, incident_channels: list, retro_exports: list, created_by: record, context_object: record, team_assignments: list, conversations: list, custom_fields: list, field_requirements: list>>, memberships: table<user: record, schedule: record, signals_on_call_schedule: record, default_incident_role: record>, owned_checklist_templates: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, owned_functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record>, owned_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, owned_runbooks: table<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record, owner: record, categories: string>, responding_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams")
  let body = {name: $name, description: $description, slug: $slug, slack_channel_id: $slack_channel_id, ms_teams_channel: $ms_teams_channel, memberships: $memberships} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a team
#
# GET /v1/teams/{team_id}
# operationId: getTeam
export def "teams get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lite: oneof<nothing, bool> # Boolean to determine whether to return a slimified version of the teams object
]: nothing -> record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool, slack_channel: record<id: string, name: string, slack_channel_id: string>, ms_teams_channel: record<id: string, channel_id: string, channel_name: string, ms_team_id: string, team_name: string, channel_url: string, status: string, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list, severity_impact_object: record, severity_condition_object: record, private_id: string, organization_id: string, milestones: list, lifecycle_phases: list, lifecycle_measurements: list, active: bool, labels: record, role_assignments: list, status_pages: list, incident_url: string, private_status_page_url: string, organization: record, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record, report_id: string, ai_incident_summary: string, services: list, environments: list, functionalities: list, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list, ticket: record, impacts: list, conference_bridges: list, incident_channels: list, retro_exports: list, created_by: record, context_object: record, team_assignments: list, conversations: list, custom_fields: list, field_requirements: list>>, memberships: table<user: record, schedule: record, signals_on_call_schedule: record, default_incident_role: record>, owned_checklist_templates: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, owned_functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record>, owned_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, owned_runbooks: table<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record, owner: record, categories: string>, responding_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lite" $lite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive a team
#
# DELETE /v1/teams/{team_id}
# operationId: archiveTeam
export def "teams archiveTeam" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool, slack_channel: record<id: string, name: string, slack_channel_id: string>, ms_teams_channel: record<id: string, channel_id: string, channel_name: string, ms_team_id: string, team_name: string, channel_url: string, status: string, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list, severity_impact_object: record, severity_condition_object: record, private_id: string, organization_id: string, milestones: list, lifecycle_phases: list, lifecycle_measurements: list, active: bool, labels: record, role_assignments: list, status_pages: list, incident_url: string, private_status_page_url: string, organization: record, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record, report_id: string, ai_incident_summary: string, services: list, environments: list, functionalities: list, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list, ticket: record, impacts: list, conference_bridges: list, incident_channels: list, retro_exports: list, created_by: record, context_object: record, team_assignments: list, conversations: list, custom_fields: list, field_requirements: list>>, memberships: table<user: record, schedule: record, signals_on_call_schedule: record, default_incident_role: record>, owned_checklist_templates: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, owned_functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record>, owned_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, owned_runbooks: table<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record, owner: record, categories: string>, responding_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a team
#
# PATCH /v1/teams/{team_id}
# operationId: updateTeam
# --ms_teams_channel shape: {channel_id: string, ms_team_id: string}
# --memberships item shape: {user_id?: string, schedule_id?: string, incident_role_id?: string}
export def "teams updateTeam" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --slug: string
  --slack-channel-id: string # The Slack channel ID that this team is associated with
  --ms-teams-channel: record # MS Teams channel identity for channel associated with this team — shape: {channel_id: string, ms_team_id: string}
  --memberships: list # item shape: {user_id?: string, schedule_id?: string, incident_role_id?: string}
]: any -> record<id: string, name: string, description: string, slug: string, created_at: string, updated_at: string, signals_ical_url: string, created_by: record<id: string, name: string, source: string, email: string>, in_support_hours: bool, slack_channel: record<id: string, name: string, slack_channel_id: string>, ms_teams_channel: record<id: string, channel_id: string, channel_name: string, ms_team_id: string, team_name: string, channel_url: string, status: string, incident: record<id: string, name: string, created_at: string, started_at: string, discarded_at: string, summary: string, customer_impact_summary: string, description: string, current_milestone: string, number: int, priority: string, severity: string, severity_color: string, severity_impact: string, severity_condition: string, tag_list: list, severity_impact_object: record, severity_condition_object: record, private_id: string, organization_id: string, milestones: list, lifecycle_phases: list, lifecycle_measurements: list, active: bool, labels: record, role_assignments: list, status_pages: list, incident_url: string, private_status_page_url: string, organization: record, customers_impacted: int, monetary_impact: int, monetary_impact_cents: int, last_update: string, last_note: record, report_id: string, ai_incident_summary: string, services: list, environments: list, functionalities: list, channel_name: string, channel_reference: string, channel_id: string, channel_status: string, incident_tickets: list, ticket: record, impacts: list, conference_bridges: list, incident_channels: list, retro_exports: list, created_by: record, context_object: record, team_assignments: list, conversations: list, custom_fields: list, field_requirements: list>>, memberships: table<user: record, schedule: record, signals_on_call_schedule: record, default_incident_role: record>, owned_checklist_templates: table<id: string, name: string, description: string, created_at: string, updated_at: string, checks: list, owner: record, connected_services: list>, owned_functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record>, owned_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, owned_runbooks: table<id: string, name: string, summary: string, description: string, type: string, created_at: string, updated_at: string, attachment_rule: record, owner: record, categories: string>, responding_services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, services: table<id: string, name: string, description: string, slug: string, service_tier: int, created_at: string, updated_at: string, allowed_params: list, labels: record, alert_on_add: bool, auto_add_responding_team: bool>, functionalities: table<id: string, name: string, slug: string, description: string, created_at: string, updated_at: string, labels: record, active_incidents: list, links: list, owner: record, alert_on_add: bool, auto_add_responding_team: bool, updated_by: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)")
  let body = {name: $name, description: $description, slug: $slug, slack_channel_id: $slack_channel_id, ms_teams_channel: $ms_teams_channel, memberships: $memberships} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List escalation policies for a team
#
# GET /v1/teams/{team_id}/escalation_policies
# operationId: listTeamEscalationPolicies
export def "teams-escalation-policies listTeamEscalationPolicies" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query string for searching through the list of escalation policies.
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/escalation_policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an escalation policy for a team
#
# POST /v1/teams/{team_id}/escalation_policies
# operationId: createTeamEscalationPolicy
# --steps item shape: {targets: list, timeout: string}
# --handoff_step shape: {target_type: "EscalationPolicy"|"Team", target_id: string}
export def "teams-escalation-policies createTeamEscalationPolicy" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The escalation policy's name.
  --description: string # A detailed description of the escalation policy.
  --repetitions: int # The number of times that the escalation policy should repeat before an alert is dropped. (format: int32, default: 0)
  --default: oneof<nothing, bool> # Whether this escalation policy should be the default for the team. (default: false)
  steps: list # A list of steps that define how an alert should escalate through the policy. — item shape: {targets: list, timeout: string}
  --handoff-step: record # A step that defines where an alert should be sent when the policy is exhausted and the alert is still unacknowledged. — shape: {target_type: "EscalationPolicy"|"Team", target_id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/escalation_policies")
  let body = {name: $name, description: $description, repetitions: $repetitions, default: $default, steps: $steps, handoff_step: $handoff_step} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an escalation policy for a team
#
# GET /v1/teams/{team_id}/escalation_policies/{id}
# operationId: getTeamEscalationPolicy
export def "teams-escalation-policies get" [
  team_id: string
  id: string
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
  let full_url = (build-url $base $"/v1/teams/($team_id)/escalation_policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an escalation policy for a team
#
# DELETE /v1/teams/{team_id}/escalation_policies/{id}
# operationId: deleteTeamEscalationPolicy
export def "teams-escalation-policies delete" [
  team_id: string
  id: string
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
  let full_url = (build-url $base $"/v1/teams/($team_id)/escalation_policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an escalation policy for a team
#
# PATCH /v1/teams/{team_id}/escalation_policies/{id}
# operationId: updateTeamEscalationPolicy
# --steps item shape: {targets?: list, timeout: string}
# --handoff_step shape: {target_type: "EscalationPolicy"|"Team", target_id: string}
export def "teams-escalation-policies updateTeamEscalationPolicy" [
  team_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The escalation policy's name.
  --description: string # A detailed description of the escalation policy.
  --repetitions: int # The number of times that the escalation policy should repeat before an alert is dropped. (format: int32, default: 0)
  --default: oneof<nothing, bool> # Whether this escalation policy should be the default for the team. (default: false)
  --steps: list # A list of steps that define how an alert should escalate through the policy. — item shape: {targets?: list, timeout: string}
  --handoff-step: record # A step that defines where an alert should be sent when the policy is exhausted and the alert is still unacknowledged. — shape: {target_type: "EscalationPolicy"|"Team", target_id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/escalation_policies/($id)")
  let body = {name: $name, description: $description, repetitions: $repetitions, default: $default, steps: $steps, handoff_step: $handoff_step} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List on-call schedules for a team
#
# GET /v1/teams/{team_id}/on_call_schedules
# operationId: listTeamOnCallSchedules
export def "teams-on-call-schedules listTeamOnCallSchedules" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query string for searching through the list of on-call schedules.
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an on-call schedule for a team
#
# POST /v1/teams/{team_id}/on_call_schedules
# operationId: createTeamOnCallSchedule
# --members item shape: {user_id?: string}
# --strategy shape: {type: "daily"|"weekly"|"custom", handoff_time?: string, handoff_day?: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", shift_duration?: string}
# --restrictions item shape: {start_day: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time: string, end_day: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", end_time: string}
export def "teams-on-call-schedules createTeamOnCallSchedule" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The on-call schedule's name.
  --description: string # A detailed description of the on-call schedule.
  time_zone: string # The time zone in which the on-call schedule operates. This value must be a valid IANA time zone name.
  --slack-user-group-id: string # The ID of a Slack user group for syncing purposes. If provided, we will automatically sync whoever is on call to the user group in Slack.
  --members: list # An ordered list of objects that specify members of the on-call schedule's rotation. — item shape: {user_id?: string}
  strategy: record # An object that specifies how the schedule's on-call shifts should be generated. — shape: {type: "daily"|"weekly"|"custom", handoff_time?: string, handoff_day?: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", shift_duration?: string}
  --restrictions: list # A list of objects that restrict the schedule to speccific on-call periods. — item shape: {start_day: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time: string, end_day: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", end_time: string}
  --start-time: string # An ISO8601 time string specifying when the schedule's first shift should start. This value is only used if the schedule's strategy is "custom".
  --color: string # A hex color code that will be used to represent the schedule in the UI and iCal subscriptions.
  --member-ids: list # This parameter is deprecated; use `members` instead.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules")
  let body = {name: $name, description: $description, time_zone: $time_zone, slack_user_group_id: $slack_user_group_id, members: $members, strategy: $strategy, restrictions: $restrictions, start_time: $start_time, color: $color, member_ids: $member_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an on-call schedule for a team
#
# GET /v1/teams/{team_id}/on_call_schedules/{schedule_id}
# operationId: getTeamOnCallSchedule
export def "teams-on-call-schedules get" [
  team_id: string
  schedule_id: string
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
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules/($schedule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an on-call schedule for a team
#
# DELETE /v1/teams/{team_id}/on_call_schedules/{schedule_id}
# operationId: deleteTeamOnCallSchedule
export def "teams-on-call-schedules delete" [
  team_id: string
  schedule_id: string
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
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules/($schedule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an on-call schedule for a team
#
# PATCH /v1/teams/{team_id}/on_call_schedules/{schedule_id}
# operationId: updateTeamOnCallSchedule
# --members item shape: {user_id?: string}
# --strategy shape: {type: "daily"|"weekly"|"custom", handoff_time?: string, handoff_day?: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", shift_duration?: string}
# --restrictions item shape: {start_day: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time: string, end_day: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", end_time: string}
export def "teams-on-call-schedules updateTeamOnCallSchedule" [
  team_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The on-call schedule's name.
  --description: string # A detailed description of the on-call schedule.
  --time-zone: string # The time zone in which the on-call schedule operates. This value must be a valid IANA time zone name.
  --slack-user-group-id: string # The ID of a Slack user group for syncing purposes. If provided, we will automatically sync whoever is on call to the user group in Slack.
  --members: list # An ordered list of objects that specify members of the on-call schedule's rotation. — item shape: {user_id?: string}
  --strategy: record # An object that specifies how the schedule's on-call shifts should be generated. — shape: {type: "daily"|"weekly"|"custom", handoff_time?: string, handoff_day?: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", shift_duration?: string}
  --restrictions: list # A list of objects that restrict the schedule to speccific on-call periods. — item shape: {start_day: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time: string, end_day: "monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", end_time: string}
  --effective-at: string # An ISO8601 time string specifying when the updated schedule should take effect. This value must be provided if editing an attribute that would affect how the schedule's shifts are generated, such as the time zone, members, strategy, or restrictions.
  --color: string # A hex color code that will be used to represent the schedule in the UI and iCal subscriptions.
  --member-ids: list # This parameter is deprecated; use `members` instead.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules/($schedule_id)")
  let body = {name: $name, description: $description, time_zone: $time_zone, slack_user_group_id: $slack_user_group_id, members: $members, strategy: $strategy, restrictions: $restrictions, effective_at: $effective_at, color: $color, member_ids: $member_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a shift for an on-call schedule
#
# POST /v1/teams/{team_id}/on_call_schedules/{schedule_id}/shifts
# operationId: createTeamOnCallScheduleShift
export def "teams-on-call-schedules-shifts createTeamOnCallScheduleShift" [
  team_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  start_time: string # The start time of the shift in ISO8601 format.
  end_time: string # The end time of the shift in ISO8601 format.
  --user-id: string # The ID of the user who is on-call for the shift. If not provided, the shift will be unassigned.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules/($schedule_id)/shifts")
  let body = {start_time: $start_time, end_time: $end_time, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an on-call shift for a team schedule
#
# GET /v1/teams/{team_id}/on_call_schedules/{schedule_id}/shifts/{id}
# operationId: getTeamScheduleShift
export def "teams-on-call-schedules-shifts get" [
  id: string
  team_id: string
  schedule_id: string
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
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules/($schedule_id)/shifts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an on-call shift from a team schedule
#
# DELETE /v1/teams/{team_id}/on_call_schedules/{schedule_id}/shifts/{id}
# operationId: deleteTeamScheduleShift
export def "teams-on-call-schedules-shifts delete" [
  id: string
  team_id: string
  schedule_id: string
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
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules/($schedule_id)/shifts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an on-call shift in a team schedule
#
# PATCH /v1/teams/{team_id}/on_call_schedules/{schedule_id}/shifts/{id}
# operationId: updateTeamScheduleShift
export def "teams-on-call-schedules-shifts updateTeamScheduleShift" [
  id: string
  team_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: string # The start time of the shift in ISO8601 format.
  --end-time: string # The end time of the shift in ISO8601 format.
  --user-id: string # The ID of the user who is on-call for the shift. If not provided, the shift will be unassigned.
  --coverage-request: string # A description of why coverage is needed for this shift. If the shift is re-assigned, this will automatically be cleared unless provided again.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/on_call_schedules/($schedule_id)/shifts/($id)")
  let body = {start_time: $start_time, end_time: $end_time, user_id: $user_id, coverage_request: $coverage_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List signal rules for a team
#
# GET /v1/teams/{team_id}/signal_rules
# operationId: listTeamSignalRules
export def "teams-signal-rules listTeamSignalRules" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query string for searching through the list of alerting rules.
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/teams/($team_id)/signal_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a signal rule for a team
#
# POST /v1/teams/{team_id}/signal_rules
# operationId: createTeamSignalRule
export def "teams-signal-rules createTeamSignalRule" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The rule's name.
  expression: string # The CEL expression that defines the rule.
  target_type: string@target-type-completer # The type of target that the rule will notify when matched.
  target_id: string # The ID of the target that the rule will notify when matched.
  --incident-type-id: string # The ID of an incident type that should be used when an alert is promoted to an incident
  --notification-priority-override: string@notification-priority-override-completer # A notification priority that will be set on the resulting alert (default: HIGH)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/signal_rules")
  let body = {name: $name, expression: $expression, target_type: $target_type, target_id: $target_id, incident_type_id: $incident_type_id, notification_priority_override: $notification_priority_override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a signal rule
#
# GET /v1/teams/{team_id}/signal_rules/{id}
# operationId: getTeamSignalRule
export def "teams-signal-rules get" [
  team_id: string
  id: string
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
  let full_url = (build-url $base $"/v1/teams/($team_id)/signal_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a signal rule
#
# DELETE /v1/teams/{team_id}/signal_rules/{id}
# operationId: deleteTeamSignalRule
export def "teams-signal-rules delete" [
  team_id: string
  id: string
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
  let full_url = (build-url $base $"/v1/teams/($team_id)/signal_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a signal rule
#
# PATCH /v1/teams/{team_id}/signal_rules/{id}
# operationId: updateTeamSignalRule
export def "teams-signal-rules updateTeamSignalRule" [
  team_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The rule's name.
  --expression: string # The CEL expression that defines the rule.
  --target-type: string@target-type-completer # The type of target that the rule will notify when matched.
  --target-id: string # The ID of the target that the rule will notify when matched.
  --incident-type-id: string # The ID of an incident type that should be used when an alert is promoted to an incident
  --notification-priority-override: string@notification-priority-override-completer # A notification priority that will be set on the resulting alert (default: HIGH)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/teams/($team_id)/signal_rules/($id)")
  let body = {name: $name, expression: $expression, target_type: $target_type, target_id: $target_id, incident_type_id: $incident_type_id, notification_priority_override: $notification_priority_override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List ticketing priorities
#
# GET /v1/ticketing/priorities
# operationId: listTicketingPriorities
export def "ticketing-priorities listTicketingPriorities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, position: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ticketing/priorities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ticketing priority
#
# POST /v1/ticketing/priorities
# operationId: createTicketingPriority
export def "ticketing-priorities createTicketingPriority" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --position: int # The position that this priority should take in your list of priorities. Priorities should be ordered from highest to lowest, with the highest priority at 0. If a position isn't specified, the new priority will be added to the end of the list; if another priority already exists at the specified position, that priority and all priorities following it will automatically be moved down the list to make room for the new priority. (format: int32)
]: any -> record<id: string, name: string, position: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ticketing/priorities")
  let body = {name: $name, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a ticketing priority
#
# GET /v1/ticketing/priorities/{id}
# operationId: getTicketingPriority
export def "ticketing-priorities get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, position: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/priorities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a ticketing priority
#
# DELETE /v1/ticketing/priorities/{id}
# operationId: deleteTicketingPriority
export def "ticketing-priorities delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, position: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/priorities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a ticketing priority
#
# PATCH /v1/ticketing/priorities/{id}
# operationId: updateTicketingPriority
export def "ticketing-priorities updateTicketingPriority" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --position: int # The position that this priority should take in your list of priorities. Priorities should be ordered from highest to lowest, with the highest priority at 0. If a position isn't specified, the new priority will be added to the end of the list; if another priority already exists at the specified position, this priority will shift that priority and all priorities down the list. (format: int32)
]: any -> record<id: string, name: string, position: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/priorities/($id)")
  let body = {name: $name, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List ticketing projects
#
# GET /v1/ticketing/projects
# operationId: listTicketingProjects
export def "ticketing-projects listTicketingProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --supports-ticket-types: string
  --providers: string
  --connection-ids: string
  --configured-projects: oneof<nothing, bool>
  --qp-query: string
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<id: string, name: string, config: record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, ticketing_project_name: string, details: record>, field_map: record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, body: list<record>>, updated_at: string, connection_slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "supports_ticket_types" $supports_ticket_types "scalar") (serialize-qp "providers" $providers "scalar") (serialize-qp "connection_ids" $connection_ids "scalar") (serialize-qp "configured_projects" $configured_projects "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ticketing/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ticketing project
#
# GET /v1/ticketing/projects/{ticketing_project_id}
# operationId: getTicketingProject
export def "ticketing-projects get" [
  ticketing_project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, config: record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, ticketing_project_name: string, details: record>, field_map: record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, body: list<record>>, updated_at: string, connection_slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List configuration options for a ticketing project
#
# GET /v1/ticketing/projects/{ticketing_project_id}/configuration_options
# operationId: getTicketingProjectConfigurationOptions
export def "ticketing-projects-configuration-options get" [
  ticketing_project_id: string
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
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/configuration_options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List configuration options for a ticketing project field
#
# GET /v1/ticketing/projects/{ticketing_project_id}/configuration_options/options_for/{field_id}
# operationId: getTicketingProjectFieldOptions
export def "ticketing-projects-configuration-options-options-for get" [
  field_id: string
  ticketing_project_id: string
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
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/configuration_options/options_for/($field_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a field mapping for a ticketing project
#
# POST /v1/ticketing/projects/{ticketing_project_id}/field_maps
# operationId: createTicketingProjectFieldMap
export def "ticketing-projects-field-maps createTicketingProjectFieldMap" [
  ticketing_project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, body: table<strategy: string, external_field: string, external_value: record, user_data: record, cases: list, else: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/field_maps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available fields for ticket field mapping
#
# GET /v1/ticketing/projects/{ticketing_project_id}/field_maps/available_fields
# operationId: getTicketingProjectAvailableFields
export def "ticketing-projects-field-maps-available-fields get" [
  ticketing_project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string, label: string, type: string, allowed_values: string, required: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/field_maps/available_fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a field map for a ticketing project
#
# GET /v1/ticketing/projects/{ticketing_project_id}/field_maps/{map_id}
# operationId: getTicketingProjectFieldMap
export def "ticketing-projects-field-maps get" [
  map_id: string
  ticketing_project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, body: table<strategy: string, external_field: string, external_value: record, user_data: record, cases: list, else: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/field_maps/($map_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a field map for a ticketing project
#
# DELETE /v1/ticketing/projects/{ticketing_project_id}/field_maps/{map_id}
# operationId: deleteTicketingProjectFieldMap
export def "ticketing-projects-field-maps delete" [
  map_id: string
  ticketing_project_id: string
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
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/field_maps/($map_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a field map for a ticketing project
#
# PATCH /v1/ticketing/projects/{ticketing_project_id}/field_maps/{map_id}
# operationId: updateTicketingProjectFieldMap
export def "ticketing-projects-field-maps updateTicketingProjectFieldMap" [
  map_id: string
  ticketing_project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, body: table<strategy: string, external_field: string, external_value: record, user_data: record, cases: list, else: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/field_maps/($map_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ticketing project configuration
#
# POST /v1/ticketing/projects/{ticketing_project_id}/provider_project_configurations
# operationId: createTicketingProjectConfiguration
export def "ticketing-projects-provider-project-configurations createTicketingProjectConfiguration" [
  ticketing_project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, ticketing_project_name: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/provider_project_configurations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ticketing project configuration
#
# GET /v1/ticketing/projects/{ticketing_project_id}/provider_project_configurations/{config_id}
# operationId: getTicketingProjectConfig
export def "ticketing-projects-provider-project-configurations get" [
  ticketing_project_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, ticketing_project_name: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/provider_project_configurations/($config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a ticketing project configuration
#
# DELETE /v1/ticketing/projects/{ticketing_project_id}/provider_project_configurations/{config_id}
# operationId: deleteTicketingProjectConfig
export def "ticketing-projects-provider-project-configurations delete" [
  ticketing_project_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, ticketing_project_name: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/provider_project_configurations/($config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a ticketing project configuration
#
# PATCH /v1/ticketing/projects/{ticketing_project_id}/provider_project_configurations/{config_id}
# operationId: updateTicketingProjectConfig
export def "ticketing-projects-provider-project-configurations updateTicketingProjectConfig" [
  ticketing_project_id: string
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_id: string, connection_type: string, ticketing_project_id: string, ticketing_project_name: string, details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/projects/($ticketing_project_id)/provider_project_configurations/($config_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ticket tags
#
# GET /v1/ticketing/ticket_tags
# operationId: listTicketTags
export def "ticketing-ticket-tags listTicketTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string
]: nothing -> record<data: table<name: string>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefix" $prefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ticketing/ticket_tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tickets
#
# GET /v1/ticketing/tickets
# operationId: listTickets
export def "ticketing-tickets listTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --tags: string # A comma separated list of tags
  --tag-match-strategy: string@tag-match-strategy-completer # A matching strategy for the tags provided
  --assigned-user: string # Filter tickets assigned to this user id
  --state: string@state-completer # Filter tickets by state
]: nothing -> record<id: string, summary: string, description: string, state: string, type: string, assignees: table<id: string, name: string, source: string, email: string>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "tag_match_strategy" $tag_match_strategy "scalar") (serialize-qp "assigned_user" $assigned_user "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ticketing/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ticket
#
# POST /v1/ticketing/tickets
# operationId: createTicket
export def "ticketing-tickets createTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  summary: string
  --related-to: string # Which incident this ticket is related to, in the format of 'incident/UUID'
  --project-id: string
  --description: string
  --state: string
  --type: string
  --priority-id: string
  --tag-list: list # List of tags for the ticket
  --remote-url: string # The remote URL for an existing ticket in a supported and configured ticketing integration
]: any -> record<id: string, summary: string, description: string, state: string, type: string, assignees: table<id: string, name: string, source: string, email: string>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ticketing/tickets")
  let body = {summary: $summary, related_to: $related_to, project_id: $project_id, description: $description, state: $state, type: $type, priority_id: $priority_id, tag_list: $tag_list, remote_url: $remote_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a ticket
#
# GET /v1/ticketing/tickets/{ticket_id}
# operationId: getTicket
export def "ticketing-tickets get" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, summary: string, description: string, state: string, type: string, assignees: table<id: string, name: string, source: string, email: string>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/tickets/($ticket_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a ticket
#
# DELETE /v1/ticketing/tickets/{ticket_id}
# operationId: deleteTicket
export def "ticketing-tickets delete" [
  ticket_id: string
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
  let full_url = (build-url $base $"/v1/ticketing/tickets/($ticket_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a ticket
#
# PATCH /v1/ticketing/tickets/{ticket_id}
# operationId: updateTicket
export def "ticketing-tickets updateTicket" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summary: string
  --description: string
  --state: string
  --type: string
  --priority-id: string
  --tag-list: list # List of tags for the ticket
]: any -> record<id: string, summary: string, description: string, state: string, type: string, assignees: table<id: string, name: string, source: string, email: string>, priority: record<id: string, name: string, position: int, created_at: string, updated_at: string>, created_by: record<id: string, name: string, source: string, email: string>, attachments: list<record>, created_at: string, updated_at: string, tag_list: list<string>, incident_id: string, incident_name: string, incident_current_milestone: string, task_id: string, due_at: string, link: record<id: string, type: string, display_text: string, href_url: string, icon_url: string, editable: bool, deletable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/ticketing/tickets/($ticket_id)")
  let body = {summary: $summary, description: $description, state: $state, type: $type, priority_id: $priority_id, tag_list: $tag_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List users
#
# GET /v1/users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
  --qp-query: string # Text string of a query to filter users by name or email
  --name: string # Text string of a query to filter users by name
]: nothing -> record<data: table<id: string, name: string, email: string, slack_user_id: string, slack_linked_: bool, created_at: string, updated_at: string, signals_enabled_notification_types: list>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /v1/users/{id}
# operationId: getUser
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, email: string, slack_user_id: string, slack_linked_: bool, created_at: string, updated_at: string, signals_enabled_notification_types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List services for a user's teams
#
# GET /v1/users/{id}/services
# operationId: listUserServices
export def "users-services listUserServices" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> table<data: list<record>, pagination: record<count: int, page: int, items: int, pages: int, last: int, prev: int, next: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($id)/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List webhooks
#
# GET /v1/webhooks
# operationId: listWebhooks
export def "webhooks listWebhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32
  --per-page: int # format: int32
]: nothing -> record<id: string, url: string, state: string, created_by: record<id: string, name: string, source: string, email: string>, created_at: string, updated_at: string, subscriptions: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /v1/webhooks
# operationId: createWebhook
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
]: any -> record<id: string, url: string, state: string, created_by: record<id: string, name: string, source: string, email: string>, created_at: string, updated_at: string, subscriptions: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webhooks")
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a webhook
#
# GET /v1/webhooks/{webhook_id}
# operationId: getWebhook
export def "webhooks get" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, url: string, state: string, created_by: record<id: string, name: string, source: string, email: string>, created_at: string, updated_at: string, subscriptions: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a webhook
#
# DELETE /v1/webhooks/{webhook_id}
# operationId: deleteWebhook
export def "webhooks delete" [
  webhook_id: string
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
  let full_url = (build-url $base $"/v1/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /v1/webhooks/{webhook_id}
# operationId: updateWebhook
export def "webhooks updateWebhook" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  --state: string@state-completer-1
]: any -> record<id: string, url: string, state: string, created_by: record<id: string, name: string, source: string, email: string>, created_at: string, updated_at: string, subscriptions: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($webhook_id)")
  let body = {url: $body_url, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List webhook deliveries
#
# GET /v1/webhooks/{webhook_id}/deliveries
# operationId: listWebhookDeliveries
export def "webhooks-deliveries listWebhookDeliveries" [
  webhook_id: string
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
  let full_url = (build-url $base $"/v1/webhooks/($webhook_id)/deliveries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
