# Auto-generated client for Flagsmith API vv1
# Source: https://api.flagsmith.com/api/v1/swagger.json
# Auth: --token flag or $env.FLAGSMITH_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "x-environment-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FLAGSMITH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-environment-key" => { {headers: {X-Environment-Key: $token_val}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["x-environment-key" "bearer" "basic"] }

# Completers for enum parameters
def format-completer [] { ["json" "xml"] }
def format-completer-1 [] { ["html" "json"] }
def accept-completer [] { ["application/json" "text/html"] }
def django-attribute-name-completer [] { ["email" "first_name" "groups" "last_name"] }
def aggregation-completer [] { ["count" "mean" "occurrence" "sum"] }
def direction-completer [] { ["down" "informational" "up"] }
def expected-direction-completer [] { ["decrease" "increase" "not_decrease" "not_increase"] }
def warehouse-type-completer [] { ["clickhouse" "flagsmith" "snowflake"] }
def strategy-completer [] { ["OVERWRITE_DESTRUCTIVE" "SKIP"] }
def type-completer [] { ["bool" "int" "multiline_str" "str" "url"] }
def role-completer [] { ["ADMIN" "USER"] }
def period-completer [] { ["" "90_day_period" "current_billing_period" "previous_billing_period"] }
def name-completer [] { ["Grafana" "Webhook"] }
def sort-direction-completer [] { ["ASC" "DESC"] }
def sort-field-completer [] { ["created_date" "name"] }
def tag-strategy-completer [] { ["INTERSECTION" "UNION"] }
def type-completer-1 [] { ["MULTIVARIATE" "STANDARD"] }
def type-completer-2 [] { ["GITHUB_ISSUE" "GITHUB_PR" "GITLAB_ISSUE" "GITLAB_MR"] }
def entity-completer [] { ["environment" "feature" "segment"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "experiments-environments-delete-segment-override create" } } | get name | first)
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

# Delete segment override
#
# POST /api/experiments/environments/{environment_key}/delete-segment-override/
# operationId: api_experiments_environments_delete_segment_override_create
# --feature shape: {name?: string, id?: int}
# --segment shape: {id: int}
export def "experiments-environments-delete-segment-override create" [
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: record # shape: {name?: string, id?: int}
  segment: record # shape: {id: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/experiments/environments/($environment_key)/delete-segment-override/")
  let body = {feature: $feature, segment: $segment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update single feature state
#
# POST /api/experiments/environments/{environment_key}/update-flag-v1/
# operationId: api_experiments_environments_update_flag_v1_create
# --feature shape: {name?: string, id?: int}
# --segment shape: {id: int, priority?: int}
# --value shape: {type: "integer"|"string"|"boolean", value: string}
export def "experiments-environments-update-flag-v1 create" [
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: record # shape: {name?: string, id?: int}
  --segment: record # shape: {id: int, priority?: int}
  --enabled: oneof<nothing, bool>
  value: record # shape: {type: "integer"|"string"|"boolean", value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/experiments/environments/($environment_key)/update-flag-v1/")
  let body = {feature: $feature, segment: $segment, enabled: $enabled, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update multiple feature states
#
# POST /api/experiments/environments/{environment_key}/update-flag-v2/
# operationId: api_experiments_environments_update_flag_v2_create
# --feature shape: {name?: string, id?: int}
# --environment_default shape: {enabled: bool, value: record}
# --segment_overrides item shape: {segment_id: int, priority?: int, enabled: bool, value: record}
export def "experiments-environments-update-flag-v2 create" [
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: record # shape: {name?: string, id?: int}
  environment_default: record # shape: {enabled: bool, value: record}
  --segment-overrides: list # item shape: {segment_id: int, priority?: int, enabled: bool, value: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/experiments/environments/($environment_key)/update-flag-v2/")
  let body = {feature: $feature, environment_default: $environment_default, segment_overrides: $segment_overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/admin/dashboard/integrations/
#
# operationId: api_v1_admin_dashboard_integrations_retrieve
export def "admin-dashboard-integrations get" [
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
  let full_url = (build-url $base "/api/v1/admin/dashboard/integrations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/admin/dashboard/organisations/
#
# operationId: api_v1_admin_dashboard_organisations_retrieve
export def "admin-dashboard-organisations get" [
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
  let full_url = (build-url $base "/api/v1/admin/dashboard/organisations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/admin/dashboard/release-pipelines/
#
# operationId: api_v1_admin_dashboard_release_pipelines_retrieve
export def "admin-dashboard-release-pipelines get" [
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
  let full_url = (build-url $base "/api/v1/admin/dashboard/release-pipelines/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/admin/dashboard/stale-flags/
#
# operationId: api_v1_admin_dashboard_stale_flags_retrieve
export def "admin-dashboard-stale-flags get" [
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
  let full_url = (build-url $base "/api/v1/admin/dashboard/stale-flags/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/admin/dashboard/summary/
#
# operationId: api_v1_admin_dashboard_summary_retrieve
export def "admin-dashboard-summary get" [
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
  let full_url = (build-url $base "/api/v1/admin/dashboard/summary/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/admin/dashboard/usage-trends/
#
# operationId: api_v1_admin_dashboard_usage_trends_retrieve
export def "admin-dashboard-usage-trends get" [
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
  let full_url = (build-url $base "/api/v1/admin/dashboard/usage-trends/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Class to handle flag analytics events
#
# POST /api/v1/analytics/flags/
# operationId: api_v1_analytics_flags_create
export def "analytics-flags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/analytics/flags/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Class to handle telemetry events from self hosted APIs so we can aggregate and track self hosted installation data
#
# POST /api/v1/analytics/telemetry/
# operationId: api_v1_analytics_telemetry_create
export def "analytics-telemetry create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organisations: int
  projects: int
  environments: int
  features: int
  segments: int
  users: int
  --debug-enabled: oneof<nothing, bool>
  env: string
]: any -> record<organisations: int, projects: int, environments: int, features: int, segments: int, users: int, debug_enabled: bool, env: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/analytics/telemetry/")
  let body = {organisations: $organisations, projects: $projects, environments: $environments, features: $features, segments: $segments, users: $users, debug_enabled: $debug_enabled, env: $env} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/audit/
#
# operationId: api_v1_audit_list
export def "audit list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environments: list
  --is-system-event: oneof<nothing, bool>
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --project: int
  --search: string
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, created_date: string, log: string, author: record, environment: record, project: record, related_object_id: int, related_object_uuid: string, related_object_type: string, is_system_event: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environments" $environments "multi") (serialize-qp "is_system_event" $is_system_event "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/audit/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/audit/{id}/
#
# operationId: api_v1_audit_retrieve
export def "audit get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_date: string, log: string, author: record<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, environment: record<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool>, project: record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool>, related_object_id: int, related_object_uuid: string, related_object_type: string, is_system_event: bool, change_details: table<field: string, old: string, new: string>, change_type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/audit/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/{method}/activate/
#
# operationId: api_v1_auth_activate_create
export def "auth-activate create" [
  method: string
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
  let full_url = (build-url $base $"/api/v1/auth/($method)/activate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/{method}/activate/confirm/
#
# operationId: api_v1_auth_activate_confirm_create
export def "auth-activate-confirm create" [
  method: string
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
  let full_url = (build-url $base $"/api/v1/auth/($method)/activate/confirm/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/{method}/deactivate/
#
# operationId: api_v1_auth_deactivate_create
export def "auth-deactivate create" [
  method: string
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
  let full_url = (build-url $base $"/api/v1/auth/($method)/deactivate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Class to handle throttling for login requests
#
# POST /api/v1/auth/login/
# operationId: api_v1_auth_login_create
export def "auth-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string
  --email: string
]: any -> record<password: string, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/login/")
  let body = {password: $password, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Override class to add throttling
#
# POST /api/v1/auth/login/code/
# operationId: api_v1_auth_login_code_create
export def "auth-login-code create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string
  --email: string
]: any -> record<password: string, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/login/code/")
  let body = {password: $password, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use this endpoint to logout user (remove user authentication token).
#
# POST /api/v1/auth/logout/
# operationId: api_v1_auth_logout_create
export def "auth-logout create" [
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
  let full_url = (build-url $base "/api/v1/auth/logout/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/auth/mfa/user-active-methods/
#
# operationId: api_v1_auth_mfa_user_active_methods_retrieve
export def "auth-mfa-user-active-methods get" [
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
  let full_url = (build-url $base "/api/v1/auth/mfa/user-active-methods/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/oauth/github/
#
# operationId: api_v1_auth_oauth_github_create
export def "auth-oauth-github create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # Code or access token returned from the FE interaction with the third party login provider.
  --sign-up-type: any # Provide information about how the user signed up (i.e. via invite or not)  * `NO_INVITE` - No Invite * `INVITE_EMAIL` - Invite Email * `INVITE_LINK` - Invite Link
  --hubspot-cookie: string # nullable
  --marketing-consent-given: oneof<nothing, bool> # nullable
  --utm-data: any
]: any -> record<key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/oauth/github/")
  let body = {access_token: $access_token, sign_up_type: $sign_up_type, hubspot_cookie: $hubspot_cookie, marketing_consent_given: $marketing_consent_given, utm_data: $utm_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/auth/oauth/google/
#
# operationId: api_v1_auth_oauth_google_create
export def "auth-oauth-google create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # Code or access token returned from the FE interaction with the third party login provider.
  --sign-up-type: any # Provide information about how the user signed up (i.e. via invite or not)  * `NO_INVITE` - No Invite * `INVITE_EMAIL` - Invite Email * `INVITE_LINK` - Invite Link
  --hubspot-cookie: string # nullable
  --marketing-consent-given: oneof<nothing, bool> # nullable
  --utm-data: any
]: any -> record<key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/oauth/google/")
  let body = {access_token: $access_token, sign_up_type: $sign_up_type, hubspot_cookie: $hubspot_cookie, marketing_consent_given: $marketing_consent_given, utm_data: $utm_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/auth/saml/{name}/metadata/
#
# operationId: api_v1_auth_saml_metadata_retrieve
export def "auth-saml-metadata get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/auth/saml/($name)/metadata/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/saml/{name}/request/
#
# operationId: api_v1_auth_saml_request_create
export def "auth-saml-request create" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer-1
]: nothing -> record<headers: record<Location: string>, status: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/auth/saml/($name)/request/" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/saml/{name}/response/
#
# operationId: api_v1_auth_saml_response_create
export def "auth-saml-response create" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/auth/saml/($name)/response/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/auth/saml/attribute-mapping/
#
# operationId: api_v1_auth_saml_attribute_mapping_list
export def "auth-saml-attribute-mapping list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organisation: int
  --page: int # A page number within the paginated result set.
  --saml-configuration: int
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, saml_configuration: int, django_attribute_name: string, idp_attribute_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organisation" $organisation "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "saml_configuration" $saml_configuration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/auth/saml/attribute-mapping/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/saml/attribute-mapping/
#
# operationId: api_v1_auth_saml_attribute_mapping_create
export def "auth-saml-attribute-mapping create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  saml_configuration: int
  django_attribute_name: string@django-attribute-name-completer # * `email` - Email * `first_name` - First / Given name * `last_name` - Last name / Surname * `groups` - Groups
  idp_attribute_name: string
]: any -> record<id: int, saml_configuration: int, django_attribute_name: string, idp_attribute_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/saml/attribute-mapping/")
  let body = {saml_configuration: $saml_configuration, django_attribute_name: $django_attribute_name, idp_attribute_name: $idp_attribute_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/auth/saml/attribute-mapping/{id}/
#
# operationId: api_v1_auth_saml_attribute_mapping_retrieve
export def "auth-saml-attribute-mapping get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, saml_configuration: int, django_attribute_name: string, idp_attribute_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/saml/attribute-mapping/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/auth/saml/attribute-mapping/{id}/
#
# operationId: api_v1_auth_saml_attribute_mapping_update
export def "auth-saml-attribute-mapping update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  saml_configuration: int
  django_attribute_name: string@django-attribute-name-completer # * `email` - Email * `first_name` - First / Given name * `last_name` - Last name / Surname * `groups` - Groups
  idp_attribute_name: string
]: any -> record<id: int, saml_configuration: int, django_attribute_name: string, idp_attribute_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/saml/attribute-mapping/($id)/")
  let body = {saml_configuration: $saml_configuration, django_attribute_name: $django_attribute_name, idp_attribute_name: $idp_attribute_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/auth/saml/attribute-mapping/{id}/
#
# operationId: api_v1_auth_saml_attribute_mapping_partial_update
export def "auth-saml-attribute-mapping patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --saml-configuration: int
  --django-attribute-name: string@django-attribute-name-completer # * `email` - Email * `first_name` - First / Given name * `last_name` - Last name / Surname * `groups` - Groups
  --idp-attribute-name: string
]: any -> record<id: int, saml_configuration: int, django_attribute_name: string, idp_attribute_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/saml/attribute-mapping/($id)/")
  let body = {saml_configuration: $saml_configuration, django_attribute_name: $django_attribute_name, idp_attribute_name: $idp_attribute_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/auth/saml/attribute-mapping/{id}/
#
# operationId: api_v1_auth_saml_attribute_mapping_destroy
export def "auth-saml-attribute-mapping delete" [
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
  let full_url = (build-url $base $"/api/v1/auth/saml/attribute-mapping/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/auth/saml/configuration/
#
# operationId: api_v1_auth_saml_configuration_list
export def "auth-saml-configuration list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organisation: int
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, organisation: int, name: string, frontend_url: string, idp_metadata_xml: string, allow_idp_initiated: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organisation" $organisation "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/auth/saml/configuration/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/saml/configuration/
#
# operationId: api_v1_auth_saml_configuration_create
export def "auth-saml-configuration create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organisation: int
  name: string # An alphanumeric string to uniquely identify the saml configuration.
  frontend_url: string # Base URL to redirect to on a successful SAML authentication, e.g. https://app.flagsmith.com/ (format: uri)
  --idp-metadata-xml: string # nullable
  --allow-idp-initiated: oneof<nothing, bool>
]: any -> record<id: int, organisation: int, name: string, frontend_url: string, idp_metadata_xml: string, allow_idp_initiated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/saml/configuration/")
  let body = {organisation: $organisation, name: $name, frontend_url: $frontend_url, idp_metadata_xml: $idp_metadata_xml, allow_idp_initiated: $allow_idp_initiated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/auth/saml/configuration/{name}/
#
# operationId: api_v1_auth_saml_configuration_retrieve
export def "auth-saml-configuration get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, organisation: int, name: string, frontend_url: string, idp_metadata_xml: string, allow_idp_initiated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/saml/configuration/($name)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/auth/saml/configuration/{name}/
#
# operationId: api_v1_auth_saml_configuration_update
export def "auth-saml-configuration update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  organisation: int
  --body-name: string # An alphanumeric string to uniquely identify the saml configuration.
  frontend_url: string # Base URL to redirect to on a successful SAML authentication, e.g. https://app.flagsmith.com/ (format: uri)
  --idp-metadata-xml: string # nullable
  --allow-idp-initiated: oneof<nothing, bool>
]: any -> record<id: int, organisation: int, name: string, frontend_url: string, idp_metadata_xml: string, allow_idp_initiated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/saml/configuration/($name)/")
  let body = {organisation: $organisation, name: $body_name, frontend_url: $frontend_url, idp_metadata_xml: $idp_metadata_xml, allow_idp_initiated: $allow_idp_initiated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/auth/saml/configuration/{name}/
#
# operationId: api_v1_auth_saml_configuration_partial_update
export def "auth-saml-configuration patch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organisation: int
  --body-name: string # An alphanumeric string to uniquely identify the saml configuration.
  --frontend-url: string # Base URL to redirect to on a successful SAML authentication, e.g. https://app.flagsmith.com/ (format: uri)
  --idp-metadata-xml: string # nullable
  --allow-idp-initiated: oneof<nothing, bool>
]: any -> record<id: int, organisation: int, name: string, frontend_url: string, idp_metadata_xml: string, allow_idp_initiated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/saml/configuration/($name)/")
  let body = {organisation: $organisation, name: $body_name, frontend_url: $frontend_url, idp_metadata_xml: $idp_metadata_xml, allow_idp_initiated: $allow_idp_initiated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/auth/saml/configuration/{name}/
#
# operationId: api_v1_auth_saml_configuration_destroy
export def "auth-saml-configuration delete" [
  name: string
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
  let full_url = (build-url $base $"/api/v1/auth/saml/configuration/($name)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/saml/login/
#
# operationId: api_v1_auth_saml_login_create
export def "auth-saml-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # Code or access token returned from the FE interaction with the third party login provider.
]: any -> record<key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/saml/login/")
  let body = {access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/auth/token/
#
# operationId: api_v1_auth_token_destroy
export def "auth-token delete" [
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
  let full_url = (build-url $base "/api/v1/auth/token/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/auth/users/
#
# operationId: api_v1_auth_users_list
export def "auth-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<first_name: string, last_name: string, sign_up_type: any, id: int, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/auth/users/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/users/
#
# operationId: api_v1_auth_users_create
export def "auth-users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  first_name: string
  last_name: string
  --sign-up-type: any
  email: string # format: email
  password: string
]: any -> record<first_name: string, last_name: string, sign_up_type: any, email: string, id: int, password: string, is_active: bool, marketing_consent_given: bool, uuid: string, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/")
  let body = {first_name: $first_name, last_name: $last_name, sign_up_type: $sign_up_type, email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/auth/users/{id}/
#
# operationId: api_v1_auth_users_retrieve
export def "auth-users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<first_name: string, last_name: string, sign_up_type: any, id: int, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/users/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/auth/users/{id}/
#
# operationId: api_v1_auth_users_update
export def "auth-users update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  first_name: string
  last_name: string
  --sign-up-type: any
]: any -> record<first_name: string, last_name: string, sign_up_type: any, id: int, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/users/($id)/")
  let body = {first_name: $first_name, last_name: $last_name, sign_up_type: $sign_up_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/auth/users/{id}/
#
# operationId: api_v1_auth_users_partial_update
export def "auth-users patch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --sign-up-type: any
]: any -> record<first_name: string, last_name: string, sign_up_type: any, id: int, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/users/($id)/")
  let body = {first_name: $first_name, last_name: $last_name, sign_up_type: $sign_up_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/auth/users/{id}/
#
# operationId: api_v1_auth_users_destroy
export def "auth-users delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-password: string
  --delete-orphan-organisations: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current_password" $current_password "scalar") (serialize-qp "delete_orphan_organisations" $delete_orphan_organisations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/auth/users/($id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/auth/users/activation/
#
# operationId: api_v1_auth_users_activation_create
export def "auth-users-activation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  uid: string
  --body-token: string
]: any -> record<uid: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/activation/")
  let body = {uid: $uid, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/auth/users/me/
#
# operationId: api_v1_auth_users_me_retrieve
export def "auth-users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<first_name: string, last_name: string, sign_up_type: any, id: int, email: string, auth_type: string, is_superuser: bool, date_joined: string, uuid: string, pylon_email_signature: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/me/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/auth/users/me/
#
# operationId: api_v1_auth_users_me_update
export def "auth-users-me update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  first_name: string
  last_name: string
  --sign-up-type: any
  --date-joined: string # format: date-time
]: any -> record<first_name: string, last_name: string, sign_up_type: any, id: int, email: string, auth_type: string, is_superuser: bool, date_joined: string, uuid: string, pylon_email_signature: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/me/")
  let body = {first_name: $first_name, last_name: $last_name, sign_up_type: $sign_up_type, date_joined: $date_joined} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/auth/users/me/
#
# operationId: api_v1_auth_users_me_partial_update
export def "auth-users-me patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --sign-up-type: any
  --date-joined: string # format: date-time
]: any -> record<first_name: string, last_name: string, sign_up_type: any, id: int, email: string, auth_type: string, is_superuser: bool, date_joined: string, uuid: string, pylon_email_signature: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/me/")
  let body = {first_name: $first_name, last_name: $last_name, sign_up_type: $sign_up_type, date_joined: $date_joined} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/auth/users/me/
#
# operationId: api_v1_auth_users_me_destroy
export def "auth-users-me delete" [
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
  let full_url = (build-url $base "/api/v1/auth/users/me/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/auth/users/me/onboarding/
#
# operationId: api_v1_auth_users_me_onboarding_partial_update
export def "auth-users-me-onboarding patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --sign-up-type: any
]: any -> record<first_name: string, last_name: string, sign_up_type: any, id: int, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/me/onboarding/")
  let body = {first_name: $first_name, last_name: $last_name, sign_up_type: $sign_up_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/auth/users/resend_activation/
#
# operationId: api_v1_auth_users_resend_activation_create
export def "auth-users-resend-activation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> record<email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/resend_activation/")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/auth/users/reset_email/
#
# operationId: api_v1_auth_users_reset_email_create
export def "auth-users-reset-email create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> record<email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/reset_email/")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/auth/users/reset_email_confirm/
#
# operationId: api_v1_auth_users_reset_email_confirm_create
export def "auth-users-reset-email-confirm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_email: string # format: email
]: any -> record<new_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/reset_email_confirm/")
  let body = {new_email: $new_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/auth/users/reset_password/
#
# operationId: api_v1_auth_users_reset_password_create
export def "auth-users-reset-password create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> record<email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/reset_password/")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/auth/users/reset_password_confirm/
#
# operationId: api_v1_auth_users_reset_password_confirm_create
export def "auth-users-reset-password-confirm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  uid: string
  --body-token: string
  new_password: string
  re_new_password: string
]: any -> record<uid: string, token: string, new_password: string, re_new_password: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/reset_password_confirm/")
  let body = {uid: $uid, token: $body_token, new_password: $new_password, re_new_password: $re_new_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/auth/users/set_email/
#
# operationId: api_v1_auth_users_set_email_create
export def "auth-users-set-email create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  current_password: string
  new_email: string # format: email
]: any -> record<current_password: string, new_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/set_email/")
  let body = {current_password: $current_password, new_email: $new_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/auth/users/set_password/
#
# operationId: api_v1_auth_users_set_password_create
export def "auth-users-set-password create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string
  re_new_password: string
  current_password: string
]: any -> record<new_password: string, re_new_password: string, current_password: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/users/set_password/")
  let body = {new_password: $new_password, re_new_password: $re_new_password, current_password: $current_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Endpoint to handle webhooks from chargebee.  Payment failure and payment succeeded webhooks are filtered out and processed to determine which of our subscriptions are in a dunning state.  The remaining webhooks are processed if they have subscription data:   - If subscription is active, check to see if plan has changed and update if so. Always update cancellation date to    None to ensure that if a subscription is reactivated, it is updated on our end.   - If subscription is cancelled or not renewing, update subscription on our end to include cancellation date and    send alert to admin users.
#
# POST /api/v1/cb-webhook/
# operationId: api_v1_cb_webhook_create
export def "cb-webhook create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/cb-webhook/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the environment document. Used by SDKs in local evaluation mode, and Edge Proxy.
#
# GET /api/v1/environment-document/
# operationId: sdk_v1_environment_document
export def "environment-document document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api_key: string, feature_states: table<feature: record, enabled: bool, feature_state_value: any, featurestate_uuid: string, feature_segment: any, multivariate_feature_state_values: list>, identity_overrides: table<identifier: string, identity_features: list>, name: string, project: record<segments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/environment-document/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This is an additional endpoint to retrieve a specific version without needing to provide the environment or feature as part of the URL.
#
# GET /api/v1/environment-feature-versions/{id}/
# operationId: api_v1_environment_feature_versions_retrieve
export def "environment-feature-versions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, updated_at: string, published: bool, live_from: string, uuid: string, is_live: bool, published_by: int, created_by: int, description: string, previous_version_uuid: string, feature: int, environment: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environment-feature-versions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all environments the user has access to
#
# GET /api/v1/environments/
# operationId: list_environments
export def "environments environments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
  --project: int # ID of the project to filter by.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool, metadata: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/environments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/
#
# operationId: api_v1_environments_create
# --metadata item shape: {model_field: int, field_value: string}
export def "environments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --api-key: string
  --description: string # nullable
  project: int # Changing the project selected will remove all previous Feature States for the previously associated projects Features that are related to this Environment. New default Feature States will be created for the new selected projects Features for this Environment.
  --allow-client-traits: oneof<nothing, bool> # Allows clients using the client API key to set traits.
  --banner-text: string # nullable
  --banner-colour: string # hex code for the banner colour (nullable)
  --hide-disabled-flags: oneof<nothing, bool> # If true will exclude flags from SDK which are disabled. NOTE: If set, this will override the project `hide_disabled_flags` (nullable)
  --use-identity-composite-key-for-hashing: oneof<nothing, bool> # Enable this to have consistent multivariate and percentage split evaluations across all SDKs (in local and server side mode)
  --hide-sensitive-data: oneof<nothing, bool> # If true, will hide sensitive data(e.g: traits, description etc) from the SDK endpoints
  --use-identity-overrides-in-local-eval: oneof<nothing, bool> # When enabled, identity overrides will be included in the environment document
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool, metadata: table<id: int, model_field: int, field_value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/environments/")
  let body = {name: $name, api_key: $api_key, description: $description, project: $project, allow_client_traits: $allow_client_traits, banner_text: $banner_text, banner_colour: $banner_colour, hide_disabled_flags: $hide_disabled_flags, use_identity_composite_key_for_hashing: $use_identity_composite_key_for_hashing, hide_sensitive_data: $hide_sensitive_data, use_identity_overrides_in_local_eval: $use_identity_overrides_in_local_eval, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{api_key}/
#
# operationId: api_v1_environments_retrieve
export def "environments get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool, metadata: table<id: int, model_field: int, field_value: string>, total_segment_overrides: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{api_key}/
#
# operationId: api_v1_environments_update
# --metadata item shape: {model_field: int, field_value: string}
export def "environments update" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --body-api-key: string
  --description: string # nullable
  --allow-client-traits: oneof<nothing, bool> # Allows clients using the client API key to set traits.
  --banner-text: string # nullable
  --banner-colour: string # hex code for the banner colour (nullable)
  --hide-disabled-flags: oneof<nothing, bool> # If true will exclude flags from SDK which are disabled. NOTE: If set, this will override the project `hide_disabled_flags` (nullable)
  --use-identity-composite-key-for-hashing: oneof<nothing, bool> # Enable this to have consistent multivariate and percentage split evaluations across all SDKs (in local and server side mode)
  --hide-sensitive-data: oneof<nothing, bool> # If true, will hide sensitive data(e.g: traits, description etc) from the SDK endpoints
  --use-identity-overrides-in-local-eval: oneof<nothing, bool> # When enabled, identity overrides will be included in the environment document
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool, metadata: table<id: int, model_field: int, field_value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/")
  let body = {name: $name, api_key: $body_api_key, description: $description, allow_client_traits: $allow_client_traits, banner_text: $banner_text, banner_colour: $banner_colour, hide_disabled_flags: $hide_disabled_flags, use_identity_composite_key_for_hashing: $use_identity_composite_key_for_hashing, hide_sensitive_data: $hide_sensitive_data, use_identity_overrides_in_local_eval: $use_identity_overrides_in_local_eval, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{api_key}/
#
# operationId: api_v1_environments_partial_update
# --metadata item shape: {model_field: int, field_value: string}
export def "environments patch" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --body-api-key: string
  --description: string # nullable
  --allow-client-traits: oneof<nothing, bool> # Allows clients using the client API key to set traits.
  --banner-text: string # nullable
  --banner-colour: string # hex code for the banner colour (nullable)
  --hide-disabled-flags: oneof<nothing, bool> # If true will exclude flags from SDK which are disabled. NOTE: If set, this will override the project `hide_disabled_flags` (nullable)
  --use-identity-composite-key-for-hashing: oneof<nothing, bool> # Enable this to have consistent multivariate and percentage split evaluations across all SDKs (in local and server side mode)
  --hide-sensitive-data: oneof<nothing, bool> # If true, will hide sensitive data(e.g: traits, description etc) from the SDK endpoints
  --use-identity-overrides-in-local-eval: oneof<nothing, bool> # When enabled, identity overrides will be included in the environment document
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool, metadata: table<id: int, model_field: int, field_value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/")
  let body = {name: $name, api_key: $body_api_key, description: $description, allow_client_traits: $allow_client_traits, banner_text: $banner_text, banner_colour: $banner_colour, hide_disabled_flags: $hide_disabled_flags, use_identity_composite_key_for_hashing: $use_identity_composite_key_for_hashing, hide_sensitive_data: $hide_sensitive_data, use_identity_overrides_in_local_eval: $use_identity_overrides_in_local_eval, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{api_key}/
#
# operationId: api_v1_environments_destroy
export def "environments delete" [
  api_key: string
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
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{api_key}/clone/
#
# operationId: api_v1_environments_clone_create
export def "environments-clone create" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --clone-feature-states-async: oneof<nothing, bool> # If True, the environment will be created immediately, but the feature states will be created asynchronously. Environment will have `is_creating: true` until this process is completed. (default: false)
]: any -> record<id: int, name: string, api_key: string, project: int, clone_feature_states_async: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/clone/")
  let body = {name: $name, clone_feature_states_async: $clone_feature_states_async} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/environments/{api_key}/delete-traits/
#
# operationId: api_v1_environments_delete_traits_create
export def "environments-delete-traits create" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string
]: any -> record<key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/delete-traits/")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/environments/{api_key}/disable-v2-versioning/
#
# operationId: api_v1_environments_disable_v2_versioning_create
export def "environments-disable-v2-versioning create" [
  api_key: string
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
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/disable-v2-versioning/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{api_key}/document/
#
# operationId: api_v1_environments_document_retrieve
export def "environments-document get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api_key: string, feature_states: table<feature: record, enabled: bool, feature_state_value: any, featurestate_uuid: string, feature_segment: any, multivariate_feature_state_values: list>, identity_overrides: table<identifier: string, identity_features: list>, name: string, project: record<segments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/document/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{api_key}/enable-v2-versioning/
#
# operationId: api_v1_environments_enable_v2_versioning_create
export def "environments-enable-v2-versioning create" [
  api_key: string
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
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/enable-v2-versioning/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{api_key}/my-permissions/
#
# operationId: api_v1_environments_my_permissions_retrieve
export def "environments-my-permissions get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: list<string>, admin: bool, tag_based_permissions: table<permissions: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/my-permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{api_key}/trait-keys/
#
# operationId: api_v1_environments_trait_keys_retrieve
export def "environments-trait-keys get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/trait-keys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{api_key}/user-detailed-permissions/{user_id}/
#
# operationId: api_v1_environments_user_detailed_permissions_retrieve
export def "environments-user-detailed-permissions get" [
  api_key: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: bool, permissions: table<permission_key: string, is_directly_granted: bool, derived_from: record>, is_directly_granted: bool, derived_from: record<groups: list<record>, roles: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($api_key)/user-detailed-permissions/($user_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# GET /api/v1/environments/{environment_api_key}/api-keys/
# operationId: api_v1_environments_api_keys_list
export def "environments-api-keys list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, key: string, active: bool, created_at: string, name: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/api-keys/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/api-keys/
# operationId: api_v1_environments_api_keys_create
export def "environments-api-keys create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  name: string
  --expires-at: string # nullable, format: date-time
]: any -> record<id: int, key: string, active: bool, created_at: string, name: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/api-keys/")
  let body = {active: $active, name: $name, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PUT /api/v1/environments/{environment_api_key}/api-keys/{id}/
# operationId: api_v1_environments_api_keys_update
export def "environments-api-keys update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  name: string
  --expires-at: string # nullable, format: date-time
]: any -> record<id: int, key: string, active: bool, created_at: string, name: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/api-keys/($id)/")
  let body = {active: $active, name: $name, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PATCH /api/v1/environments/{environment_api_key}/api-keys/{id}/
# operationId: api_v1_environments_api_keys_partial_update
export def "environments-api-keys patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --name: string
  --expires-at: string # nullable, format: date-time
]: any -> record<id: int, key: string, active: bool, created_at: string, name: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/api-keys/($id)/")
  let body = {active: $active, name: $name, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# DELETE /api/v1/environments/{environment_api_key}/api-keys/{id}/
# operationId: api_v1_environments_api_keys_destroy
export def "environments-api-keys delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/api-keys/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new change request for feature flag modifications in an environment.
#
# POST /api/v1/environments/{environment_api_key}/create-change-request/
# operationId: create_environment_feature_change_request
# --feature_states item shape: {feature: int, feature_segment?: int, enabled?: bool, feature_state_value?: record, multivariate_feature_state_values?: list, live_from?: string}
# --approvals item shape: {user: int}
# --group_assignments item shape: {group: int}
# --change_sets item shape: {feature: int, live_from?: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list}
export def "environments-create-change-request request" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  --description: string # nullable
  feature_states: list # item shape: {feature: int, feature_segment?: int, enabled?: bool, feature_state_value?: record, multivariate_feature_state_values?: list, live_from?: string}
  --approvals: list # item shape: {user: int}
  --group-assignments: list # item shape: {group: int}
  --environment-feature-versions: list
  --change-sets: list # nullable — item shape: {feature: int, live_from?: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list}
  --ignore-conflicts: oneof<nothing, bool>
]: any -> record<id: int, created_at: string, updated_at: string, title: string, description: string, feature_states: table<id: int, feature: int, feature_segment: int, enabled: bool, feature_state_value: record, multivariate_feature_state_values: list, live_from: string>, deleted_at: string, environment: int, committed_at: string, approvals: table<id: int, user: int, approved_at: string>, user: int, committed_by: int, group_assignments: table<group: int>, environment_feature_versions: list<string>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, ignore_conflicts: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/create-change-request/")
  let body = {title: $title, description: $description, feature_states: $feature_states, approvals: $approvals, group_assignments: $group_assignments, environment_feature_versions: $environment_feature_versions, change_sets: $change_sets, ignore_conflicts: $ignore_conflicts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/edge-identities/
#
# operationId: api_v1_environments_edge_identities_list
export def "environments-edge-identities list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-evaluated-key: string # Used as the starting point for the page
  --page-size: int # Number of results to return per page.
]: nothing -> record<last_evaluated_key: string, results: table<identity_uuid: string, identifier: string, dashboard_alias: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_evaluated_key" $last_evaluated_key "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/edge-identities/
#
# operationId: api_v1_environments_edge_identities_create
export def "environments-edge-identities create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string
  --dashboard-alias: string
]: any -> record<identity_uuid: string, identifier: string, dashboard_alias: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/")
  let body = {identifier: $identifier, dashboard_alias: $dashboard_alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/edge-identities/{edge_identity_identity_uuid}/edge-featurestates/
#
# operationId: api_v1_environments_edge_identities_edge_featurestates_list
export def "environments-edge-identities-edge-featurestates list" [
  edge_identity_identity_uuid: string
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: int # ID of the feature to filter by
]: nothing -> table<feature_state_value: string, feature: int, multivariate_feature_state_values: list<record>, enabled: bool, featurestate_uuid: string, identity_uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feature" $feature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($edge_identity_identity_uuid)/edge-featurestates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/edge-identities/{edge_identity_identity_uuid}/edge-featurestates/
#
# operationId: api_v1_environments_edge_identities_edge_featurestates_create
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-edge-identities-edge-featurestates create" [
  edge_identity_identity_uuid: string
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-state-value: string # Feature state value (string, integer, or boolean) (nullable)
  feature: int # Feature ID
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --enabled: oneof<nothing, bool> # default: false
]: any -> record<feature_state_value: string, feature: int, multivariate_feature_state_values: table<multivariate_feature_option: int, percentage_allocation: float>, enabled: bool, featurestate_uuid: string, identity_uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($edge_identity_identity_uuid)/edge-featurestates/")
  let body = {feature_state_value: $feature_state_value, feature: $feature, multivariate_feature_state_values: $multivariate_feature_state_values, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/edge-identities/{edge_identity_identity_uuid}/edge-featurestates/{featurestate_uuid}/
#
# operationId: api_v1_environments_edge_identities_edge_featurestates_retrieve
export def "environments-edge-identities-edge-featurestates get" [
  edge_identity_identity_uuid: string
  environment_api_key: string
  featurestate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<feature_state_value: string, feature: int, multivariate_feature_state_values: table<multivariate_feature_option: int, percentage_allocation: float>, enabled: bool, featurestate_uuid: string, identity_uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($edge_identity_identity_uuid)/edge-featurestates/($featurestate_uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/edge-identities/{edge_identity_identity_uuid}/edge-featurestates/{featurestate_uuid}/
#
# operationId: api_v1_environments_edge_identities_edge_featurestates_update
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-edge-identities-edge-featurestates update" [
  edge_identity_identity_uuid: string
  environment_api_key: string
  featurestate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-state-value: string # Feature state value (string, integer, or boolean) (nullable)
  feature: int # Feature ID
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --enabled: oneof<nothing, bool> # default: false
]: any -> record<feature_state_value: string, feature: int, multivariate_feature_state_values: table<multivariate_feature_option: int, percentage_allocation: float>, enabled: bool, featurestate_uuid: string, identity_uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($edge_identity_identity_uuid)/edge-featurestates/($featurestate_uuid)/")
  let body = {feature_state_value: $feature_state_value, feature: $feature, multivariate_feature_state_values: $multivariate_feature_state_values, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/edge-identities/{edge_identity_identity_uuid}/edge-featurestates/{featurestate_uuid}/
#
# operationId: api_v1_environments_edge_identities_edge_featurestates_destroy
export def "environments-edge-identities-edge-featurestates delete" [
  edge_identity_identity_uuid: string
  environment_api_key: string
  featurestate_uuid: string
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($edge_identity_identity_uuid)/edge-featurestates/($featurestate_uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/edge-identities/{edge_identity_identity_uuid}/edge-featurestates/all/
#
# operationId: api_v1_environments_edge_identities_edge_featurestates_all_list
export def "environments-edge-identities-edge-featurestates-all list" [
  edge_identity_identity_uuid: string
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<feature: record<id: int, name: string, type: string>, enabled: bool, feature_state_value: any, overridden_by: string, segment: record<id: int, name: string>, multivariate_feature_state_values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($edge_identity_identity_uuid)/edge-featurestates/all/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clone feature states from a given source identity.
#
# POST /api/v1/environments/{environment_api_key}/edge-identities/{edge_identity_identity_uuid}/edge-featurestates/clone-from-given-identity/
# operationId: api_v1_environments_edge_identities_edge_featurestates_clone_from_given_identity_create
export def "environments-edge-identities-edge-featurestates-clone-from-given-identity create" [
  edge_identity_identity_uuid: string
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  source_identity_uuid: string # UUID of the source identity to clone feature states from.
]: any -> table<feature: record<id: int, name: string, type: string>, enabled: bool, feature_state_value: any, overridden_by: string, segment: record<id: int, name: string>, multivariate_feature_state_values: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($edge_identity_identity_uuid)/edge-featurestates/clone-from-given-identity/")
  let body = {source_identity_uuid: $source_identity_uuid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/edge-identities/{identity_uuid}/
#
# operationId: api_v1_environments_edge_identities_retrieve
export def "environments-edge-identities get" [
  environment_api_key: string
  identity_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<identity_uuid: string, identifier: string, dashboard_alias: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($identity_uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/edge-identities/{identity_uuid}/
#
# operationId: api_v1_environments_edge_identities_update
export def "environments-edge-identities update" [
  environment_api_key: string
  identity_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dashboard-alias: string
]: any -> record<identity_uuid: string, identifier: string, dashboard_alias: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($identity_uuid)/")
  let body = {dashboard_alias: $dashboard_alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/edge-identities/{identity_uuid}/
#
# operationId: api_v1_environments_edge_identities_partial_update
export def "environments-edge-identities patch" [
  environment_api_key: string
  identity_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dashboard-alias: string
]: any -> record<identity_uuid: string, identifier: string, dashboard_alias: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($identity_uuid)/")
  let body = {dashboard_alias: $dashboard_alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/edge-identities/{identity_uuid}/
#
# operationId: api_v1_environments_edge_identities_destroy
export def "environments-edge-identities delete" [
  environment_api_key: string
  identity_uuid: string
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($identity_uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/edge-identities/{identity_uuid}/list-traits/
#
# operationId: api_v1_environments_edge_identities_list_traits_list
export def "environments-edge-identities-list-traits list" [
  environment_api_key: string
  identity_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-evaluated-key: string # Used as the starting point for the page
  --page-size: int # Number of results to return per page.
]: nothing -> record<last_evaluated_key: string, results: table<trait_key: string, trait_value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_evaluated_key" $last_evaluated_key "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($identity_uuid)/list-traits/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/edge-identities/{identity_uuid}/update-traits/
#
# operationId: api_v1_environments_edge_identities_update_traits_update
export def "environments-edge-identities-update-traits update" [
  environment_api_key: string
  identity_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  trait_key: string
  --trait-value: string # nullable
]: any -> record<trait_key: string, trait_value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identities/($identity_uuid)/update-traits/")
  let body = {trait_key: $trait_key, trait_value: $trait_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/edge-identity-overrides
#
# operationId: api_v1_environments_edge_identity_overrides_retrieve
export def "environments-edge-identity-overrides get" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: int
]: nothing -> record<results: table<identifier: string, identity_uuid: string, feature_state: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feature" $feature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/edge-identity-overrides" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# GET /api/v1/environments/{environment_api_key}/experiment-metrics/
# operationId: api_v1_environments_experiment_metrics_list
export def "environments-experiment-metrics list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, description: string, aggregation: string, direction: string, definition: any, experiments: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiment-metrics/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/experiment-metrics/
# operationId: api_v1_environments_experiment_metrics_create
# --experiments item shape: {id: int, name: string, status: string}
export def "environments-experiment-metrics create" [
  environment_api_key: string
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
  --aggregation: string@aggregation-completer # * `count` - Count * `sum` - Sum * `mean` - Mean * `occurrence` - Occurrence (event happened at least once)
  --direction: string@direction-completer # * `up` - Higher is better * `down` - Lower is better * `informational` - Informational only
  definition: any
]: any -> record<id: int, name: string, description: string, aggregation: string, direction: string, definition: any, experiments: table<id: int, name: string, status: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiment-metrics/")
  let body = {name: $name, description: $description, aggregation: $aggregation, direction: $direction, definition: $definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# GET /api/v1/environments/{environment_api_key}/experiment-metrics/{id}/
# operationId: api_v1_environments_experiment_metrics_retrieve
export def "environments-experiment-metrics get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, description: string, aggregation: string, direction: string, definition: any, experiments: table<id: int, name: string, status: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiment-metrics/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PUT /api/v1/environments/{environment_api_key}/experiment-metrics/{id}/
# operationId: api_v1_environments_experiment_metrics_update
# --experiments item shape: {id: int, name: string, status: string}
export def "environments-experiment-metrics update" [
  environment_api_key: string
  id: int
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
  --aggregation: string@aggregation-completer # * `count` - Count * `sum` - Sum * `mean` - Mean * `occurrence` - Occurrence (event happened at least once)
  --direction: string@direction-completer # * `up` - Higher is better * `down` - Lower is better * `informational` - Informational only
  definition: any
]: any -> record<id: int, name: string, description: string, aggregation: string, direction: string, definition: any, experiments: table<id: int, name: string, status: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiment-metrics/($id)/")
  let body = {name: $name, description: $description, aggregation: $aggregation, direction: $direction, definition: $definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PATCH /api/v1/environments/{environment_api_key}/experiment-metrics/{id}/
# operationId: api_v1_environments_experiment_metrics_partial_update
# --experiments item shape: {id: int, name: string, status: string}
export def "environments-experiment-metrics patch" [
  environment_api_key: string
  id: int
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
  --aggregation: string@aggregation-completer # * `count` - Count * `sum` - Sum * `mean` - Mean * `occurrence` - Occurrence (event happened at least once)
  --direction: string@direction-completer # * `up` - Higher is better * `down` - Lower is better * `informational` - Informational only
  --definition: any
]: any -> record<id: int, name: string, description: string, aggregation: string, direction: string, definition: any, experiments: table<id: int, name: string, status: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiment-metrics/($id)/")
  let body = {name: $name, description: $description, aggregation: $aggregation, direction: $direction, definition: $definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# DELETE /api/v1/environments/{environment_api_key}/experiment-metrics/{id}/
# operationId: api_v1_environments_experiment_metrics_destroy
export def "environments-experiment-metrics delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiment-metrics/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# GET /api/v1/environments/{environment_api_key}/experiments/
# operationId: api_v1_environments_experiments_list
export def "environments-experiments list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, feature: record, name: string, hypothesis: string, status: record, created_at: string, updated_at: string, started_at: string, ended_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/experiments/
# operationId: api_v1_environments_experiments_create
export def "environments-experiments create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: int
  name: string
  hypothesis: string
]: any -> record<id: int, feature: int, name: string, hypothesis: string, status: record, created_at: string, updated_at: string, started_at: string, ended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/")
  let body = {feature: $feature, name: $name, hypothesis: $hypothesis} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/experiments/{experiment_experiment_id}/metrics/
#
# operationId: api_v1_environments_experiments_metrics_list
export def "environments-experiments-metrics list" [
  environment_api_key: string
  experiment_experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, metric: int, metric_name: string, aggregation: string, expected_direction: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_experiment_id)/metrics/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/experiments/{experiment_experiment_id}/metrics/
#
# operationId: api_v1_environments_experiments_metrics_create
export def "environments-experiments-metrics create" [
  environment_api_key: string
  experiment_experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  metric: int
  expected_direction: string@expected-direction-completer # * `increase` - Increase * `decrease` - Decrease * `not_increase` - Should not increase * `not_decrease` - Should not decrease
]: any -> record<id: int, metric: int, metric_name: string, aggregation: string, expected_direction: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_experiment_id)/metrics/")
  let body = {metric: $metric, expected_direction: $expected_direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/experiments/{experiment_experiment_id}/metrics/{id}/
#
# operationId: api_v1_environments_experiments_metrics_retrieve
export def "environments-experiments-metrics get" [
  environment_api_key: string
  experiment_experiment_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, metric: int, metric_name: string, aggregation: string, expected_direction: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_experiment_id)/metrics/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/experiments/{experiment_experiment_id}/metrics/{id}/
#
# operationId: api_v1_environments_experiments_metrics_update
export def "environments-experiments-metrics update" [
  environment_api_key: string
  experiment_experiment_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  metric: int
  expected_direction: string@expected-direction-completer # * `increase` - Increase * `decrease` - Decrease * `not_increase` - Should not increase * `not_decrease` - Should not decrease
]: any -> record<id: int, metric: int, metric_name: string, aggregation: string, expected_direction: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_experiment_id)/metrics/($id)/")
  let body = {metric: $metric, expected_direction: $expected_direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/experiments/{experiment_experiment_id}/metrics/{id}/
#
# operationId: api_v1_environments_experiments_metrics_partial_update
export def "environments-experiments-metrics patch" [
  environment_api_key: string
  experiment_experiment_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metric: int
  --expected-direction: string@expected-direction-completer # * `increase` - Increase * `decrease` - Decrease * `not_increase` - Should not increase * `not_decrease` - Should not decrease
]: any -> record<id: int, metric: int, metric_name: string, aggregation: string, expected_direction: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_experiment_id)/metrics/($id)/")
  let body = {metric: $metric, expected_direction: $expected_direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/experiments/{experiment_experiment_id}/metrics/{id}/
#
# operationId: api_v1_environments_experiments_metrics_destroy
export def "environments-experiments-metrics delete" [
  environment_api_key: string
  experiment_experiment_id: string
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_experiment_id)/metrics/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# GET /api/v1/environments/{environment_api_key}/experiments/{experiment_id}/
# operationId: api_v1_environments_experiments_retrieve
export def "environments-experiments get" [
  environment_api_key: string
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, feature: record<id: int, name: string, type: record, initial_value: string, multivariate_options: list<record>>, name: string, hypothesis: string, status: record, created_at: string, updated_at: string, started_at: string, ended_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PUT /api/v1/environments/{environment_api_key}/experiments/{experiment_id}/
# operationId: api_v1_environments_experiments_update
export def "environments-experiments update" [
  environment_api_key: string
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: int
  name: string
  hypothesis: string
]: any -> record<id: int, feature: int, name: string, hypothesis: string, status: record, created_at: string, updated_at: string, started_at: string, ended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_id)/")
  let body = {feature: $feature, name: $name, hypothesis: $hypothesis} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PATCH /api/v1/environments/{environment_api_key}/experiments/{experiment_id}/
# operationId: api_v1_environments_experiments_partial_update
export def "environments-experiments patch" [
  environment_api_key: string
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: int
  --name: string
  --hypothesis: string
]: any -> record<id: int, feature: int, name: string, hypothesis: string, status: record, created_at: string, updated_at: string, started_at: string, ended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_id)/")
  let body = {feature: $feature, name: $name, hypothesis: $hypothesis} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# DELETE /api/v1/environments/{environment_api_key}/experiments/{experiment_id}/
# operationId: api_v1_environments_experiments_destroy
export def "environments-experiments delete" [
  environment_api_key: string
  experiment_id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/experiments/{experiment_id}/complete/
# operationId: api_v1_environments_experiments_complete_create
export def "environments-experiments-complete create" [
  environment_api_key: string
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  hypothesis: string
]: any -> record<id: int, feature: record<id: int, name: string, type: record, initial_value: string, multivariate_options: list<record>>, name: string, hypothesis: string, status: record, created_at: string, updated_at: string, started_at: string, ended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_id)/complete/")
  let body = {name: $name, hypothesis: $hypothesis} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/experiments/{experiment_id}/pause/
# operationId: api_v1_environments_experiments_pause_create
export def "environments-experiments-pause create" [
  environment_api_key: string
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  hypothesis: string
]: any -> record<id: int, feature: record<id: int, name: string, type: record, initial_value: string, multivariate_options: list<record>>, name: string, hypothesis: string, status: record, created_at: string, updated_at: string, started_at: string, ended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_id)/pause/")
  let body = {name: $name, hypothesis: $hypothesis} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/experiments/{experiment_id}/start/
# operationId: api_v1_environments_experiments_start_create
export def "environments-experiments-start create" [
  environment_api_key: string
  experiment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  hypothesis: string
]: any -> record<id: int, feature: record<id: int, name: string, type: record, initial_value: string, multivariate_options: list<record>>, name: string, hypothesis: string, status: record, created_at: string, updated_at: string, started_at: string, ended_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/($experiment_id)/start/")
  let body = {name: $name, hypothesis: $hypothesis} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get experiment results for a feature.  Returns conversion rates and statistical significance for each variant of a feature flag experiment.  Trait naming convention: - Variant tracking: `exp_{feature}_variant` (string value) - Conversion tracking: `exp_{feature}_converted` (boolean value)
#
# GET /api/v1/environments/{environment_api_key}/experiments/results/
# operationId: api_v1_environments_experiments_results_retrieve
export def "environments-experiments-results get" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: string # Feature name to analyse
]: nothing -> record<feature: string, variants: table<variant: string, evaluations: int, conversions: int, conversion_rate: float>, statistics: record<p_value: float, significant: bool, chance_to_win: record, lift: string, winner: string, recommendation: string, sample_size_warning: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feature" $feature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/experiments/results/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a segment override for a feature in an environment in a single call, setting both the segment binding and its value. Applies to environments without v2 feature versioning (use_v2_feature_versioning: false).
#
# POST /api/v1/environments/{environment_api_key}/features/{feature_pk}/create-segment-override/
# operationId: create_segment_override
# --feature_state_value shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-features-create-segment-override override" [
  environment_api_key: string
  feature_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  feature_state_value: record # shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
  --feature-segment: any
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
]: any -> record<id: int, feature: int, enabled: bool, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, feature_segment: any, deleted_at: string, uuid: string, created_at: string, updated_at: string, live_from: string, environment: int, identity: int, change_request: int, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/features/($feature_pk)/create-segment-override/")
  let body = {enabled: $enabled, feature_state_value: $feature_state_value, feature_segment: $feature_segment, multivariate_feature_state_values: $multivariate_feature_state_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View set to manage feature states. Nested beneath environments and environments + identities to allow for filtering on both.
#
# GET /api/v1/environments/{environment_api_key}/featurestates/
# operationId: api_v1_environments_featurestates_list
export def "environments-featurestates list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anyIdentity: string # Pass any value to get results that have an identity override. Do not pass for default behaviour.
  --feature: int # ID of the feature to filter by.
  --feature-name: string # Name of the feature to filter by.
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, feature_state_value: string, multivariate_feature_state_values: list, identifier: string, identity: record, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, feature_segment: int, change_request: int, environment_feature_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "anyIdentity" $anyIdentity "scalar") (serialize-qp "feature" $feature "scalar") (serialize-qp "feature_name" $feature_name "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/featurestates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPRECATED: please use `/features/featurestates/` instead. Override create method to add environment and identity (if present) from URL parameters.
#
# POST /api/v1/environments/{environment_api_key}/featurestates/
# operationId: api_v1_environments_featurestates_create
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-featurestates create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --identifier: string # Can be passed as an alternative to `identity`
  --enabled: oneof<nothing, bool>
  --live-from: string # nullable, format: date-time
  feature: int
  --environment: int # nullable
  --identity: int # nullable
  --feature-segment: int # nullable
  --change-request: int # nullable
  --environment-feature-version: string # nullable, format: uuid
]: any -> record<id: int, feature_state_value: string, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/featurestates/")
  let body = {multivariate_feature_state_values: $multivariate_feature_state_values, identifier: $identifier, enabled: $enabled, live_from: $live_from, feature: $feature, environment: $environment, identity: $identity, feature_segment: $feature_segment, change_request: $change_request, environment_feature_version: $environment_feature_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View set to manage feature states. Nested beneath environments and environments + identities to allow for filtering on both.
#
# GET /api/v1/environments/{environment_api_key}/featurestates/{id}/
# operationId: api_v1_environments_featurestates_retrieve
export def "environments-featurestates get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, feature_state_value: string, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/featurestates/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a feature state in an environment, including enabled status and value. Applies to environments without v2 feature versioning (use_v2_feature_versioning: false).
#
# PUT /api/v1/environments/{environment_api_key}/featurestates/{id}/
# operationId: update_environment_feature_state
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-featurestates state" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --identifier: string # Can be passed as an alternative to `identity`
  --enabled: oneof<nothing, bool>
  --live-from: string # nullable, format: date-time
  feature: int
  --environment: int # nullable
  --identity: int # nullable
  --feature-segment: int # nullable
  --change-request: int # nullable
  --environment-feature-version: string # nullable, format: uuid
]: any -> record<id: int, feature_state_value: string, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/featurestates/($id)/")
  let body = {multivariate_feature_state_values: $multivariate_feature_state_values, identifier: $identifier, enabled: $enabled, live_from: $live_from, feature: $feature, environment: $environment, identity: $identity, feature_segment: $feature_segment, change_request: $change_request, environment_feature_version: $environment_feature_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Override partial_update as overridden update method assumes partial True for all requests.
#
# PATCH /api/v1/environments/{environment_api_key}/featurestates/{id}/
# operationId: api_v1_environments_featurestates_partial_update
export def "environments-featurestates patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: int
  --enabled: oneof<nothing, bool>
]: any -> record<feature: int, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/featurestates/($id)/")
  let body = {feature: $feature, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View set to manage feature states. Nested beneath environments and environments + identities to allow for filtering on both.
#
# DELETE /api/v1/environments/{environment_api_key}/featurestates/{id}/
# operationId: api_v1_environments_featurestates_destroy
export def "environments-featurestates delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/featurestates/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/identities/
#
# operationId: api_v1_environments_identities_list
export def "environments-identities list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, identifier: string, environment: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/identities/
#
# operationId: api_v1_environments_identities_create
export def "environments-identities create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string
]: any -> record<id: int, identifier: string, environment: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/")
  let body = {identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View set to manage feature states. Nested beneath environments and environments + identities to allow for filtering on both.
#
# GET /api/v1/environments/{environment_api_key}/identities/{identity_pk}/featurestates/
# operationId: api_v1_environments_identities_featurestates_list
export def "environments-identities-featurestates list" [
  environment_api_key: string
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anyIdentity: string # Pass any value to get results that have an identity override. Do not pass for default behaviour.
  --feature: int # ID of the feature to filter by.
  --feature-name: string # Name of the feature to filter by.
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, feature_state_value: string, multivariate_feature_state_values: list, identifier: string, identity: record, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, feature_segment: int, change_request: int, environment_feature_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "anyIdentity" $anyIdentity "scalar") (serialize-qp "feature" $feature "scalar") (serialize-qp "feature_name" $feature_name "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/featurestates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPRECATED: please use `/features/featurestates/` instead. Override create method to add environment and identity (if present) from URL parameters.
#
# POST /api/v1/environments/{environment_api_key}/identities/{identity_pk}/featurestates/
# operationId: api_v1_environments_identities_featurestates_create
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-identities-featurestates create" [
  environment_api_key: string
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --identifier: string # Can be passed as an alternative to `identity`
  --enabled: oneof<nothing, bool>
  --live-from: string # nullable, format: date-time
  feature: int
  --environment: int # nullable
  --identity: int # nullable
  --feature-segment: int # nullable
  --change-request: int # nullable
  --environment-feature-version: string # nullable, format: uuid
]: any -> record<id: int, feature_state_value: string, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/featurestates/")
  let body = {multivariate_feature_state_values: $multivariate_feature_state_values, identifier: $identifier, enabled: $enabled, live_from: $live_from, feature: $feature, environment: $environment, identity: $identity, feature_segment: $feature_segment, change_request: $change_request, environment_feature_version: $environment_feature_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View set to manage feature states. Nested beneath environments and environments + identities to allow for filtering on both.
#
# GET /api/v1/environments/{environment_api_key}/identities/{identity_pk}/featurestates/{id}/
# operationId: api_v1_environments_identities_featurestates_retrieve
export def "environments-identities-featurestates get" [
  environment_api_key: string
  id: int
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, feature_state_value: string, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/featurestates/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Override update method to always assume update request is partial and create / update feature state value.
#
# PUT /api/v1/environments/{environment_api_key}/identities/{identity_pk}/featurestates/{id}/
# operationId: api_v1_environments_identities_featurestates_update
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-identities-featurestates update" [
  environment_api_key: string
  id: int
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --identifier: string # Can be passed as an alternative to `identity`
  --enabled: oneof<nothing, bool>
  --live-from: string # nullable, format: date-time
  feature: int
  --environment: int # nullable
  --identity: int # nullable
  --feature-segment: int # nullable
  --change-request: int # nullable
  --environment-feature-version: string # nullable, format: uuid
]: any -> record<id: int, feature_state_value: string, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/featurestates/($id)/")
  let body = {multivariate_feature_state_values: $multivariate_feature_state_values, identifier: $identifier, enabled: $enabled, live_from: $live_from, feature: $feature, environment: $environment, identity: $identity, feature_segment: $feature_segment, change_request: $change_request, environment_feature_version: $environment_feature_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Override partial_update as overridden update method assumes partial True for all requests.
#
# PATCH /api/v1/environments/{environment_api_key}/identities/{identity_pk}/featurestates/{id}/
# operationId: api_v1_environments_identities_featurestates_partial_update
export def "environments-identities-featurestates patch" [
  environment_api_key: string
  id: int
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: int
  --enabled: oneof<nothing, bool>
]: any -> record<feature: int, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/featurestates/($id)/")
  let body = {feature: $feature, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View set to manage feature states. Nested beneath environments and environments + identities to allow for filtering on both.
#
# DELETE /api/v1/environments/{environment_api_key}/identities/{identity_pk}/featurestates/{id}/
# operationId: api_v1_environments_identities_featurestates_destroy
export def "environments-identities-featurestates delete" [
  environment_api_key: string
  id: int
  identity_pk: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/featurestates/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View set to manage feature states. Nested beneath environments and environments + identities to allow for filtering on both.
#
# GET /api/v1/environments/{environment_api_key}/identities/{identity_pk}/featurestates/all/
# operationId: api_v1_environments_identities_featurestates_all_retrieve
export def "environments-identities-featurestates-all get" [
  environment_api_key: string
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<feature: int, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/featurestates/all/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clone feature states from a given source identity.
#
# POST /api/v1/environments/{environment_api_key}/identities/{identity_pk}/featurestates/clone-from-given-identity/
# operationId: api_v1_environments_identities_featurestates_clone_from_given_identity_create
export def "environments-identities-featurestates-clone-from-given-identity create" [
  environment_api_key: string
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
  source_identity_id: int # ID of the source identity to clone feature states from.
]: any -> record<count: int, next: string, previous: string, results: table<feature: record, enabled: bool, feature_state_value: any, overridden_by: string, segment: record, multivariate_feature_state_values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/featurestates/clone-from-given-identity/" $qp)
  let body = {source_identity_id: $source_identity_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/identities/{identity_pk}/traits/
#
# operationId: api_v1_environments_identities_traits_list
export def "environments-identities-traits list" [
  environment_api_key: string
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, trait_key: string, value_type: any, integer_value: int, string_value: string, boolean_value: bool, float_value: float, created_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/traits/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/identities/{identity_pk}/traits/
#
# operationId: api_v1_environments_identities_traits_create
export def "environments-identities-traits create" [
  environment_api_key: string
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  trait_key: string
  --value-type: any
  --integer-value: int # nullable
  --string-value: string # nullable
  --boolean-value: oneof<nothing, bool> # nullable
  --float-value: float # nullable, format: double
]: any -> record<id: int, trait_key: string, value_type: any, integer_value: int, string_value: string, boolean_value: bool, float_value: float, created_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/traits/")
  let body = {trait_key: $trait_key, value_type: $value_type, integer_value: $integer_value, string_value: $string_value, boolean_value: $boolean_value, float_value: $float_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/identities/{identity_pk}/traits/{id}/
#
# operationId: api_v1_environments_identities_traits_retrieve
export def "environments-identities-traits get" [
  environment_api_key: string
  id: int
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, trait_key: string, value_type: any, integer_value: int, string_value: string, boolean_value: bool, float_value: float, created_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/traits/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/identities/{identity_pk}/traits/{id}/
#
# operationId: api_v1_environments_identities_traits_update
export def "environments-identities-traits update" [
  environment_api_key: string
  id: int
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  trait_key: string
  --value-type: any
  --integer-value: int # nullable
  --string-value: string # nullable
  --boolean-value: oneof<nothing, bool> # nullable
  --float-value: float # nullable, format: double
]: any -> record<id: int, trait_key: string, value_type: any, integer_value: int, string_value: string, boolean_value: bool, float_value: float, created_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/traits/($id)/")
  let body = {trait_key: $trait_key, value_type: $value_type, integer_value: $integer_value, string_value: $string_value, boolean_value: $boolean_value, float_value: $float_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/identities/{identity_pk}/traits/{id}/
#
# operationId: api_v1_environments_identities_traits_partial_update
export def "environments-identities-traits patch" [
  environment_api_key: string
  id: int
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trait-key: string
  --value-type: any
  --integer-value: int # nullable
  --string-value: string # nullable
  --boolean-value: oneof<nothing, bool> # nullable
  --float-value: float # nullable, format: double
]: any -> record<id: int, trait_key: string, value_type: any, integer_value: int, string_value: string, boolean_value: bool, float_value: float, created_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/traits/($id)/")
  let body = {trait_key: $trait_key, value_type: $value_type, integer_value: $integer_value, string_value: $string_value, boolean_value: $boolean_value, float_value: $float_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/identities/{identity_pk}/traits/{id}/
#
# operationId: api_v1_environments_identities_traits_destroy
export def "environments-identities-traits delete" [
  environment_api_key: string
  id: int
  identity_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleteAllMatchingTraits: oneof<nothing, bool> # Deletes all traits in this environment matching the key of the deleted trait
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteAllMatchingTraits" $deleteAllMatchingTraits "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($identity_pk)/traits/($id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/identities/{id}/
#
# operationId: api_v1_environments_identities_retrieve
export def "environments-identities get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, identifier: string, environment: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/identities/{id}/
#
# operationId: api_v1_environments_identities_update
export def "environments-identities update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string
]: any -> record<id: int, identifier: string, environment: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($id)/")
  let body = {identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/identities/{id}/
#
# operationId: api_v1_environments_identities_partial_update
export def "environments-identities patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifier: string
]: any -> record<id: int, identifier: string, environment: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($id)/")
  let body = {identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/identities/{id}/
#
# operationId: api_v1_environments_identities_destroy
export def "environments-identities delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/identities/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/amplitude/
#
# operationId: api_v1_environments_integrations_amplitude_list
export def "environments-integrations-amplitude list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, api_key: string, base_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/amplitude/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/amplitude/
#
# operationId: api_v1_environments_integrations_amplitude_create
export def "environments-integrations-amplitude create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
  --body-base-url: string # format: uri
]: any -> record<id: int, api_key: string, base_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/amplitude/")
  let body = {api_key: $api_key, base_url: $body_base_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/amplitude/{id}/
#
# operationId: api_v1_environments_integrations_amplitude_retrieve
export def "environments-integrations-amplitude get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, api_key: string, base_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/amplitude/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/amplitude/{id}/
#
# operationId: api_v1_environments_integrations_amplitude_update
export def "environments-integrations-amplitude update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
  --body-base-url: string # format: uri
]: any -> record<id: int, api_key: string, base_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/amplitude/($id)/")
  let body = {api_key: $api_key, base_url: $body_base_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/amplitude/{id}/
#
# operationId: api_v1_environments_integrations_amplitude_partial_update
export def "environments-integrations-amplitude patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --body-base-url: string # format: uri
]: any -> record<id: int, api_key: string, base_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/amplitude/($id)/")
  let body = {api_key: $api_key, base_url: $body_base_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/amplitude/{id}/
#
# operationId: api_v1_environments_integrations_amplitude_destroy
export def "environments-integrations-amplitude delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/amplitude/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/dynatrace/
#
# operationId: api_v1_environments_integrations_dynatrace_list
export def "environments-integrations-dynatrace list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, base_url: string, api_key: string, entity_selector: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/dynatrace/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/dynatrace/
#
# operationId: api_v1_environments_integrations_dynatrace_create
export def "environments-integrations-dynatrace create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
  entity_selector: string
]: any -> record<id: int, base_url: string, api_key: string, entity_selector: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/dynatrace/")
  let body = {base_url: $body_base_url, api_key: $api_key, entity_selector: $entity_selector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/dynatrace/{id}/
#
# operationId: api_v1_environments_integrations_dynatrace_retrieve
export def "environments-integrations-dynatrace get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, base_url: string, api_key: string, entity_selector: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/dynatrace/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/dynatrace/{id}/
#
# operationId: api_v1_environments_integrations_dynatrace_update
export def "environments-integrations-dynatrace update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
  entity_selector: string
]: any -> record<id: int, base_url: string, api_key: string, entity_selector: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/dynatrace/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key, entity_selector: $entity_selector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/dynatrace/{id}/
#
# operationId: api_v1_environments_integrations_dynatrace_partial_update
export def "environments-integrations-dynatrace patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  --api-key: string
  --entity-selector: string
]: any -> record<id: int, base_url: string, api_key: string, entity_selector: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/dynatrace/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key, entity_selector: $entity_selector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/dynatrace/{id}/
#
# operationId: api_v1_environments_integrations_dynatrace_destroy
export def "environments-integrations-dynatrace delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/dynatrace/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/grafana/
#
# operationId: api_v1_environments_integrations_grafana_list
export def "environments-integrations-grafana list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, base_url: string, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/grafana/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/grafana/
#
# operationId: api_v1_environments_integrations_grafana_create
export def "environments-integrations-grafana create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/grafana/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/grafana/{id}/
#
# operationId: api_v1_environments_integrations_grafana_retrieve
export def "environments-integrations-grafana get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, base_url: string, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/grafana/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/grafana/{id}/
#
# operationId: api_v1_environments_integrations_grafana_update
export def "environments-integrations-grafana update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/grafana/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/grafana/{id}/
#
# operationId: api_v1_environments_integrations_grafana_partial_update
export def "environments-integrations-grafana patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  --api-key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/grafana/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/grafana/{id}/
#
# operationId: api_v1_environments_integrations_grafana_destroy
export def "environments-integrations-grafana delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/grafana/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/heap/
#
# operationId: api_v1_environments_integrations_heap_list
export def "environments-integrations-heap list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/heap/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/heap/
#
# operationId: api_v1_environments_integrations_heap_create
export def "environments-integrations-heap create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
]: any -> record<id: int, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/heap/")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/heap/{id}/
#
# operationId: api_v1_environments_integrations_heap_retrieve
export def "environments-integrations-heap get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/heap/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/heap/{id}/
#
# operationId: api_v1_environments_integrations_heap_update
export def "environments-integrations-heap update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
]: any -> record<id: int, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/heap/($id)/")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/heap/{id}/
#
# operationId: api_v1_environments_integrations_heap_partial_update
export def "environments-integrations-heap patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
]: any -> record<id: int, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/heap/($id)/")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/heap/{id}/
#
# operationId: api_v1_environments_integrations_heap_destroy
export def "environments-integrations-heap delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/heap/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/mixpanel/
#
# operationId: api_v1_environments_integrations_mixpanel_list
export def "environments-integrations-mixpanel list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/mixpanel/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/mixpanel/
#
# operationId: api_v1_environments_integrations_mixpanel_create
export def "environments-integrations-mixpanel create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
]: any -> record<id: int, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/mixpanel/")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/mixpanel/{id}/
#
# operationId: api_v1_environments_integrations_mixpanel_retrieve
export def "environments-integrations-mixpanel get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/mixpanel/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/mixpanel/{id}/
#
# operationId: api_v1_environments_integrations_mixpanel_update
export def "environments-integrations-mixpanel update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
]: any -> record<id: int, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/mixpanel/($id)/")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/mixpanel/{id}/
#
# operationId: api_v1_environments_integrations_mixpanel_partial_update
export def "environments-integrations-mixpanel patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
]: any -> record<id: int, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/mixpanel/($id)/")
  let body = {api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/mixpanel/{id}/
#
# operationId: api_v1_environments_integrations_mixpanel_destroy
export def "environments-integrations-mixpanel delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/mixpanel/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/rudderstack/
#
# operationId: api_v1_environments_integrations_rudderstack_list
export def "environments-integrations-rudderstack list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, base_url: string, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/rudderstack/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/rudderstack/
#
# operationId: api_v1_environments_integrations_rudderstack_create
export def "environments-integrations-rudderstack create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/rudderstack/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/rudderstack/{id}/
#
# operationId: api_v1_environments_integrations_rudderstack_retrieve
export def "environments-integrations-rudderstack get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, base_url: string, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/rudderstack/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/rudderstack/{id}/
#
# operationId: api_v1_environments_integrations_rudderstack_update
export def "environments-integrations-rudderstack update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/rudderstack/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/rudderstack/{id}/
#
# operationId: api_v1_environments_integrations_rudderstack_partial_update
export def "environments-integrations-rudderstack patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  --api-key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/rudderstack/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/rudderstack/{id}/
#
# operationId: api_v1_environments_integrations_rudderstack_destroy
export def "environments-integrations-rudderstack delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/rudderstack/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/segment/
#
# operationId: api_v1_environments_integrations_segment_list
export def "environments-integrations-segment list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, api_key: string, base_url: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/segment/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/segment/
#
# operationId: api_v1_environments_integrations_segment_create
export def "environments-integrations-segment create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
  --body-base-url: any # default: https://api.segment.io/
]: any -> record<id: int, api_key: string, base_url: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/segment/")
  let body = {api_key: $api_key, base_url: $body_base_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/segment/{id}/
#
# operationId: api_v1_environments_integrations_segment_retrieve
export def "environments-integrations-segment get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, api_key: string, base_url: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/segment/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/segment/{id}/
#
# operationId: api_v1_environments_integrations_segment_update
export def "environments-integrations-segment update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
  --body-base-url: any # default: https://api.segment.io/
]: any -> record<id: int, api_key: string, base_url: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/segment/($id)/")
  let body = {api_key: $api_key, base_url: $body_base_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/segment/{id}/
#
# operationId: api_v1_environments_integrations_segment_partial_update
export def "environments-integrations-segment patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --body-base-url: any # default: https://api.segment.io/
]: any -> record<id: int, api_key: string, base_url: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/segment/($id)/")
  let body = {api_key: $api_key, base_url: $body_base_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/segment/{id}/
#
# operationId: api_v1_environments_integrations_segment_destroy
export def "environments-integrations-segment delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/segment/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/sentry/
#
# operationId: api_v1_environments_integrations_sentry_list
export def "environments-integrations-sentry list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, environment: int, webhook_url: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/sentry/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/sentry/
#
# operationId: api_v1_environments_integrations_sentry_create
export def "environments-integrations-sentry create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook_url: string # format: uri
  secret: string
]: any -> record<id: int, environment: int, webhook_url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/sentry/")
  let body = {webhook_url: $webhook_url, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/sentry/{id}/
#
# operationId: api_v1_environments_integrations_sentry_retrieve
export def "environments-integrations-sentry get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, environment: int, webhook_url: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/sentry/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/sentry/{id}/
#
# operationId: api_v1_environments_integrations_sentry_update
export def "environments-integrations-sentry update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook_url: string # format: uri
  secret: string
]: any -> record<id: int, environment: int, webhook_url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/sentry/($id)/")
  let body = {webhook_url: $webhook_url, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/sentry/{id}/
#
# operationId: api_v1_environments_integrations_sentry_partial_update
export def "environments-integrations-sentry patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --webhook-url: string # format: uri
  --secret: string
]: any -> record<id: int, environment: int, webhook_url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/sentry/($id)/")
  let body = {webhook_url: $webhook_url, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/sentry/{id}/
#
# operationId: api_v1_environments_integrations_sentry_destroy
export def "environments-integrations-sentry delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/sentry/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/slack/
#
# operationId: api_v1_environments_integrations_slack_list
export def "environments-integrations-slack list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, channel_id: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/slack/
#
# operationId: api_v1_environments_integrations_slack_create
export def "environments-integrations-slack create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: string # Id of the slack channel to post messages to
  --enabled: oneof<nothing, bool>
]: any -> record<id: int, channel_id: string, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/")
  let body = {channel_id: $channel_id, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/slack-channels/
#
# operationId: api_v1_environments_integrations_slack_channels_list
export def "environments-integrations-slack-channels list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<cursor: string, channels: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack-channels/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/slack/{id}/
#
# operationId: api_v1_environments_integrations_slack_retrieve
export def "environments-integrations-slack get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, channel_id: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/slack/{id}/
#
# operationId: api_v1_environments_integrations_slack_update
export def "environments-integrations-slack update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: string # Id of the slack channel to post messages to
  --enabled: oneof<nothing, bool>
]: any -> record<id: int, channel_id: string, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/($id)/")
  let body = {channel_id: $channel_id, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/slack/{id}/
#
# operationId: api_v1_environments_integrations_slack_partial_update
export def "environments-integrations-slack patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-id: string # Id of the slack channel to post messages to
  --enabled: oneof<nothing, bool>
]: any -> record<id: int, channel_id: string, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/($id)/")
  let body = {channel_id: $channel_id, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/slack/{id}/
#
# operationId: api_v1_environments_integrations_slack_destroy
export def "environments-integrations-slack delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/slack/callback/
#
# operationId: api_v1_environments_integrations_slack_callback_retrieve
export def "environments-integrations-slack-callback get" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, channel_id: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/callback/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/slack/oauth/
#
# operationId: api_v1_environments_integrations_slack_oauth_retrieve
export def "environments-integrations-slack-oauth get" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, channel_id: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/oauth/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/slack/signature/
#
# operationId: api_v1_environments_integrations_slack_signature_retrieve
export def "environments-integrations-slack-signature get" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, channel_id: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/slack/signature/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/integrations/webhook/
#
# operationId: api_v1_environments_integrations_webhook_list
export def "environments-integrations-webhook list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, url: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/webhook/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/integrations/webhook/
#
# operationId: api_v1_environments_integrations_webhook_create
export def "environments-integrations-webhook create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  --secret: string
]: any -> record<id: int, url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/webhook/")
  let body = {url: $body_url, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/integrations/webhook/{id}/
#
# operationId: api_v1_environments_integrations_webhook_retrieve
export def "environments-integrations-webhook get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, url: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/webhook/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/integrations/webhook/{id}/
#
# operationId: api_v1_environments_integrations_webhook_update
export def "environments-integrations-webhook update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  --secret: string
]: any -> record<id: int, url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/webhook/($id)/")
  let body = {url: $body_url, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/integrations/webhook/{id}/
#
# operationId: api_v1_environments_integrations_webhook_partial_update
export def "environments-integrations-webhook patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  --secret: string
]: any -> record<id: int, url: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/webhook/($id)/")
  let body = {url: $body_url, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/integrations/webhook/{id}/
#
# operationId: api_v1_environments_integrations_webhook_destroy
export def "environments-integrations-webhook delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/integrations/webhook/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all change requests for an environment.
#
# GET /api/v1/environments/{environment_api_key}/list-change-requests/
# operationId: list_environment_change_requests
export def "environments-list-change-requests requests" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --committed: oneof<nothing, bool> # Filter on the committed status of a change request.
  --feature-id: int # Filter for a particular feature.
  --live-from-after: string # Filter change requests due to go live after this datetime. (format: date-time)
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # Fuzzy search across Change Request titles.
  --segment-id: int # Filter change requests which match a specific segment id.
]: nothing -> record<id: int, created_at: string, updated_at: string, title: string, description: string, user: int, committed_at: string, committed_by: int, deleted_at: string, live_from: string, environment_feature_versions: list<string>, ignore_conflicts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "committed" $committed "scalar") (serialize-qp "feature_id" $feature_id "scalar") (serialize-qp "live_from_after" $live_from_after "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "segment_id" $segment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/list-change-requests/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metrics for this environment.
#
# GET /api/v1/environments/{environment_api_key}/metrics/
# operationId: api_v1_environments_metrics_list
export def "environments-metrics list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<metrics: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/metrics/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/user-group-permissions/
#
# operationId: api_v1_environments_user_group_permissions_list
export def "environments-user-group-permissions list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, permissions: list<string>, admin: bool, group: record<id: int, name: string, users: list, is_default: bool, external_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-group-permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/user-group-permissions/
#
# operationId: api_v1_environments_user_group_permissions_create
export def "environments-user-group-permissions create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  group: int
]: any -> record<id: int, permissions: list<string>, admin: bool, group: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-group-permissions/")
  let body = {permissions: $permissions, admin: $admin, group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/user-group-permissions/{id}/
#
# operationId: api_v1_environments_user_group_permissions_retrieve
export def "environments-user-group-permissions get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, permissions: list<string>, admin: bool, group: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-group-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/user-group-permissions/{id}/
#
# operationId: api_v1_environments_user_group_permissions_update
export def "environments-user-group-permissions update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  group: int
]: any -> record<id: int, permissions: list<string>, admin: bool, group: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-group-permissions/($id)/")
  let body = {permissions: $permissions, admin: $admin, group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/user-group-permissions/{id}/
#
# operationId: api_v1_environments_user_group_permissions_partial_update
export def "environments-user-group-permissions patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  --group: int
]: any -> record<id: int, permissions: list<string>, admin: bool, group: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-group-permissions/($id)/")
  let body = {permissions: $permissions, admin: $admin, group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/user-group-permissions/{id}/
#
# operationId: api_v1_environments_user_group_permissions_destroy
export def "environments-user-group-permissions delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-group-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/{environment_api_key}/user-permissions/
#
# operationId: api_v1_environments_user_permissions_list
export def "environments-user-permissions list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, permissions: list<string>, admin: bool, user: record<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/environments/{environment_api_key}/user-permissions/
#
# operationId: api_v1_environments_user_permissions_create
export def "environments-user-permissions create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  user: int
]: any -> record<id: int, permissions: list<string>, admin: bool, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-permissions/")
  let body = {permissions: $permissions, admin: $admin, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/environments/{environment_api_key}/user-permissions/{id}/
#
# operationId: api_v1_environments_user_permissions_retrieve
export def "environments-user-permissions get" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, permissions: list<string>, admin: bool, user: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/environments/{environment_api_key}/user-permissions/{id}/
#
# operationId: api_v1_environments_user_permissions_update
export def "environments-user-permissions update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  user: int
]: any -> record<id: int, permissions: list<string>, admin: bool, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-permissions/($id)/")
  let body = {permissions: $permissions, admin: $admin, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_api_key}/user-permissions/{id}/
#
# operationId: api_v1_environments_user_permissions_partial_update
export def "environments-user-permissions patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  --user: int
]: any -> record<id: int, permissions: list<string>, admin: bool, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-permissions/($id)/")
  let body = {permissions: $permissions, admin: $admin, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_api_key}/user-permissions/{id}/
#
# operationId: api_v1_environments_user_permissions_destroy
export def "environments-user-permissions delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/user-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# GET /api/v1/environments/{environment_api_key}/warehouse-connections/
# operationId: api_v1_environments_warehouse_connections_list
export def "environments-warehouse-connections list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, warehouse_type: string, status: record, name: string, config: any, created_at: string, total_events_received: int, unique_events_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/warehouse-connections/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/warehouse-connections/
# operationId: api_v1_environments_warehouse_connections_create
export def "environments-warehouse-connections create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  warehouse_type: string@warehouse-type-completer # * `flagsmith` - Flagsmith * `snowflake` - Snowflake * `clickhouse` - ClickHouse
  --name: string
  --config: any
]: any -> record<id: int, warehouse_type: string, status: record, name: string, config: any, created_at: string, total_events_received: int, unique_events_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/warehouse-connections/")
  let body = {warehouse_type: $warehouse_type, name: $name, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# GET /api/v1/environments/{environment_api_key}/warehouse-connections/{connection_id}/
# operationId: api_v1_environments_warehouse_connections_retrieve
export def "environments-warehouse-connections get" [
  connection_id: int
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, warehouse_type: string, status: record, name: string, config: any, created_at: string, total_events_received: int, unique_events_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/warehouse-connections/($connection_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PUT /api/v1/environments/{environment_api_key}/warehouse-connections/{connection_id}/
# operationId: api_v1_environments_warehouse_connections_update
export def "environments-warehouse-connections update" [
  connection_id: int
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  warehouse_type: string@warehouse-type-completer # * `flagsmith` - Flagsmith * `snowflake` - Snowflake * `clickhouse` - ClickHouse
  --name: string
  --config: any
]: any -> record<id: int, warehouse_type: string, status: record, name: string, config: any, created_at: string, total_events_received: int, unique_events_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/warehouse-connections/($connection_id)/")
  let body = {warehouse_type: $warehouse_type, name: $name, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PATCH /api/v1/environments/{environment_api_key}/warehouse-connections/{connection_id}/
# operationId: api_v1_environments_warehouse_connections_partial_update
export def "environments-warehouse-connections patch" [
  connection_id: int
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --warehouse-type: string@warehouse-type-completer # * `flagsmith` - Flagsmith * `snowflake` - Snowflake * `clickhouse` - ClickHouse
  --name: string
  --config: any
]: any -> record<id: int, warehouse_type: string, status: record, name: string, config: any, created_at: string, total_events_received: int, unique_events_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/warehouse-connections/($connection_id)/")
  let body = {warehouse_type: $warehouse_type, name: $name, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# DELETE /api/v1/environments/{environment_api_key}/warehouse-connections/{connection_id}/
# operationId: api_v1_environments_warehouse_connections_destroy
export def "environments-warehouse-connections delete" [
  connection_id: int
  environment_api_key: string
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/warehouse-connections/($connection_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/warehouse-connections/{connection_id}/test-warehouse-connection/
# operationId: api_v1_environments_warehouse_connections_test_warehouse_connection_create
export def "environments-warehouse-connections-test-warehouse-connection create" [
  connection_id: int
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  warehouse_type: string@warehouse-type-completer # * `flagsmith` - Flagsmith * `snowflake` - Snowflake * `clickhouse` - ClickHouse
  --name: string
  --config: any
]: any -> record<id: int, warehouse_type: string, status: record, name: string, config: any, created_at: string, total_events_received: int, unique_events_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/warehouse-connections/($connection_id)/test-warehouse-connection/")
  let body = {warehouse_type: $warehouse_type, name: $name, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# GET /api/v1/environments/{environment_api_key}/webhooks/
# operationId: api_v1_environments_webhooks_list
export def "environments-webhooks list" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, url: string, enabled: bool, created_at: string, updated_at: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/webhooks/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# POST /api/v1/environments/{environment_api_key}/webhooks/
# operationId: api_v1_environments_webhooks_create
export def "environments-webhooks create" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # format: uri
  --enabled: oneof<nothing, bool>
  --secret: string
]: any -> record<id: int, url: string, enabled: bool, created_at: string, updated_at: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/webhooks/")
  let body = {url: $body_url, enabled: $enabled, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PUT /api/v1/environments/{environment_api_key}/webhooks/{id}/
# operationId: api_v1_environments_webhooks_update
export def "environments-webhooks update" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # format: uri
  --enabled: oneof<nothing, bool>
  --secret: string
]: any -> record<id: int, url: string, enabled: bool, created_at: string, updated_at: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/webhooks/($id)/")
  let body = {url: $body_url, enabled: $enabled, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# PATCH /api/v1/environments/{environment_api_key}/webhooks/{id}/
# operationId: api_v1_environments_webhooks_partial_update
export def "environments-webhooks patch" [
  environment_api_key: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # format: uri
  --enabled: oneof<nothing, bool>
  --secret: string
]: any -> record<id: int, url: string, enabled: bool, created_at: string, updated_at: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/webhooks/($id)/")
  let body = {url: $body_url, enabled: $enabled, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abstract base class for generic types.  On Python 3.12 and newer, generic classes implicitly inherit from Generic when they declare a parameter list after the class's name::      class Mapping[KT, VT]:         def __getitem__(self, key: KT) -> VT:             ...         # Etc.  On older versions of Python, however, generic classes have to explicitly inherit from Generic.  After a class has been declared to be generic, it can then be used as follows::      def lookup_name[KT, VT](mapping: Mapping[KT, VT], key: KT, default: VT) -> VT:         try:             return mapping[key]         except KeyError:             return default
#
# DELETE /api/v1/environments/{environment_api_key}/webhooks/{id}/
# operationId: api_v1_environments_webhooks_destroy
export def "environments-webhooks delete" [
  environment_api_key: string
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_api_key)/webhooks/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves version information for a feature flag in a specific environment. Applies to environments with v2 feature versioning (use_v2_feature_versioning: true).
#
# GET /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/
# operationId: get_environment_feature_versions
export def "environments-features-versions versions" [
  environment_pk: int
  feature_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<created_at: string, updated_at: string, published: bool, live_from: string, uuid: string, is_live: bool, published_by: int, created_by: int, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new version for a feature flag in a specific environment. Applies to environments with v2 feature versioning (use_v2_feature_versioning: true).
#
# POST /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/
# operationId: create_environment_feature_version
# --feature_states_to_create item shape: {enabled?: bool, feature_state_value: record, feature_segment?: any, multivariate_feature_state_values?: list}
# --feature_states_to_update item shape: {enabled?: bool, feature_state_value: record, feature_segment?: any, multivariate_feature_state_values?: list}
export def "environments-features-versions version" [
  environment_pk: int
  feature_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --live-from: string # nullable, format: date-time
  --description: string # nullable
  --feature-states-to-create: list # Array of feature states that will be created in the new version. Note: these can only include segment overrides. (nullable) — item shape: {enabled?: bool, feature_state_value: record, feature_segment?: any, multivariate_feature_state_values?: list}
  --feature-states-to-update: list # Array of feature states to update in the new version. (nullable) — item shape: {enabled?: bool, feature_state_value: record, feature_segment?: any, multivariate_feature_state_values?: list}
  --segment-ids-to-delete-overrides: list # List of segment ids for which the segment overrides will be removed in the new version. (nullable)
  --publish-immediately: oneof<nothing, bool> # Boolean to confirm whether the new version should be publish immediately or not. (default: false)
]: any -> record<created_at: string, updated_at: string, published: bool, live_from: string, uuid: string, is_live: bool, published_by: int, created_by: int, description: string, feature_states_to_create: table<id: int, feature: int, enabled: bool, feature_state_value: record, feature_segment: any, deleted_at: string, uuid: string, created_at: string, updated_at: string, live_from: string, environment: int, identity: int, change_request: int, multivariate_feature_state_values: list>, feature_states_to_update: table<id: int, feature: int, enabled: bool, feature_state_value: record, feature_segment: any, deleted_at: string, uuid: string, created_at: string, updated_at: string, live_from: string, environment: int, identity: int, change_request: int, multivariate_feature_state_values: list>, segment_ids_to_delete_overrides: list<int>, publish_immediately: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/")
  let body = {live_from: $live_from, description: $description, feature_states_to_create: $feature_states_to_create, feature_states_to_update: $feature_states_to_update, segment_ids_to_delete_overrides: $segment_ids_to_delete_overrides, publish_immediately: $publish_immediately} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves feature state information for a specific version in an environment. Applies to environments with v2 feature versioning (use_v2_feature_versioning: true).
#
# GET /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/{environment_feature_version_pk}/featurestates/
# operationId: get_environment_feature_version_states
export def "environments-features-versions-featurestates states" [
  environment_feature_version_pk: string
  environment_pk: int
  feature_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, feature: int, enabled: bool, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, feature_segment: any, deleted_at: string, uuid: string, created_at: string, updated_at: string, live_from: string, environment: int, identity: int, change_request: int, multivariate_feature_state_values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/($environment_feature_version_pk)/featurestates/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new feature state for a specific version in an environment. Applies to environments with v2 feature versioning (use_v2_feature_versioning: true).
#
# POST /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/{environment_feature_version_pk}/featurestates/
# operationId: create_environment_feature_version_state
# --feature_state_value shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-features-versions-featurestates state-by-environment_feature_version_pk-environment_pk-feature_pk" [
  environment_feature_version_pk: string
  environment_pk: int
  feature_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  feature_state_value: record # shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
  --feature-segment: any
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
]: any -> record<id: int, feature: int, enabled: bool, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, feature_segment: any, deleted_at: string, uuid: string, created_at: string, updated_at: string, live_from: string, environment: int, identity: int, change_request: int, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/($environment_feature_version_pk)/featurestates/")
  let body = {enabled: $enabled, feature_state_value: $feature_state_value, feature_segment: $feature_segment, multivariate_feature_state_values: $multivariate_feature_state_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing feature state for a specific version in an environment. Applies to environments with v2 feature versioning (use_v2_feature_versioning: true).
#
# PUT /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/{environment_feature_version_pk}/featurestates/{id}/
# operationId: update_environment_feature_version_state
# --feature_state_value shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-features-versions-featurestates state-by-environment_feature_version_pk-environment_pk-feature_pk-id" [
  environment_feature_version_pk: string
  environment_pk: int
  feature_pk: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  feature_state_value: record # shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
  --feature-segment: any
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
]: any -> record<id: int, feature: int, enabled: bool, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, feature_segment: any, deleted_at: string, uuid: string, created_at: string, updated_at: string, live_from: string, environment: int, identity: int, change_request: int, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/($environment_feature_version_pk)/featurestates/($id)/")
  let body = {enabled: $enabled, feature_state_value: $feature_state_value, feature_segment: $feature_segment, multivariate_feature_state_values: $multivariate_feature_state_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/{environment_feature_version_pk}/featurestates/{id}/
#
# operationId: api_v1_environments_features_versions_featurestates_partial_update
# --feature_state_value shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-features-versions-featurestates patch" [
  environment_feature_version_pk: string
  environment_pk: int
  feature_pk: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --feature-state-value: record # shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
  --feature-segment: any
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
]: any -> record<id: int, feature: int, enabled: bool, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, feature_segment: any, deleted_at: string, uuid: string, created_at: string, updated_at: string, live_from: string, environment: int, identity: int, change_request: int, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/($environment_feature_version_pk)/featurestates/($id)/")
  let body = {enabled: $enabled, feature_state_value: $feature_state_value, feature_segment: $feature_segment, multivariate_feature_state_values: $multivariate_feature_state_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/{environment_feature_version_pk}/featurestates/{id}/
#
# operationId: api_v1_environments_features_versions_featurestates_destroy
export def "environments-features-versions-featurestates delete" [
  environment_feature_version_pk: string
  environment_pk: int
  feature_pk: int
  id: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/($environment_feature_version_pk)/featurestates/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/{id}/
#
# operationId: api_v1_environments_features_versions_destroy
export def "environments-features-versions delete" [
  environment_pk: int
  feature_pk: int
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
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publishes a feature version to make it live in the environment. Applies to environments with v2 feature versioning (use_v2_feature_versioning: true).
#
# POST /api/v1/environments/{environment_pk}/features/{feature_pk}/versions/{id}/publish/
# operationId: publish_environment_feature_version
export def "environments-features-versions-publish version" [
  environment_pk: int
  feature_pk: int
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --live-from: string # format: date-time
]: any -> record<live_from: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/($environment_pk)/features/($feature_pk)/versions/($id)/publish/")
  let body = {live_from: $live_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/environments/environments/{environment_api_key}/edge-identities-featurestates
#
# operationId: api_v1_environments_environments_edge_identities_featurestates_update
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "environments-environments-edge-identities-featurestates update" [
  environment_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-state-value: string # Feature state value (string, integer, or boolean) (nullable)
  feature: any # Feature identifier (ID or name)
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --enabled: oneof<nothing, bool> # default: false
  identifier: string
]: any -> record<feature_state_value: string, feature: int, multivariate_feature_state_values: table<multivariate_feature_option: int, percentage_allocation: float>, enabled: bool, featurestate_uuid: string, identity_uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/environments/($environment_api_key)/edge-identities-featurestates")
  let body = {feature_state_value: $feature_state_value, feature: $feature, multivariate_feature_state_values: $multivariate_feature_state_values, enabled: $enabled, identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/environments/environments/{environment_api_key}/edge-identities-featurestates
#
# operationId: api_v1_environments_environments_edge_identities_featurestates_destroy
export def "environments-environments-edge-identities-featurestates delete" [
  environment_api_key: string
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
  let full_url = (build-url $base $"/api/v1/environments/environments/($environment_api_key)/edge-identities-featurestates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/get-by-uuid/{uuid}/
#
# operationId: api_v1_environments_get_by_uuid_retrieve
export def "environments-get-by-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool, metadata: table<id: int, model_field: int, field_value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/environments/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/environments/permissions/
#
# operationId: api_v1_environments_permissions_list
export def "environments-permissions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, description: string, supports_tag: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/environments/permissions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/feature-health/{path}
#
# operationId: api_v1_feature_health_create
export def "feature-health create" [
  path: string
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
  let full_url = (build-url $base $"/api/v1/feature-health/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/features/create-feature-export/
#
# operationId: api_v1_features_create_feature_export_create
export def "features-create-feature-export create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment_id: int
  tag_ids: list
]: any -> record<id: int, name: string, environment_id: int, status: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/features/create-feature-export/")
  let body = {environment_id: $environment_id, tag_ids: $tag_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This endpoint is to download a feature export file from a specific environment
#
# GET /api/v1/features/download-feature-export/{feature_export_id}/
# operationId: api_v1_features_download_feature_export_retrieve
export def "features-download-feature-export get" [
  feature_export_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/download-feature-export/($feature_export_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This endpoint is to download a feature export to enable Flagsmith on Flagsmith
#
# GET /api/v1/features/download-flagsmith-on-flagsmith/
# operationId: api_v1_features_download_flagsmith_on_flagsmith_retrieve
export def "features-download-flagsmith-on-flagsmith get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/features/download-flagsmith-on-flagsmith/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/features/feature-import/{environment_id}
#
# operationId: api_v1_features_feature_import_create
export def "features-feature-import create" [
  environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: uri
  strategy: string@strategy-completer # * `SKIP` - SKIP * `OVERWRITE_DESTRUCTIVE` - OVERWRITE_DESTRUCTIVE
]: any -> record<id: int, environment_id: int, strategy: string, status: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/feature-import/($environment_id)")
  let body = {file: $file, strategy: $strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists segment overrides for a feature in an environment.
#
# GET /api/v1/features/feature-segments/
# operationId: list_feature_segments
export def "features-feature-segments segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: int
  --feature: int
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, uuid: string, segment: int, priority: int, environment: int, segment_name: string, is_feature_specific: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar") (serialize-qp "feature" $feature "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/features/feature-segments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/features/feature-segments/
#
# operationId: api_v1_features_feature_segments_create
export def "features-feature-segments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: int
  segment: int
  environment: int
]: any -> record<id: int, uuid: string, feature: int, segment: int, environment: int, priority: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/features/feature-segments/")
  let body = {feature: $feature, segment: $segment, environment: $environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/features/feature-segments/{id}/
#
# operationId: api_v1_features_feature_segments_retrieve
export def "features-feature-segments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, segment: int, priority: int, environment: int, segment_name: string, is_feature_specific: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/feature-segments/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/features/feature-segments/{id}/
#
# operationId: api_v1_features_feature_segments_update
export def "features-feature-segments update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: int
  segment: int
  environment: int
]: any -> record<id: int, uuid: string, feature: int, segment: int, environment: int, priority: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/feature-segments/($id)/")
  let body = {feature: $feature, segment: $segment, environment: $environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/features/feature-segments/{id}/
#
# operationId: api_v1_features_feature_segments_partial_update
export def "features-feature-segments patch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: int
  --segment: int
  --environment: int
]: any -> record<id: int, uuid: string, feature: int, segment: int, environment: int, priority: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/feature-segments/($id)/")
  let body = {feature: $feature, segment: $segment, environment: $environment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a segment override. Applies to environments without v2 feature versioning (use_v2_feature_versioning: false).
#
# DELETE /api/v1/features/feature-segments/{id}/
# operationId: delete_feature_segment
export def "features-feature-segments segment" [
  id: int
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
  let full_url = (build-url $base $"/api/v1/features/feature-segments/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/features/feature-segments/get-by-uuid/{uuid}/
#
# operationId: api_v1_features_feature_segments_get_by_uuid_retrieve
export def "features-feature-segments-get-by-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, segment: int, priority: int, environment: int, segment_name: string, is_feature_specific: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/feature-segments/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/features/feature-segments/update-priorities/
#
# operationId: api_v1_features_feature_segments_update_priorities_create
export def "features-feature-segments-update-priorities create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
  --body: record
]: any -> record<count: int, next: string, previous: string, results: table<id: int, uuid: string, segment: int, priority: int, environment: int, segment_name: string, is_feature_specific: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/features/feature-segments/update-priorities/" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/features/featurestates/
#
# operationId: api_v1_features_featurestates_list
export def "features-featurestates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: int # ID of the environment.
  --feature: int
  --feature-segment: int
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, feature_state_value: record, multivariate_feature_state_values: list, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar") (serialize-qp "feature" $feature "scalar") (serialize-qp "feature_segment" $feature_segment "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/features/featurestates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/features/featurestates/
#
# operationId: api_v1_features_featurestates_create
# --feature_state_value shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "features-featurestates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-state-value: record # shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --identifier: string # Can be passed as an alternative to `identity`
  --enabled: oneof<nothing, bool>
  --live-from: string # nullable, format: date-time
  feature: int
  --environment: int # nullable
  --identity: int # nullable
  --feature-segment: int # nullable
  --change-request: int # nullable
  --environment-feature-version: string # nullable, format: uuid
]: any -> record<id: int, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/features/featurestates/")
  let body = {feature_state_value: $feature_state_value, multivariate_feature_state_values: $multivariate_feature_state_values, identifier: $identifier, enabled: $enabled, live_from: $live_from, feature: $feature, environment: $environment, identity: $identity, feature_segment: $feature_segment, change_request: $change_request, environment_feature_version: $environment_feature_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a feature state, including its enabled status and value. Also updates a segment override's value for environments without v2 feature versioning (use_v2_feature_versioning: false).
#
# PUT /api/v1/features/featurestates/{id}/
# operationId: update_feature_state
# --feature_state_value shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "features-featurestates state" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-state-value: record # shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --identifier: string # Can be passed as an alternative to `identity`
  --enabled: oneof<nothing, bool>
  --live-from: string # nullable, format: date-time
  feature: int
  --environment: int # nullable
  --identity: int # nullable
  --feature-segment: int # nullable
  --change-request: int # nullable
  --environment-feature-version: string # nullable, format: uuid
]: any -> record<id: int, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/featurestates/($id)/")
  let body = {feature_state_value: $feature_state_value, multivariate_feature_state_values: $multivariate_feature_state_values, identifier: $identifier, enabled: $enabled, live_from: $live_from, feature: $feature, environment: $environment, identity: $identity, feature_segment: $feature_segment, change_request: $change_request, environment_feature_version: $environment_feature_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/features/featurestates/{id}/
#
# operationId: api_v1_features_featurestates_partial_update
# --feature_state_value shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
# --multivariate_feature_state_values item shape: {multivariate_feature_option: int, percentage_allocation: float}
export def "features-featurestates patch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature-state-value: record # shape: {type?: any, string_value?: string, integer_value?: int, boolean_value?: bool}
  --multivariate-feature-state-values: list # item shape: {multivariate_feature_option: int, percentage_allocation: float}
  --identifier: string # Can be passed as an alternative to `identity`
  --enabled: oneof<nothing, bool>
  --live-from: string # nullable, format: date-time
  --feature: int
  --environment: int # nullable
  --identity: int # nullable
  --feature-segment: int # nullable
  --change-request: int # nullable
  --environment-feature-version: string # nullable, format: uuid
]: any -> record<id: int, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/featurestates/($id)/")
  let body = {feature_state_value: $feature_state_value, multivariate_feature_state_values: $multivariate_feature_state_values, identifier: $identifier, enabled: $enabled, live_from: $live_from, feature: $feature, environment: $environment, identity: $identity, feature_segment: $feature_segment, change_request: $change_request, environment_feature_version: $environment_feature_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/features/featurestates/get-by-uuid/{uuid}/
#
# operationId: api_v1_features_featurestates_get_by_uuid_retrieve
export def "features-featurestates-get-by-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, feature_state_value: record<type: any, string_value: string, integer_value: int, boolean_value: bool>, multivariate_feature_state_values: table<id: int, multivariate_feature_option: int, percentage_allocation: float>, identifier: string, deleted_at: string, uuid: string, enabled: bool, created_at: string, updated_at: string, live_from: string, version: int, feature: int, environment: int, identity: int, feature_segment: int, change_request: int, environment_feature_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/featurestates/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/features/get-by-uuid/{uuid}/
#
# operationId: api_v1_features_get_by_uuid_retrieve
export def "features-get-by-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, type: any, default_enabled: bool, initial_value: string, created_date: string, description: string, tags: list<int>, multivariate_options: table<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string>, is_archived: bool, owners: list<int>, group_owners: list<int>, uuid: string, project: int, environment_feature_state: any, segment_feature_state: any, num_segment_overrides: int, num_identity_overrides: int, is_num_identity_overrides_complete: bool, is_server_key_only: bool, last_modified_in_any_environment: string, last_modified_in_current_environment: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/features/workflows/change-requests/{id}/
#
# operationId: api_v1_features_workflows_change_requests_retrieve
export def "features-workflows-change-requests get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_at: string, updated_at: string, environment: int, title: string, description: string, feature_states: table<id: int, feature: int, feature_segment: int, enabled: bool, feature_state_value: record, multivariate_feature_state_values: list, live_from: string>, user: int, committed_at: string, committed_by: int, deleted_at: string, approvals: table<id: int, user: int, approved_at: string>, is_approved: string, is_committed: string, group_assignments: table<group: int>, environment_feature_versions: table<uuid: string, feature_states: list, live_from: string>, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, conflicts: table<original_cr_id: int, segment_id: int, is_environment_default: bool, published_at: string>, ignore_conflicts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/workflows/change-requests/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/features/workflows/change-requests/{id}/
#
# operationId: api_v1_features_workflows_change_requests_update
# --feature_states item shape: {feature: int, feature_segment?: int, enabled?: bool, feature_state_value?: record, multivariate_feature_state_values?: list, live_from?: string}
# --approvals item shape: {user: int}
# --group_assignments item shape: {group: int}
# --change_sets item shape: {feature: int, live_from?: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list}
export def "features-workflows-change-requests update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  --description: string # nullable
  feature_states: list # item shape: {feature: int, feature_segment?: int, enabled?: bool, feature_state_value?: record, multivariate_feature_state_values?: list, live_from?: string}
  --approvals: list # item shape: {user: int}
  --group-assignments: list # item shape: {group: int}
  --environment-feature-versions: list
  --change-sets: list # nullable — item shape: {feature: int, live_from?: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list}
  --ignore-conflicts: oneof<nothing, bool>
]: any -> record<id: int, created_at: string, updated_at: string, title: string, description: string, feature_states: table<id: int, feature: int, feature_segment: int, enabled: bool, feature_state_value: record, multivariate_feature_state_values: list, live_from: string>, deleted_at: string, environment: int, committed_at: string, approvals: table<id: int, user: int, approved_at: string>, user: int, committed_by: int, group_assignments: table<group: int>, environment_feature_versions: list<string>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, ignore_conflicts: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/workflows/change-requests/($id)/")
  let body = {title: $title, description: $description, feature_states: $feature_states, approvals: $approvals, group_assignments: $group_assignments, environment_feature_versions: $environment_feature_versions, change_sets: $change_sets, ignore_conflicts: $ignore_conflicts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/features/workflows/change-requests/{id}/
#
# operationId: api_v1_features_workflows_change_requests_partial_update
# --feature_states item shape: {feature: int, feature_segment?: int, enabled?: bool, feature_state_value?: record, multivariate_feature_state_values?: list, live_from?: string}
# --approvals item shape: {user: int}
# --group_assignments item shape: {group: int}
# --change_sets item shape: {feature: int, live_from?: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list}
export def "features-workflows-change-requests patch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string
  --description: string # nullable
  --feature-states: list # item shape: {feature: int, feature_segment?: int, enabled?: bool, feature_state_value?: record, multivariate_feature_state_values?: list, live_from?: string}
  --approvals: list # item shape: {user: int}
  --group-assignments: list # item shape: {group: int}
  --environment-feature-versions: list
  --change-sets: list # nullable — item shape: {feature: int, live_from?: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list}
  --ignore-conflicts: oneof<nothing, bool>
]: any -> record<id: int, created_at: string, updated_at: string, title: string, description: string, feature_states: table<id: int, feature: int, feature_segment: int, enabled: bool, feature_state_value: record, multivariate_feature_state_values: list, live_from: string>, deleted_at: string, environment: int, committed_at: string, approvals: table<id: int, user: int, approved_at: string>, user: int, committed_by: int, group_assignments: table<group: int>, environment_feature_versions: list<string>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, ignore_conflicts: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/workflows/change-requests/($id)/")
  let body = {title: $title, description: $description, feature_states: $feature_states, approvals: $approvals, group_assignments: $group_assignments, environment_feature_versions: $environment_feature_versions, change_sets: $change_sets, ignore_conflicts: $ignore_conflicts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/features/workflows/change-requests/{id}/
#
# operationId: api_v1_features_workflows_change_requests_destroy
export def "features-workflows-change-requests delete" [
  id: int
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
  let full_url = (build-url $base $"/api/v1/features/workflows/change-requests/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/features/workflows/change-requests/{id}/approve/
#
# operationId: api_v1_features_workflows_change_requests_approve_create
export def "features-workflows-change-requests-approve create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_at: string, updated_at: string, environment: int, title: string, description: string, feature_states: table<id: int, feature: int, feature_segment: int, enabled: bool, feature_state_value: record, multivariate_feature_state_values: list, live_from: string>, user: int, committed_at: string, committed_by: int, deleted_at: string, approvals: table<id: int, user: int, approved_at: string>, is_approved: string, is_committed: string, group_assignments: table<group: int>, environment_feature_versions: table<uuid: string, feature_states: list, live_from: string>, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, conflicts: table<original_cr_id: int, segment_id: int, is_environment_default: bool, published_at: string>, ignore_conflicts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/workflows/change-requests/($id)/approve/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/features/workflows/change-requests/{id}/commit/
#
# operationId: api_v1_features_workflows_change_requests_commit_create
export def "features-workflows-change-requests-commit create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_at: string, updated_at: string, environment: int, title: string, description: string, feature_states: table<id: int, feature: int, feature_segment: int, enabled: bool, feature_state_value: record, multivariate_feature_state_values: list, live_from: string>, user: int, committed_at: string, committed_by: int, deleted_at: string, approvals: table<id: int, user: int, approved_at: string>, is_approved: string, is_committed: string, group_assignments: table<group: int>, environment_feature_versions: table<uuid: string, feature_states: list, live_from: string>, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, conflicts: table<original_cr_id: int, segment_id: int, is_environment_default: bool, published_at: string>, ignore_conflicts: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/features/workflows/change-requests/($id)/commit/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the flags for an environment.  --- *Note*: when providing the `feature` query argument, this endpoint will return either a single object or a 404 (if the feature does not exist) rather than a list.  --- *Note*: using this endpoint with an identifier is deprecated. Please use `/api/v1/identities/?identifier=<identifier>` instead.
#
# GET /api/v1/flags/
# operationId: sdk_v1_flags
export def "flags flags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: string # Name of the feature to get the state of
]: nothing -> table<feature: record<id: int, name: string, type: string>, enabled: bool, feature_state_value: any> {
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feature" $feature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/flags/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/flags/{feature_id}/multivariate-options/
#
# operationId: api_v1_flags_multivariate_options_list
export def "flags-multivariate-options list" [
  feature_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<control_value: any, options: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/flags/($feature_id)/multivariate-options/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the flags for an environment.  --- *Note*: when providing the `feature` query argument, this endpoint will return either a single object or a 404 (if the feature does not exist) rather than a list.  --- *Note*: using this endpoint with an identifier is deprecated. Please use `/api/v1/identities/?identifier=<identifier>` instead.
#
# GET /api/v1/flags/{identifier}
# operationId: sdk_v1_flags_2
export def "flags flags-by-identifier" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feature: string # Name of the feature to get the state of
]: nothing -> table<feature: record<id: int, name: string, type: string>, enabled: bool, feature_state_value: any> {
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feature" $feature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/flags/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/github-webhook/
#
# operationId: api_v1_github_webhook_create
export def "github-webhook create" [
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
  let full_url = (build-url $base "/api/v1/github-webhook/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/gitlab-webhook/{webhook_uuid}/
#
# operationId: api_v1_gitlab_webhook_create
export def "gitlab-webhook create" [
  webhook_uuid: string
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
  let full_url = (build-url $base $"/api/v1/gitlab-webhook/($webhook_uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the flags and traits for an identity.
#
# GET /api/v1/identities/
# operationId: sdk_v1_get_identities
export def "identities identities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifier: string
  --transient: oneof<nothing, bool> # default: false
]: nothing -> record<identifier: string, flags: table<feature: record, enabled: bool, feature_state_value: any>, traits: table<trait_key: string, trait_value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifier" $identifier "scalar") (serialize-qp "transient" $transient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/identities/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Identify a user, set their traits, and retrieve their flags.
#
# POST /api/v1/identities/
# operationId: sdk_v1_post_identities
export def "identities identities-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identifier: string
  --traits: any
  --transient: any
]: any -> record<identifier: string, flags: table<feature: record, enabled: bool, feature_state_value: any>, traits: table<trait_key: string, trait_value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/identities/")
  let body = {identifier: $identifier, traits: $traits, transient: $transient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/metadata/fields/
#
# operationId: api_v1_metadata_fields_list
export def "metadata-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organisation: int # Organisation ID to filter by
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, type: string, description: string, organisation: int, project: int, model_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organisation" $organisation "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/metadata/fields/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/metadata/fields/
#
# operationId: api_v1_metadata_fields_create
# --model_fields item shape: {content_type: int}
export def "metadata-fields create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --type: string@type-completer # * `int` - Integer * `str` - String * `bool` - Boolean * `url` - Url * `multiline_str` - Multiline String
  --description: string # nullable
  organisation: int
  --project: int # nullable
]: any -> record<id: int, name: string, type: string, description: string, organisation: int, project: int, model_fields: table<id: int, content_type: int, is_required_for: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/metadata/fields/")
  let body = {name: $name, type: $type, description: $description, organisation: $organisation, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/metadata/fields/{id}/
#
# operationId: api_v1_metadata_fields_retrieve
export def "metadata-fields get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, type: string, description: string, organisation: int, project: int, model_fields: table<id: int, content_type: int, is_required_for: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/metadata/fields/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/metadata/fields/{id}/
#
# operationId: api_v1_metadata_fields_update
# --model_fields item shape: {content_type: int}
export def "metadata-fields update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --type: string@type-completer # * `int` - Integer * `str` - String * `bool` - Boolean * `url` - Url * `multiline_str` - Multiline String
  --description: string # nullable
  organisation: int
  --project: int # nullable
]: any -> record<id: int, name: string, type: string, description: string, organisation: int, project: int, model_fields: table<id: int, content_type: int, is_required_for: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/metadata/fields/($id)/")
  let body = {name: $name, type: $type, description: $description, organisation: $organisation, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/metadata/fields/{id}/
#
# operationId: api_v1_metadata_fields_partial_update
# --model_fields item shape: {content_type: int}
export def "metadata-fields patch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --type: string@type-completer # * `int` - Integer * `str` - String * `bool` - Boolean * `url` - Url * `multiline_str` - Multiline String
  --description: string # nullable
  --organisation: int
  --project: int # nullable
]: any -> record<id: int, name: string, type: string, description: string, organisation: int, project: int, model_fields: table<id: int, content_type: int, is_required_for: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/metadata/fields/($id)/")
  let body = {name: $name, type: $type, description: $description, organisation: $organisation, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/metadata/fields/{id}/
#
# operationId: api_v1_metadata_fields_destroy
export def "metadata-fields delete" [
  id: int
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
  let full_url = (build-url $base $"/api/v1/metadata/fields/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/multivariate/options/get-by-uuid/{uuid}/
#
# operationId: api_v1_multivariate_options_get_by_uuid_retrieve
export def "multivariate-options-get-by-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string, feature: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/multivariate/options/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate an authorisation request and return application info.
#
# GET /api/v1/oauth/authorize/
# operationId: api_v1_oauth_authorize_retrieve
export def "oauth-authorize get" [
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
  let full_url = (build-url $base "/api/v1/oauth/authorize/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Process a consent decision and return the redirect URI.
#
# POST /api/v1/oauth/authorize/
# operationId: api_v1_oauth_authorize_create
export def "oauth-authorize create" [
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
  let full_url = (build-url $base "/api/v1/oauth/authorize/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/onboarding/request/receive/
#
# operationId: api_v1_onboarding_request_receive_create
export def "onboarding-request-receive create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  first_name: string
  last_name: string
  email: string # format: email
  --hubspot-cookie: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/onboarding/request/receive/")
  let body = {first_name: $first_name, last_name: $last_name, email: $email, hubspot_cookie: $hubspot_cookie} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all organisations accessible with the provided user API key.
#
# GET /api/v1/organisations/
# operationId: list_organizations
export def "organisations organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/organisations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Override create method to add new organisation to authenticated user
#
# POST /api/v1/organisations/
# operationId: api_v1_organisations_create
# --subscription shape: {subscription_id?: string, subscription_date?: string, plan?: string, max_seats?: int, max_api_calls?: int, cancellation_date?: string, customer_id?: string, billing_status?: any, payment_method?: any, notes?: string}
export def "organisations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --webhook-notification-email: string # nullable, format: email
  --subscription: record # shape: {subscription_id?: string, subscription_date?: string, plan?: string, max_seats?: int, max_api_calls?: int, cancellation_date?: string, customer_id?: string, billing_status?: any, payment_method?: any, notes?: string}
  --restrict-project-create-to-admin: oneof<nothing, bool>
  --force-2fa: oneof<nothing, bool>
]: any -> record<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record<id: int, has_active_billing_periods: bool, deleted_at: string, uuid: string, subscription_id: string, subscription_date: string, plan: string, max_seats: int, max_api_calls: int, cancellation_date: string, customer_id: string, billing_status: any, payment_method: any, notes: string>, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/organisations/")
  let body = {name: $name, webhook_notification_email: $webhook_notification_email, subscription: $subscription, restrict_project_create_to_admin: $restrict_project_create_to_admin, force_2fa: $force_2fa} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/organisations/{organisation_id}/licence
#
# operationId: api_v1_organisations_licence_update
export def "organisations-licence update" [
  organisation_id: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_id)/licence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/api-usage-notification/
#
# operationId: api_v1_organisations_api_usage_notification_list
export def "organisations-api-usage-notification list" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<organisation_id: int, percent_usage: int, notified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/api-usage-notification/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/audit/
#
# operationId: api_v1_organisations_audit_list
export def "organisations-audit list" [
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environments: list
  --is-system-event: oneof<nothing, bool>
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --project: int
  --search: string
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, created_date: string, log: string, author: record, environment: record, project: record, related_object_id: int, related_object_uuid: string, related_object_type: string, is_system_event: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environments" $environments "multi") (serialize-qp "is_system_event" $is_system_event "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/audit/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/audit/{id}/
#
# operationId: api_v1_organisations_audit_retrieve
export def "organisations-audit get" [
  id: int
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_date: string, log: string, author: record<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, environment: record<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool>, project: record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool>, related_object_id: int, related_object_uuid: string, related_object_type: string, is_system_event: bool, change_details: table<field: string, old: string, new: string>, change_type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/audit/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/github/create-cleanup-issue/
#
# operationId: api_v1_organisations_github_create_cleanup_issue_create
export def "organisations-github-create-cleanup-issue create" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/github/create-cleanup-issue/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/github/issues/
#
# operationId: api_v1_organisations_github_issues_retrieve
export def "organisations-github-issues get" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/github/issues/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/github/pulls/
#
# operationId: api_v1_organisations_github_pulls_retrieve
export def "organisations-github-pulls get" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/github/pulls/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/github/repo-contributors/
#
# operationId: api_v1_organisations_github_repo_contributors_retrieve
export def "organisations-github-repo-contributors get" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/github/repo-contributors/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/github/repositories/
#
# operationId: api_v1_organisations_github_repositories_retrieve
export def "organisations-github-repositories get" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/github/repositories/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all permission groups within the organisation.
#
# GET /api/v1/organisations/{organisation_pk}/groups/
# operationId: list_organization_groups
export def "organisations-groups groups" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, users: list, is_default: bool, external_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/groups/
#
# operationId: api_v1_organisations_groups_create
# --users item shape: {id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin?: bool}
export def "organisations-groups create" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --is-default: oneof<nothing, bool> # If set to true, all new users will be added to this group
  --external-id: string # Unique ID of the group in an external system (nullable)
]: any -> record<id: int, name: string, users: table<id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin: bool>, is_default: bool, external_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/")
  let body = {name: $name, is_default: $is_default, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/groups/{group_pk}/roles/
#
# operationId: api_v1_organisations_groups_roles_list
export def "organisations-groups-roles list" [
  group_pk: string
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, description: string, organisation: int, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($group_pk)/roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/organisations/{organisation_pk}/groups/{group_pk}/roles/{id}/
#
# operationId: api_v1_organisations_groups_roles_destroy
export def "organisations-groups-roles delete" [
  group_pk: string
  id: string
  organisation_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($group_pk)/roles/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/groups/{group_pk}/users/{user_pk}/make-admin
#
# operationId: api_v1_organisations_groups_users_make_admin_create
export def "organisations-groups-users-make-admin create" [
  group_pk: int
  organisation_pk: int
  user_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($group_pk)/users/($user_pk)/make-admin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/groups/{group_pk}/users/{user_pk}/remove-admin
#
# operationId: api_v1_organisations_groups_users_remove_admin_create
export def "organisations-groups-users-remove-admin create" [
  group_pk: int
  organisation_pk: int
  user_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($group_pk)/users/($user_pk)/remove-admin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/groups/{id}/
#
# operationId: api_v1_organisations_groups_retrieve
export def "organisations-groups get" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, users: table<id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin: bool>, is_default: bool, external_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/groups/{id}/
#
# operationId: api_v1_organisations_groups_update
# --users item shape: {id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin?: bool}
export def "organisations-groups update" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --is-default: oneof<nothing, bool> # If set to true, all new users will be added to this group
  --external-id: string # Unique ID of the group in an external system (nullable)
]: any -> record<id: int, name: string, users: table<id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin: bool>, is_default: bool, external_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($id)/")
  let body = {name: $name, is_default: $is_default, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/groups/{id}/
#
# operationId: api_v1_organisations_groups_partial_update
# --users item shape: {id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin?: bool}
export def "organisations-groups patch" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --is-default: oneof<nothing, bool> # If set to true, all new users will be added to this group
  --external-id: string # Unique ID of the group in an external system (nullable)
]: any -> record<id: int, name: string, users: table<id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin: bool>, is_default: bool, external_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($id)/")
  let body = {name: $name, is_default: $is_default, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/groups/{id}/
#
# operationId: api_v1_organisations_groups_destroy
export def "organisations-groups delete" [
  id: int
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/groups/{id}/add-users/
#
# operationId: api_v1_organisations_groups_add_users_create
export def "organisations-groups-add-users create" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list
]: any -> record<id: int, name: string, users: table<id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin: bool>, is_default: bool, external_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($id)/add-users/")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/organisations/{organisation_pk}/groups/{id}/remove-users/
#
# operationId: api_v1_organisations_groups_remove_users_create
export def "organisations-groups-remove-users create" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list
]: any -> record<id: int, name: string, users: table<id: int, email: string, first_name: string, last_name: string, last_login: string, group_admin: bool>, is_default: bool, external_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/($id)/remove-users/")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of summary group objects only for the groups a user is a member of.
#
# GET /api/v1/organisations/{organisation_pk}/groups/my-groups/
# operationId: api_v1_organisations_groups_my_groups_retrieve
export def "organisations-groups-my-groups get" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/my-groups/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of summary group objects for all groups in the organisation.
#
# GET /api/v1/organisations/{organisation_pk}/groups/summaries/
# operationId: api_v1_organisations_groups_summaries_retrieve
export def "organisations-groups-summaries get" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/groups/summaries/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/integrations/github/
#
# operationId: api_v1_organisations_integrations_github_list
export def "organisations-integrations-github list" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, installation_id: string, organisation: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/integrations/github/
#
# operationId: api_v1_organisations_integrations_github_create
export def "organisations-integrations-github create" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  installation_id: string
]: any -> record<id: int, installation_id: string, organisation: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/")
  let body = {installation_id: $installation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/integrations/github/{github_pk}/repositories/
#
# operationId: api_v1_organisations_integrations_github_repositories_list
export def "organisations-integrations-github-repositories list" [
  github_pk: string
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, github_configuration: int, project: int, repository_owner: string, repository_name: string, tagging_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($github_pk)/repositories/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/integrations/github/{github_pk}/repositories/
#
# operationId: api_v1_organisations_integrations_github_repositories_create
export def "organisations-integrations-github-repositories create" [
  github_pk: string
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project: int
  repository_owner: string
  repository_name: string
  --tagging-enabled: oneof<nothing, bool>
]: any -> record<id: int, github_configuration: int, project: int, repository_owner: string, repository_name: string, tagging_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($github_pk)/repositories/")
  let body = {project: $project, repository_owner: $repository_owner, repository_name: $repository_name, tagging_enabled: $tagging_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/integrations/github/{github_pk}/repositories/{id}/
#
# operationId: api_v1_organisations_integrations_github_repositories_retrieve
export def "organisations-integrations-github-repositories get" [
  github_pk: string
  id: int
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, github_configuration: int, project: int, repository_owner: string, repository_name: string, tagging_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($github_pk)/repositories/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/integrations/github/{github_pk}/repositories/{id}/
#
# operationId: api_v1_organisations_integrations_github_repositories_update
export def "organisations-integrations-github-repositories update" [
  github_pk: string
  id: int
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project: int
  repository_owner: string
  repository_name: string
  --tagging-enabled: oneof<nothing, bool>
]: any -> record<id: int, github_configuration: int, project: int, repository_owner: string, repository_name: string, tagging_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($github_pk)/repositories/($id)/")
  let body = {project: $project, repository_owner: $repository_owner, repository_name: $repository_name, tagging_enabled: $tagging_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/integrations/github/{github_pk}/repositories/{id}/
#
# operationId: api_v1_organisations_integrations_github_repositories_partial_update
export def "organisations-integrations-github-repositories patch" [
  github_pk: string
  id: int
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: int
  --repository-owner: string
  --repository-name: string
  --tagging-enabled: oneof<nothing, bool>
]: any -> record<id: int, github_configuration: int, project: int, repository_owner: string, repository_name: string, tagging_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($github_pk)/repositories/($id)/")
  let body = {project: $project, repository_owner: $repository_owner, repository_name: $repository_name, tagging_enabled: $tagging_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/integrations/github/{github_pk}/repositories/{id}/
#
# operationId: api_v1_organisations_integrations_github_repositories_destroy
export def "organisations-integrations-github-repositories delete" [
  github_pk: string
  id: int
  organisation_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($github_pk)/repositories/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/integrations/github/{id}/
#
# operationId: api_v1_organisations_integrations_github_retrieve
export def "organisations-integrations-github get" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, installation_id: string, organisation: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/integrations/github/{id}/
#
# operationId: api_v1_organisations_integrations_github_update
export def "organisations-integrations-github update" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  installation_id: string
]: any -> record<id: int, installation_id: string, organisation: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($id)/")
  let body = {installation_id: $installation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/integrations/github/{id}/
#
# operationId: api_v1_organisations_integrations_github_partial_update
export def "organisations-integrations-github patch" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --installation-id: string
]: any -> record<id: int, installation_id: string, organisation: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($id)/")
  let body = {installation_id: $installation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/integrations/github/{id}/
#
# operationId: api_v1_organisations_integrations_github_destroy
export def "organisations-integrations-github delete" [
  id: int
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/github/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/integrations/grafana/
#
# operationId: api_v1_organisations_integrations_grafana_list
export def "organisations-integrations-grafana list" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, base_url: string, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/grafana/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/integrations/grafana/
#
# operationId: api_v1_organisations_integrations_grafana_create
export def "organisations-integrations-grafana create" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/grafana/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/integrations/grafana/{id}/
#
# operationId: api_v1_organisations_integrations_grafana_retrieve
export def "organisations-integrations-grafana get" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, base_url: string, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/grafana/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/integrations/grafana/{id}/
#
# operationId: api_v1_organisations_integrations_grafana_update
export def "organisations-integrations-grafana update" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/grafana/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/integrations/grafana/{id}/
#
# operationId: api_v1_organisations_integrations_grafana_partial_update
export def "organisations-integrations-grafana patch" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  --api-key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/grafana/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/integrations/grafana/{id}/
#
# operationId: api_v1_organisations_integrations_grafana_destroy
export def "organisations-integrations-grafana delete" [
  id: int
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/integrations/grafana/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/invite-links/
#
# operationId: api_v1_organisations_invite_links_list
export def "organisations-invite-links list" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, hash: string, date_created: string, role: string, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/invite-links/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/invite-links/
#
# operationId: api_v1_organisations_invite_links_create
export def "organisations-invite-links create" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # * `ADMIN` - Admin * `USER` - User
  --expires-at: string # Datetime that the invite link will cease to be active. Leave blank to enable indefinitely. (nullable, format: date-time)
]: any -> record<id: int, hash: string, date_created: string, role: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/invite-links/")
  let body = {role: $role, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/invite-links/{id}/
#
# operationId: api_v1_organisations_invite_links_destroy
export def "organisations-invite-links delete" [
  id: int
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/invite-links/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all pending invitations for the organisation.
#
# GET /api/v1/organisations/{organisation_pk}/invites/
# operationId: list_organization_invites
export def "organisations-invites invites" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, email: string, date_created: string, invited_by: record, permission_groups: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/invites/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send an invitation to join the organisation with specified role and permissions.
#
# POST /api/v1/organisations/{organisation_pk}/invites/
# operationId: create_organization_invite
export def "organisations-invites invite" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
  --role: string@role-completer # * `ADMIN` - Admin * `USER` - User
  --permission-groups: list
]: any -> record<id: int, email: string, role: string, date_created: string, permission_groups: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/invites/")
  let body = {email: $email, role: $role, permission_groups: $permission_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/invites/{id}/
#
# operationId: api_v1_organisations_invites_retrieve
export def "organisations-invites get" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, email: string, date_created: string, invited_by: record<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, permission_groups: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/invites/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/organisations/{organisation_pk}/invites/{id}/
#
# operationId: api_v1_organisations_invites_destroy
export def "organisations-invites delete" [
  id: int
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/invites/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/invites/{id}/resend/
#
# operationId: api_v1_organisations_invites_resend_create
# --invited_by shape: {email: string, first_name: string, last_name: string, last_login?: string}
export def "organisations-invites-resend create" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
  invited_by: record # shape: {email: string, first_name: string, last_name: string, last_login?: string}
  --permission-groups: list
]: any -> record<id: int, email: string, date_created: string, invited_by: record<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, permission_groups: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/invites/($id)/resend/")
  let body = {email: $email, invited_by: $invited_by, permission_groups: $permission_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/master-api-keys/
#
# operationId: api_v1_organisations_master_api_keys_list
export def "organisations-master-api-keys list" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: string, prefix: string, created: string, name: string, revoked: bool, expiry_date: string, key: string, is_admin: bool, has_expired: bool, created_by: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/master-api-keys/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/master-api-keys/
#
# operationId: api_v1_organisations_master_api_keys_create
export def "organisations-master-api-keys create" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A free-form name for the API key. Need not be unique. 50 characters max.
  --revoked: oneof<nothing, bool> # If the API key is revoked, clients cannot use it anymore. (This cannot be undone.)
  --expiry-date: string # Once API key expires, clients cannot use it anymore. (nullable, format: date-time)
  --is-admin: oneof<nothing, bool> # default: true
]: any -> record<id: string, prefix: string, created: string, name: string, revoked: bool, expiry_date: string, key: string, is_admin: bool, has_expired: bool, created_by: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/master-api-keys/")
  let body = {name: $name, revoked: $revoked, expiry_date: $expiry_date, is_admin: $is_admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/master-api-keys/{api_key_prefix}/roles/
#
# operationId: api_v1_organisations_master_api_keys_roles_list
export def "organisations-master-api-keys-roles list" [
  api_key_prefix: string
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, description: string, organisation: int, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/master-api-keys/($api_key_prefix)/roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/organisations/{organisation_pk}/master-api-keys/{api_key_prefix}/roles/{id}/detach-roles-from-master-api-key/
#
# operationId: api_v1_organisations_master_api_keys_roles_detach_roles_from_master_api_key_destroy
export def "organisations-master-api-keys-roles-detach-roles-from-master-api-key delete" [
  api_key_prefix: string
  id: string
  organisation_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/master-api-keys/($api_key_prefix)/roles/($id)/detach-roles-from-master-api-key/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/master-api-keys/{prefix}/
#
# operationId: api_v1_organisations_master_api_keys_retrieve
export def "organisations-master-api-keys get" [
  organisation_pk: int
  prefix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, prefix: string, created: string, name: string, revoked: bool, expiry_date: string, key: string, is_admin: bool, has_expired: bool, created_by: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/master-api-keys/($prefix)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/master-api-keys/{prefix}/
#
# operationId: api_v1_organisations_master_api_keys_update
export def "organisations-master-api-keys update" [
  organisation_pk: int
  prefix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A free-form name for the API key. Need not be unique. 50 characters max.
  --revoked: oneof<nothing, bool> # If the API key is revoked, clients cannot use it anymore. (This cannot be undone.)
  --expiry-date: string # Once API key expires, clients cannot use it anymore. (nullable, format: date-time)
  --is-admin: oneof<nothing, bool> # default: true
]: any -> record<id: string, prefix: string, created: string, name: string, revoked: bool, expiry_date: string, key: string, is_admin: bool, has_expired: bool, created_by: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/master-api-keys/($prefix)/")
  let body = {name: $name, revoked: $revoked, expiry_date: $expiry_date, is_admin: $is_admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/master-api-keys/{prefix}/
#
# operationId: api_v1_organisations_master_api_keys_partial_update
export def "organisations-master-api-keys patch" [
  organisation_pk: int
  prefix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A free-form name for the API key. Need not be unique. 50 characters max.
  --revoked: oneof<nothing, bool> # If the API key is revoked, clients cannot use it anymore. (This cannot be undone.)
  --expiry-date: string # Once API key expires, clients cannot use it anymore. (nullable, format: date-time)
  --is-admin: oneof<nothing, bool> # default: true
]: any -> record<id: string, prefix: string, created: string, name: string, revoked: bool, expiry_date: string, key: string, is_admin: bool, has_expired: bool, created_by: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/master-api-keys/($prefix)/")
  let body = {name: $name, revoked: $revoked, expiry_date: $expiry_date, is_admin: $is_admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/master-api-keys/{prefix}/
#
# operationId: api_v1_organisations_master_api_keys_destroy
export def "organisations-master-api-keys delete" [
  organisation_pk: int
  prefix: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/master-api-keys/($prefix)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/metadata-model-fields/
#
# operationId: api_v1_organisations_metadata_model_fields_list
export def "organisations-metadata-model-fields list" [
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, field: int, content_type: int, is_required_for: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/metadata-model-fields/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/metadata-model-fields/
#
# operationId: api_v1_organisations_metadata_model_fields_create
# --is_required_for item shape: {content_type: int, object_id: int}
export def "organisations-metadata-model-fields create" [
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  field: int
  content_type: int
  --is-required-for: list # item shape: {content_type: int, object_id: int}
]: any -> record<id: int, field: int, content_type: int, is_required_for: table<content_type: int, object_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/metadata-model-fields/")
  let body = {field: $field, content_type: $content_type, is_required_for: $is_required_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/metadata-model-fields/{id}/
#
# operationId: api_v1_organisations_metadata_model_fields_retrieve
export def "organisations-metadata-model-fields get" [
  id: int
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, field: int, content_type: int, is_required_for: table<content_type: int, object_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/metadata-model-fields/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/metadata-model-fields/{id}/
#
# operationId: api_v1_organisations_metadata_model_fields_update
# --is_required_for item shape: {content_type: int, object_id: int}
export def "organisations-metadata-model-fields update" [
  id: int
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  field: int
  content_type: int
  --is-required-for: list # item shape: {content_type: int, object_id: int}
]: any -> record<id: int, field: int, content_type: int, is_required_for: table<content_type: int, object_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/metadata-model-fields/($id)/")
  let body = {field: $field, content_type: $content_type, is_required_for: $is_required_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/metadata-model-fields/{id}/
#
# operationId: api_v1_organisations_metadata_model_fields_partial_update
# --is_required_for item shape: {content_type: int, object_id: int}
export def "organisations-metadata-model-fields patch" [
  id: int
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --field: int
  --content-type: int
  --is-required-for: list # item shape: {content_type: int, object_id: int}
]: any -> record<id: int, field: int, content_type: int, is_required_for: table<content_type: int, object_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/metadata-model-fields/($id)/")
  let body = {field: $field, content_type: $content_type, is_required_for: $is_required_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/metadata-model-fields/{id}/
#
# operationId: api_v1_organisations_metadata_model_fields_destroy
export def "organisations-metadata-model-fields delete" [
  id: int
  organisation_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/metadata-model-fields/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/metadata-model-fields/supported-content-types/
#
# operationId: api_v1_organisations_metadata_model_fields_supported_content_types_list
export def "organisations-metadata-model-fields-supported-content-types list" [
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, app_label: string, model: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/metadata-model-fields/supported-content-types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/metadata-model-fields/supported-required-for-models/
#
# operationId: api_v1_organisations_metadata_model_fields_supported_required_for_models_list
export def "organisations-metadata-model-fields-supported-required-for-models list" [
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model-name: string
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, app_label: string, model: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model_name" $model_name "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/metadata-model-fields/supported-required-for-models/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all custom roles defined within the organisation.
#
# GET /api/v1/organisations/{organisation_pk}/roles/
# operationId: list_organization_roles
export def "organisations-roles roles" [
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, description: string, organisation: int, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/roles/
#
# operationId: api_v1_organisations_roles_create
export def "organisations-roles create" [
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --tags: list
]: any -> record<id: int, name: string, description: string, organisation: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/")
  let body = {name: $name, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/roles/{id}/
#
# operationId: api_v1_organisations_roles_retrieve
export def "organisations-roles get" [
  id: string
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, description: string, organisation: int, tags: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/roles/{id}/
#
# operationId: api_v1_organisations_roles_update
export def "organisations-roles update" [
  id: string
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --tags: list
]: any -> record<id: int, name: string, description: string, organisation: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($id)/")
  let body = {name: $name, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/roles/{id}/
#
# operationId: api_v1_organisations_roles_partial_update
export def "organisations-roles patch" [
  id: string
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string # nullable
  --tags: list
]: any -> record<id: int, name: string, description: string, organisation: int, tags: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($id)/")
  let body = {name: $name, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/roles/{id}/
#
# operationId: api_v1_organisations_roles_destroy
export def "organisations-roles delete" [
  id: string
  organisation_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/environments-permissions/
#
# operationId: api_v1_organisations_roles_environments_permissions_list
export def "organisations-roles-environments-permissions list" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: int # ID of the environment to filter by.
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, role: int, environment: int, permissions: list, admin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/environments-permissions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/roles/{role_pk}/environments-permissions/
#
# operationId: api_v1_organisations_roles_environments_permissions_create
# --permissions item shape: {permission_key: string, tags?: list}
export def "organisations-roles-environments-permissions create" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment: int
  permissions: list # item shape: {permission_key: string, tags?: list}
  --admin: oneof<nothing, bool>
]: any -> record<id: int, role: int, environment: int, permissions: table<permission_key: string, tags: list>, admin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/environments-permissions/")
  let body = {environment: $environment, permissions: $permissions, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/environments-permissions/{id}/
#
# operationId: api_v1_organisations_roles_environments_permissions_retrieve
export def "organisations-roles-environments-permissions get" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, role: int, environment: int, permissions: table<permission_key: string, tags: list>, admin: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/environments-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/roles/{role_pk}/environments-permissions/{id}/
#
# operationId: api_v1_organisations_roles_environments_permissions_update
# --permissions item shape: {permission_key: string, tags?: list}
export def "organisations-roles-environments-permissions update" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  environment: int
  permissions: list # item shape: {permission_key: string, tags?: list}
  --admin: oneof<nothing, bool>
]: any -> record<id: int, role: int, environment: int, permissions: table<permission_key: string, tags: list>, admin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/environments-permissions/($id)/")
  let body = {environment: $environment, permissions: $permissions, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/roles/{role_pk}/environments-permissions/{id}/
#
# operationId: api_v1_organisations_roles_environments_permissions_partial_update
# --permissions item shape: {permission_key: string, tags?: list}
export def "organisations-roles-environments-permissions patch" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: int
  --permissions: list # item shape: {permission_key: string, tags?: list}
  --admin: oneof<nothing, bool>
]: any -> record<id: int, role: int, environment: int, permissions: table<permission_key: string, tags: list>, admin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/environments-permissions/($id)/")
  let body = {environment: $environment, permissions: $permissions, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/roles/{role_pk}/environments-permissions/{id}/
#
# operationId: api_v1_organisations_roles_environments_permissions_destroy
export def "organisations-roles-environments-permissions delete" [
  id: string
  organisation_pk: string
  role_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/environments-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/groups/
#
# operationId: api_v1_organisations_roles_groups_list
export def "organisations-roles-groups list" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, group: int, role: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/roles/{role_pk}/groups/
#
# operationId: api_v1_organisations_roles_groups_create
export def "organisations-roles-groups create" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group: int
]: any -> record<id: int, group: int, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/groups/")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/groups/{id}/
#
# operationId: api_v1_organisations_roles_groups_retrieve
export def "organisations-roles-groups get" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, group: int, role: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/groups/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/roles/{role_pk}/groups/{id}/
#
# operationId: api_v1_organisations_roles_groups_update
export def "organisations-roles-groups update" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group: int
]: any -> record<id: int, group: int, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/groups/($id)/")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/roles/{role_pk}/groups/{id}/
#
# operationId: api_v1_organisations_roles_groups_partial_update
export def "organisations-roles-groups patch" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: int
]: any -> record<id: int, group: int, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/groups/($id)/")
  let body = {group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/roles/{role_pk}/groups/{id}/
#
# operationId: api_v1_organisations_roles_groups_destroy
export def "organisations-roles-groups delete" [
  id: string
  organisation_pk: string
  role_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/groups/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/master-api-keys/
#
# operationId: api_v1_organisations_roles_master_api_keys_list
export def "organisations-roles-master-api-keys list" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, master_api_key: string, role: int, role_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/master-api-keys/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/roles/{role_pk}/master-api-keys/
#
# operationId: api_v1_organisations_roles_master_api_keys_create
export def "organisations-roles-master-api-keys create" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  master_api_key: string
]: any -> record<id: int, master_api_key: string, role: int, role_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/master-api-keys/")
  let body = {master_api_key: $master_api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/master-api-keys/{id}/
#
# operationId: api_v1_organisations_roles_master_api_keys_retrieve
export def "organisations-roles-master-api-keys get" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, master_api_key: string, role: int, role_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/master-api-keys/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/roles/{role_pk}/master-api-keys/{id}/
#
# operationId: api_v1_organisations_roles_master_api_keys_update
export def "organisations-roles-master-api-keys update" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  master_api_key: string
]: any -> record<id: int, master_api_key: string, role: int, role_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/master-api-keys/($id)/")
  let body = {master_api_key: $master_api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/roles/{role_pk}/master-api-keys/{id}/
#
# operationId: api_v1_organisations_roles_master_api_keys_partial_update
export def "organisations-roles-master-api-keys patch" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --master-api-key: string
]: any -> record<id: int, master_api_key: string, role: int, role_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/master-api-keys/($id)/")
  let body = {master_api_key: $master_api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/roles/{role_pk}/master-api-keys/{id}/
#
# operationId: api_v1_organisations_roles_master_api_keys_destroy
export def "organisations-roles-master-api-keys delete" [
  id: string
  organisation_pk: string
  role_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/master-api-keys/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/organisation-permissions/
#
# operationId: api_v1_organisations_roles_organisation_permissions_list
export def "organisations-roles-organisation-permissions list" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, role: int, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/organisation-permissions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/roles/{role_pk}/organisation-permissions/
#
# operationId: api_v1_organisations_roles_organisation_permissions_create
export def "organisations-roles-organisation-permissions create" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
]: any -> record<id: int, role: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/organisation-permissions/")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/organisation-permissions/{id}/
#
# operationId: api_v1_organisations_roles_organisation_permissions_retrieve
export def "organisations-roles-organisation-permissions get" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, role: int, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/organisation-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/roles/{role_pk}/organisation-permissions/{id}/
#
# operationId: api_v1_organisations_roles_organisation_permissions_update
export def "organisations-roles-organisation-permissions update" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
]: any -> record<id: int, role: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/organisation-permissions/($id)/")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/roles/{role_pk}/organisation-permissions/{id}/
#
# operationId: api_v1_organisations_roles_organisation_permissions_partial_update
export def "organisations-roles-organisation-permissions patch" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
]: any -> record<id: int, role: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/organisation-permissions/($id)/")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/roles/{role_pk}/organisation-permissions/{id}/
#
# operationId: api_v1_organisations_roles_organisation_permissions_destroy
export def "organisations-roles-organisation-permissions delete" [
  id: string
  organisation_pk: string
  role_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/organisation-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/projects-permissions/
#
# operationId: api_v1_organisations_roles_projects_permissions_list
export def "organisations-roles-projects-permissions list" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
  --project: int # ID of the project to filter by.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, role: int, project: int, permissions: list, admin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/projects-permissions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/roles/{role_pk}/projects-permissions/
#
# operationId: api_v1_organisations_roles_projects_permissions_create
# --permissions item shape: {permission_key: string, tags?: list}
export def "organisations-roles-projects-permissions create" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project: int
  permissions: list # item shape: {permission_key: string, tags?: list}
  --admin: oneof<nothing, bool>
]: any -> record<id: int, role: int, project: int, permissions: table<permission_key: string, tags: list>, admin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/projects-permissions/")
  let body = {project: $project, permissions: $permissions, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/projects-permissions/{id}/
#
# operationId: api_v1_organisations_roles_projects_permissions_retrieve
export def "organisations-roles-projects-permissions get" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, role: int, project: int, permissions: table<permission_key: string, tags: list>, admin: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/projects-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/roles/{role_pk}/projects-permissions/{id}/
#
# operationId: api_v1_organisations_roles_projects_permissions_update
# --permissions item shape: {permission_key: string, tags?: list}
export def "organisations-roles-projects-permissions update" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project: int
  permissions: list # item shape: {permission_key: string, tags?: list}
  --admin: oneof<nothing, bool>
]: any -> record<id: int, role: int, project: int, permissions: table<permission_key: string, tags: list>, admin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/projects-permissions/($id)/")
  let body = {project: $project, permissions: $permissions, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/roles/{role_pk}/projects-permissions/{id}/
#
# operationId: api_v1_organisations_roles_projects_permissions_partial_update
# --permissions item shape: {permission_key: string, tags?: list}
export def "organisations-roles-projects-permissions patch" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: int
  --permissions: list # item shape: {permission_key: string, tags?: list}
  --admin: oneof<nothing, bool>
]: any -> record<id: int, role: int, project: int, permissions: table<permission_key: string, tags: list>, admin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/projects-permissions/($id)/")
  let body = {project: $project, permissions: $permissions, admin: $admin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/roles/{role_pk}/projects-permissions/{id}/
#
# operationId: api_v1_organisations_roles_projects_permissions_destroy
export def "organisations-roles-projects-permissions delete" [
  id: string
  organisation_pk: string
  role_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/projects-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/users/
#
# operationId: api_v1_organisations_roles_users_list
export def "organisations-roles-users list" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, user: int, role: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/users/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/roles/{role_pk}/users/
#
# operationId: api_v1_organisations_roles_users_create
export def "organisations-roles-users create" [
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user: int
]: any -> record<id: int, user: int, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/users/")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/roles/{role_pk}/users/{id}/
#
# operationId: api_v1_organisations_roles_users_retrieve
export def "organisations-roles-users get" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, user: int, role: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/users/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/roles/{role_pk}/users/{id}/
#
# operationId: api_v1_organisations_roles_users_update
export def "organisations-roles-users update" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user: int
]: any -> record<id: int, user: int, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/users/($id)/")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/roles/{role_pk}/users/{id}/
#
# operationId: api_v1_organisations_roles_users_partial_update
export def "organisations-roles-users patch" [
  id: string
  organisation_pk: string
  role_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: int
]: any -> record<id: int, user: int, role: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/users/($id)/")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/roles/{role_pk}/users/{id}/
#
# operationId: api_v1_organisations_roles_users_destroy
export def "organisations-roles-users delete" [
  id: string
  organisation_pk: string
  role_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/roles/($role_pk)/users/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/scim/
#
# operationId: api_v1_organisations_scim_retrieve
export def "organisations-scim get" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/scim/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/scim/
#
# operationId: api_v1_organisations_scim_create
export def "organisations-scim create" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/scim/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/organisations/{organisation_pk}/scim/
#
# operationId: api_v1_organisations_scim_destroy
export def "organisations-scim delete" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/scim/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/scim/regenerate-token/
#
# operationId: api_v1_organisations_scim_regenerate_token_create
export def "organisations-scim-regenerate-token create" [
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/scim/regenerate-token/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/usage-data/
#
# operationId: api_v1_organisations_usage_data_retrieve
export def "organisations-usage-data get" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-application-name: string
  --client-application-version: string
  --environment-id: int
  --period: string@period-completer # * `current_billing_period` - current_billing_period * `previous_billing_period` - previous_billing_period * `90_day_period` - 90_day_period
  --project-id: int
  --user-agent: string
]: nothing -> record<flags: int, identities: int, traits: int, environment_document: int, day: string, labels: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_application_name" $client_application_name "scalar") (serialize-qp "client_application_version" $client_application_version "scalar") (serialize-qp "environment_id" $environment_id "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "user_agent" $user_agent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/usage-data/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/usage-data/total-count/
#
# operationId: api_v1_organisations_usage_data_total_count_retrieve
export def "organisations-usage-data-total-count get" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/usage-data/total-count/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/user-group-permissions/
#
# operationId: api_v1_organisations_user_group_permissions_list
export def "organisations-user-group-permissions list" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: int
]: nothing -> table<id: int, group: record<id: int, name: string, users: list, is_default: bool, external_id: string>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-group-permissions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/user-group-permissions/
#
# operationId: api_v1_organisations_user_group_permissions_create
export def "organisations-user-group-permissions create" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group: int
  --permissions: list
]: any -> record<id: int, group: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-group-permissions/")
  let body = {group: $group, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/organisations/{organisation_pk}/user-group-permissions/{id}/
#
# operationId: api_v1_organisations_user_group_permissions_update
export def "organisations-user-group-permissions update" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group: int
  --permissions: list
]: any -> record<id: int, group: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-group-permissions/($id)/")
  let body = {group: $group, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/user-group-permissions/{id}/
#
# operationId: api_v1_organisations_user_group_permissions_partial_update
export def "organisations-user-group-permissions patch" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group: int
  --permissions: list
]: any -> record<id: int, group: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-group-permissions/($id)/")
  let body = {group: $group, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/user-group-permissions/{id}/
#
# operationId: api_v1_organisations_user_group_permissions_destroy
export def "organisations-user-group-permissions delete" [
  id: int
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-group-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/user-permissions/
#
# operationId: api_v1_organisations_user_permissions_list
export def "organisations-user-permissions list" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: int
]: nothing -> table<id: int, user: record<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-permissions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/user-permissions/
#
# operationId: api_v1_organisations_user_permissions_create
export def "organisations-user-permissions create" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user: int
  --permissions: list
]: any -> record<id: int, user: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-permissions/")
  let body = {user: $user, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/organisations/{organisation_pk}/user-permissions/{id}/
#
# operationId: api_v1_organisations_user_permissions_update
export def "organisations-user-permissions update" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user: int
  --permissions: list
]: any -> record<id: int, user: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-permissions/($id)/")
  let body = {user: $user, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/user-permissions/{id}/
#
# operationId: api_v1_organisations_user_permissions_partial_update
export def "organisations-user-permissions patch" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: int
  --permissions: list
]: any -> record<id: int, user: int, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-permissions/($id)/")
  let body = {user: $user, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/user-permissions/{id}/
#
# operationId: api_v1_organisations_user_permissions_destroy
export def "organisations-user-permissions delete" [
  id: int
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/user-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/users/
#
# operationId: api_v1_organisations_users_list
export def "organisations-users list" [
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/users/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/users/{id}/update-role/
#
# operationId: api_v1_organisations_users_update_role_create
export def "organisations-users-update-role create" [
  id: int
  organisation_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role: string@role-completer # * `ADMIN` - Admin * `USER` - User
]: any -> record<role: string, organisation: record<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/users/($id)/update-role/")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/users/{user_pk}/roles/
#
# operationId: api_v1_organisations_users_roles_list
export def "organisations-users-roles list" [
  organisation_pk: string
  user_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, description: string, organisation: int, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/users/($user_pk)/roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/organisations/{organisation_pk}/users/{user_pk}/roles/{id}/
#
# operationId: api_v1_organisations_users_roles_destroy
export def "organisations-users-roles delete" [
  id: string
  organisation_pk: string
  user_pk: string
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/users/($user_pk)/roles/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{organisation_pk}/webhooks/
#
# operationId: api_v1_organisations_webhooks_list
export def "organisations-webhooks list" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, url: string, enabled: bool, secret: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/webhooks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{organisation_pk}/webhooks/
#
# operationId: api_v1_organisations_webhooks_create
export def "organisations-webhooks create" [
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  --enabled: oneof<nothing, bool>
  --secret: string
]: any -> record<id: int, url: string, enabled: bool, secret: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/webhooks/")
  let body = {url: $body_url, enabled: $enabled, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{organisation_pk}/webhooks/{id}/
#
# operationId: api_v1_organisations_webhooks_retrieve
export def "organisations-webhooks get" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, url: string, enabled: bool, secret: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/webhooks/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{organisation_pk}/webhooks/{id}/
#
# operationId: api_v1_organisations_webhooks_update
export def "organisations-webhooks update" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  --enabled: oneof<nothing, bool>
  --secret: string
]: any -> record<id: int, url: string, enabled: bool, secret: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/webhooks/($id)/")
  let body = {url: $body_url, enabled: $enabled, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{organisation_pk}/webhooks/{id}/
#
# operationId: api_v1_organisations_webhooks_partial_update
export def "organisations-webhooks patch" [
  id: int
  organisation_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string
  --enabled: oneof<nothing, bool>
  --secret: string
]: any -> record<id: int, url: string, enabled: bool, secret: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/webhooks/($id)/")
  let body = {url: $body_url, enabled: $enabled, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{organisation_pk}/webhooks/{id}/
#
# operationId: api_v1_organisations_webhooks_destroy
export def "organisations-webhooks delete" [
  id: int
  organisation_pk: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($organisation_pk)/webhooks/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{id}/
#
# operationId: api_v1_organisations_retrieve
export def "organisations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record<id: int, has_active_billing_periods: bool, deleted_at: string, uuid: string, subscription_id: string, subscription_date: string, plan: string, max_seats: int, max_api_calls: int, cancellation_date: string, customer_id: string, billing_status: any, payment_method: any, notes: string>, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/organisations/{id}/
#
# operationId: api_v1_organisations_update
# --subscription shape: {subscription_id?: string, subscription_date?: string, plan?: string, max_seats?: int, max_api_calls?: int, cancellation_date?: string, customer_id?: string, billing_status?: any, payment_method?: any, notes?: string}
export def "organisations update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --webhook-notification-email: string # nullable, format: email
  --subscription: record # shape: {subscription_id?: string, subscription_date?: string, plan?: string, max_seats?: int, max_api_calls?: int, cancellation_date?: string, customer_id?: string, billing_status?: any, payment_method?: any, notes?: string}
  --restrict-project-create-to-admin: oneof<nothing, bool>
  --force-2fa: oneof<nothing, bool>
]: any -> record<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record<id: int, has_active_billing_periods: bool, deleted_at: string, uuid: string, subscription_id: string, subscription_date: string, plan: string, max_seats: int, max_api_calls: int, cancellation_date: string, customer_id: string, billing_status: any, payment_method: any, notes: string>, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/")
  let body = {name: $name, webhook_notification_email: $webhook_notification_email, subscription: $subscription, restrict_project_create_to_admin: $restrict_project_create_to_admin, force_2fa: $force_2fa} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/organisations/{id}/
#
# operationId: api_v1_organisations_partial_update
# --subscription shape: {subscription_id?: string, subscription_date?: string, plan?: string, max_seats?: int, max_api_calls?: int, cancellation_date?: string, customer_id?: string, billing_status?: any, payment_method?: any, notes?: string}
export def "organisations patch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --webhook-notification-email: string # nullable, format: email
  --subscription: record # shape: {subscription_id?: string, subscription_date?: string, plan?: string, max_seats?: int, max_api_calls?: int, cancellation_date?: string, customer_id?: string, billing_status?: any, payment_method?: any, notes?: string}
  --restrict-project-create-to-admin: oneof<nothing, bool>
  --force-2fa: oneof<nothing, bool>
]: any -> record<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record<id: int, has_active_billing_periods: bool, deleted_at: string, uuid: string, subscription_id: string, subscription_date: string, plan: string, max_seats: int, max_api_calls: int, cancellation_date: string, customer_id: string, billing_status: any, payment_method: any, notes: string>, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/")
  let body = {name: $name, webhook_notification_email: $webhook_notification_email, subscription: $subscription, restrict_project_create_to_admin: $restrict_project_create_to_admin, force_2fa: $force_2fa} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/organisations/{id}/
#
# operationId: api_v1_organisations_destroy
export def "organisations delete" [
  id: int
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
  let full_url = (build-url $base $"/api/v1/organisations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{id}/get-hosted-page-url-for-subscription-upgrade/
#
# operationId: api_v1_organisations_get_hosted_page_url_for_subscription_upgrade_create
export def "organisations-get-hosted-page-url-for-subscription-upgrade create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  plan_id: string
  subscription_id: string
]: any -> record<plan_id: string, subscription_id: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/get-hosted-page-url-for-subscription-upgrade/")
  let body = {plan_id: $plan_id, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{id}/get-subscription-metadata/
#
# operationId: api_v1_organisations_get_subscription_metadata_retrieve
export def "organisations-get-subscription-metadata get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<max_seats: int, max_api_calls: int, max_projects: int, payment_source: any, chargebee_email: string, feature_history_visibility_days: int, audit_log_visibility_days: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/get-subscription-metadata/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Please use /api/v1/organisations/{organisation_pk}/usage-data/
#
# GET /api/v1/organisations/{id}/influx-data/
# DEPRECATED
# operationId: api_v1_organisations_influx_data_retrieve
@deprecated
export def "organisations-influx-data get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-id: int
  --project-id: int
]: nothing -> record<events_list: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment_id" $environment_id "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/organisations/($id)/influx-data/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/organisations/{id}/invite/
#
# operationId: api_v1_organisations_invite_create
# --invites item shape: {email: string, role?: "ADMIN"|"USER", permission_groups?: list}
export def "organisations-invite create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --invites: list # item shape: {email: string, role?: "ADMIN"|"USER", permission_groups?: list}
  --emails: list
]: any -> record<invites: table<id: int, email: string, role: string, date_created: string, permission_groups: list>, emails: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/invite/")
  let body = {invites: $invites, emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/organisations/{id}/my-permissions/
#
# operationId: api_v1_organisations_my_permissions_retrieve
export def "organisations-my-permissions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: list<string>, admin: bool, tag_based_permissions: table<permissions: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/my-permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{id}/portal-url/
#
# operationId: api_v1_organisations_portal_url_retrieve
export def "organisations-portal-url get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/portal-url/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all projects within a specified organisation.
#
# GET /api/v1/organisations/{id}/projects/
# operationId: list_projects_in_organization
export def "organisations-projects organization" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record<id: int, has_active_billing_periods: bool, deleted_at: string, uuid: string, subscription_id: string, subscription_date: string, plan: string, max_seats: int, max_api_calls: int, cancellation_date: string, customer_id: string, billing_status: any, payment_method: any, notes: string>, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/projects/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Takes a list of users and removes them from the organisation provided in the url
#
# POST /api/v1/organisations/{id}/remove-users/
# operationId: api_v1_organisations_remove_users_create
export def "organisations-remove-users create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: int
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/remove-users/")
  let body = {id: $body_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/organisations/{id}/update-subscription/
#
# operationId: api_v1_organisations_update_subscription_create
export def "organisations-update-subscription create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  hosted_page_id: string
]: any -> record<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record<id: int, has_active_billing_periods: bool, deleted_at: string, uuid: string, subscription_id: string, subscription_date: string, plan: string, max_seats: int, max_api_calls: int, cancellation_date: string, customer_id: string, billing_status: any, payment_method: any, notes: string>, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/update-subscription/")
  let body = {hosted_page_id: $hosted_page_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Please use /api/v1/organisations/{organisation_pk}/usage-data/total-count/
#
# GET /api/v1/organisations/{id}/usage/
# DEPRECATED
# operationId: api_v1_organisations_usage_retrieve
@deprecated
export def "organisations-usage get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record<id: int, has_active_billing_periods: bool, deleted_at: string, uuid: string, subscription_id: string, subscription_date: string, plan: string, max_seats: int, max_api_calls: int, cancellation_date: string, customer_id: string, billing_status: any, payment_method: any, notes: string>, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/usage/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/{id}/user-detailed-permissions/{user_id}/
#
# operationId: api_v1_organisations_user_detailed_permissions_retrieve
export def "organisations-user-detailed-permissions get" [
  id: int
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: bool, permissions: table<permission_key: string, is_directly_granted: bool, derived_from: record>, is_directly_granted: bool, derived_from: record<groups: list<record>, roles: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/($id)/user-detailed-permissions/($user_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/get-by-uuid/{uuid}/
#
# operationId: api_v1_organisations_get_by_uuid_retrieve
export def "organisations-get-by-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, created_date: string, webhook_notification_email: string, num_seats: int, subscription: record<id: int, has_active_billing_periods: bool, deleted_at: string, uuid: string, subscription_id: string, subscription_date: string, plan: string, max_seats: int, max_api_calls: int, cancellation_date: string, customer_id: string, billing_status: any, payment_method: any, notes: string>, role: string, persist_trait_data: bool, block_access_to_admin: bool, restrict_project_create_to_admin: bool, force_2fa: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/organisations/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/organisations/permissions/
#
# operationId: api_v1_organisations_permissions_retrieve
export def "organisations-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, description: string, supports_tag: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/organisations/permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/
#
# operationId: api_v1_projects_list
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/projects/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/
#
# operationId: api_v1_projects_create
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  organisation: int
  --hide-disabled-flags: oneof<nothing, bool> # If true will exclude flags from SDK which are disabled
  --prevent-flag-defaults: oneof<nothing, bool> # Prevent defaults from being set in all environments when creating a feature.
  --only-allow-lower-case-feature-names: oneof<nothing, bool> # Used by UI to validate feature names
  --feature-name-regex: string # Used for validating feature names (nullable)
  --minimum-change-request-approvals: int # nullable
  --enforce-feature-owners: oneof<nothing, bool> # Require at least one user or group owner when creating a feature.
]: any -> record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/projects/")
  let body = {name: $name, organisation: $organisation, hide_disabled_flags: $hide_disabled_flags, prevent_flag_defaults: $prevent_flag_defaults, only_allow_lower_case_feature_names: $only_allow_lower_case_feature_names, feature_name_regex: $feature_name_regex, minimum_change_request_approvals: $minimum_change_request_approvals, enforce_feature_owners: $enforce_feature_owners} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves comprehensive information about a specific project including configuration and statistics.
#
# GET /api/v1/projects/{id}/
# operationId: get_project
export def "projects project-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool, max_segments_allowed: int, max_features_allowed: int, max_segment_overrides_allowed: int, total_features: int, total_segments: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates project configuration settings such as the project name and feature visibility.
#
# PUT /api/v1/projects/{id}/
# operationId: update_project
export def "projects project-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --hide-disabled-flags: oneof<nothing, bool> # If true will exclude flags from SDK which are disabled
  --prevent-flag-defaults: oneof<nothing, bool> # Prevent defaults from being set in all environments when creating a feature.
  --only-allow-lower-case-feature-names: oneof<nothing, bool> # Used by UI to validate feature names
  --feature-name-regex: string # Used for validating feature names (nullable)
  --minimum-change-request-approvals: int # nullable
  --enforce-feature-owners: oneof<nothing, bool> # Require at least one user or group owner when creating a feature.
]: any -> record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($id)/")
  let body = {name: $name, hide_disabled_flags: $hide_disabled_flags, prevent_flag_defaults: $prevent_flag_defaults, only_allow_lower_case_feature_names: $only_allow_lower_case_feature_names, feature_name_regex: $feature_name_regex, minimum_change_request_approvals: $minimum_change_request_approvals, enforce_feature_owners: $enforce_feature_owners} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{id}/
#
# operationId: api_v1_projects_partial_update
export def "projects patch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --hide-disabled-flags: oneof<nothing, bool> # If true will exclude flags from SDK which are disabled
  --prevent-flag-defaults: oneof<nothing, bool> # Prevent defaults from being set in all environments when creating a feature.
  --only-allow-lower-case-feature-names: oneof<nothing, bool> # Used by UI to validate feature names
  --feature-name-regex: string # Used for validating feature names (nullable)
  --minimum-change-request-approvals: int # nullable
  --enforce-feature-owners: oneof<nothing, bool> # Require at least one user or group owner when creating a feature.
]: any -> record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($id)/")
  let body = {name: $name, hide_disabled_flags: $hide_disabled_flags, prevent_flag_defaults: $prevent_flag_defaults, only_allow_lower_case_feature_names: $only_allow_lower_case_feature_names, feature_name_regex: $feature_name_regex, minimum_change_request_approvals: $minimum_change_request_approvals, enforce_feature_owners: $enforce_feature_owners} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{id}/
#
# operationId: api_v1_projects_destroy
export def "projects delete" [
  id: int
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
  let full_url = (build-url $base $"/api/v1/projects/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all environments configured for the specified project.
#
# GET /api/v1/projects/{id}/environments/
# operationId: list_project_environments
export def "projects-environments environments" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($id)/environments/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{id}/migrate-to-edge/
#
# operationId: api_v1_projects_migrate_to_edge_create
export def "projects-migrate-to-edge create" [
  id: int
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
  let full_url = (build-url $base $"/api/v1/projects/($id)/migrate-to-edge/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{id}/my-permissions/
#
# operationId: api_v1_projects_my_permissions_retrieve
export def "projects-my-permissions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: list<string>, admin: bool, tag_based_permissions: table<permissions: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($id)/my-permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{id}/user-detailed-permissions/{user_id}/
#
# operationId: api_v1_projects_user_detailed_permissions_retrieve
export def "projects-user-detailed-permissions get" [
  id: int
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: bool, permissions: table<permission_key: string, is_directly_granted: bool, derived_from: record>, is_directly_granted: bool, derived_from: record<groups: list<record>, roles: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($id)/user-detailed-permissions/($user_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/all-user-permissions/{user_pk}/
#
# operationId: api_v1_projects_all_user_permissions_retrieve
export def "projects-all-user-permissions get" [
  project_pk: int
  user_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<permissions: list<string>, admin: bool, tag_based_permissions: table<permissions: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/all-user-permissions/($user_pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/audit/
#
# operationId: api_v1_projects_audit_list
export def "projects-audit list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environments: list
  --is-system-event: oneof<nothing, bool>
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --project: int
  --search: string
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, created_date: string, log: string, author: record, environment: record, project: record, related_object_id: int, related_object_uuid: string, related_object_type: string, is_system_event: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environments" $environments "multi") (serialize-qp "is_system_event" $is_system_event "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/audit/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/audit/{id}/
#
# operationId: api_v1_projects_audit_retrieve
export def "projects-audit get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_date: string, log: string, author: record<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, environment: record<id: int, uuid: string, name: string, api_key: string, description: string, project: int, minimum_change_request_approvals: int, allow_client_traits: bool, banner_text: string, banner_colour: string, hide_disabled_flags: bool, use_mv_v2_evaluation: bool, use_identity_composite_key_for_hashing: bool, hide_sensitive_data: bool, use_v2_feature_versioning: bool, use_identity_overrides_in_local_eval: bool, is_creating: bool>, project: record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool>, related_object_id: int, related_object_uuid: string, related_object_type: string, is_system_event: bool, change_details: table<field: string, old: string, new: string>, change_type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/audit/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all change requests for a project.
#
# GET /api/v1/projects/{project_pk}/change-requests/
# operationId: list_project_change_requests
export def "projects-change-requests requests" [
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --committed: oneof<nothing, bool> # Filter on the committed status of a change request.
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # Fuzzy search across Change Request titles.
  --segment-id: int # Filter change requests which match a specific segment id.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, created_at: string, updated_at: string, title: string, description: string, user: int, committed_at: string, committed_by: int, deleted_at: string, live_from: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "committed" $committed "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "segment_id" $segment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/change-requests/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/change-requests/
#
# operationId: api_v1_projects_change_requests_create
# --approvals item shape: {user: int}
# --group_assignments item shape: {group: int}
# --segments item shape: {name: string, description?: string, project: int, feature?: int, version_of?: int, rules: list, metadata?: list, change_request?: int}
export def "projects-change-requests create" [
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --approvals: list # item shape: {user: int}
  --description: string # nullable
  --group-assignments: list # item shape: {group: int}
  segments: list # item shape: {name: string, description?: string, project: int, feature?: int, version_of?: int, rules: list, metadata?: list, change_request?: int}
  title: string
  --user: int # nullable
]: any -> record<id: int, approvals: table<id: int, user: int, approved_at: string>, committed_at: string, committed_by: int, created_at: string, deleted_at: string, description: string, group_assignments: table<group: int>, project_id: int, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list, change_request: int>, title: string, updated_at: string, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/change-requests/")
  let body = {approvals: $approvals, description: $description, group_assignments: $group_assignments, segments: $segments, title: $title, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/change-requests/{id}/
#
# operationId: api_v1_projects_change_requests_retrieve
export def "projects-change-requests get" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_at: string, updated_at: string, environment: int, title: string, description: string, user: int, committed_at: string, committed_by: int, deleted_at: string, approvals: table<id: int, user: int, approved_at: string>, is_approved: bool, is_committed: string, group_assignments: table<group: int>, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, conflicts: table<original_cr_id: int, segment_id: int, is_environment_default: bool, published_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/change-requests/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/change-requests/{id}/
#
# operationId: api_v1_projects_change_requests_update
# --approvals item shape: {user: int}
# --group_assignments item shape: {group: int}
# --segments item shape: {name: string, description?: string, project: int, feature?: int, version_of?: int, rules: list, metadata?: list, change_request?: int}
export def "projects-change-requests update" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --approvals: list # item shape: {user: int}
  --description: string # nullable
  --group-assignments: list # item shape: {group: int}
  segments: list # item shape: {name: string, description?: string, project: int, feature?: int, version_of?: int, rules: list, metadata?: list, change_request?: int}
  title: string
  --user: int # nullable
]: any -> record<id: int, approvals: table<id: int, user: int, approved_at: string>, committed_at: string, committed_by: int, created_at: string, deleted_at: string, description: string, group_assignments: table<group: int>, project_id: int, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list, change_request: int>, title: string, updated_at: string, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/change-requests/($id)/")
  let body = {approvals: $approvals, description: $description, group_assignments: $group_assignments, segments: $segments, title: $title, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/change-requests/{id}/
#
# operationId: api_v1_projects_change_requests_partial_update
# --approvals item shape: {user: int}
# --group_assignments item shape: {group: int}
# --segments item shape: {name: string, description?: string, project: int, feature?: int, version_of?: int, rules: list, metadata?: list, change_request?: int}
export def "projects-change-requests patch" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --approvals: list # item shape: {user: int}
  --description: string # nullable
  --group-assignments: list # item shape: {group: int}
  --segments: list # item shape: {name: string, description?: string, project: int, feature?: int, version_of?: int, rules: list, metadata?: list, change_request?: int}
  --title: string
  --user: int # nullable
]: any -> record<id: int, approvals: table<id: int, user: int, approved_at: string>, committed_at: string, committed_by: int, created_at: string, deleted_at: string, description: string, group_assignments: table<group: int>, project_id: int, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list, change_request: int>, title: string, updated_at: string, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/change-requests/($id)/")
  let body = {approvals: $approvals, description: $description, group_assignments: $group_assignments, segments: $segments, title: $title, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/change-requests/{id}/
#
# operationId: api_v1_projects_change_requests_destroy
export def "projects-change-requests delete" [
  id: string
  project_pk: string
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/change-requests/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/change-requests/{id}/approve/
#
# operationId: api_v1_projects_change_requests_approve_create
export def "projects-change-requests-approve create" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_at: string, updated_at: string, environment: int, title: string, description: string, user: int, committed_at: string, committed_by: int, deleted_at: string, approvals: table<id: int, user: int, approved_at: string>, is_approved: bool, is_committed: string, group_assignments: table<group: int>, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, conflicts: table<original_cr_id: int, segment_id: int, is_environment_default: bool, published_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/change-requests/($id)/approve/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/change-requests/{id}/commit/
#
# operationId: api_v1_projects_change_requests_commit_create
export def "projects-change-requests-commit create" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_at: string, updated_at: string, environment: int, title: string, description: string, user: int, committed_at: string, committed_by: int, deleted_at: string, approvals: table<id: int, user: int, approved_at: string>, is_approved: bool, is_committed: string, group_assignments: table<group: int>, segments: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list>, change_sets: table<id: int, feature: int, live_from: string, feature_states_to_update: list, feature_states_to_create: list, segment_ids_to_delete_overrides: list>, conflicts: table<original_cr_id: int, segment_id: int, is_environment_default: bool, published_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/change-requests/($id)/commit/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# API view to create code references for a project
#
# POST /api/v1/projects/{project_pk}/code-references/
# operationId: api_v1_projects_code_references_create
# --code_references item shape: {file_path: string, line_number: int, feature_name: string}
export def "projects-code-references create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  repository_url: string # format: uri
  --vcs-provider: any # default: github
  revision: string
  code_references: list # item shape: {file_path: string, line_number: int, feature_name: string}
]: any -> record<created_at: string, project: int, repository_url: string, vcs_provider: record, revision: string, code_references: table<file_path: string, line_number: int, feature_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/code-references/")
  let body = {repository_url: $repository_url, vcs_provider: $vcs_provider, revision: $revision, code_references: $code_references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/feature-exports/
#
# operationId: api_v1_projects_feature_exports_list
export def "projects-feature-exports list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, environment_id: int, status: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/feature-exports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves feature health monitoring events and metrics for the project.
#
# GET /api/v1/projects/{project_pk}/feature-health/events/
# operationId: get_feature_health_events
export def "projects-feature-health-events events" [
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, created_at: string, environment: int, feature: int, provider_name: string, reason: any, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/feature-health/events/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/feature-health/events/{id}/dismiss/
#
# operationId: api_v1_projects_feature_health_events_dismiss_create
export def "projects-feature-health-events-dismiss create" [
  id: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: any
]: any -> record<id: int, created_at: string, environment: int, feature: int, provider_name: string, reason: any, type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/feature-health/events/($id)/dismiss/")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/feature-health/providers/
#
# operationId: api_v1_projects_feature_health_providers_list
export def "projects-feature-health-providers list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_by: string, name: string, project: int, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/feature-health/providers/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/feature-health/providers/
#
# operationId: api_v1_projects_feature_health_providers_create
export def "projects-feature-health-providers create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string@name-completer # * `Webhook` - Webhook * `Grafana` - Grafana
]: any -> record<created_by: string, name: string, project: int, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/feature-health/providers/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/feature-health/providers/{name}/
#
# operationId: api_v1_projects_feature_health_providers_destroy
export def "projects-feature-health-providers delete" [
  name: string
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/feature-health/providers/($name)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/feature-imports/
#
# operationId: api_v1_projects_feature_imports_list
export def "projects-feature-imports list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, environment_id: int, strategy: string, status: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/feature-imports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists a project's feature flags (paginated). Pass `environment=<id>` to also get each feature's live state for that environment in `environment_feature_state`, along with override counts. Works for both v1 and v2 versioned environments.
#
# GET /api/v1/projects/{project_pk}/features/
# operationId: list_project_features
export def "projects-features features" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: int # Integer ID of the environment to view features in the context of.
  --group-owners: string # Comma separated list of group owner ids to filter on
  --identity: string # ID of the identity to sort features with identity overrides first.
  --is-archived: oneof<nothing, bool>
  --is-enabled: oneof<nothing, bool> # Boolean value to filter features as enabled or disabled.
  --owners: string # Comma separated list of owner ids to filter on
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string
  --segment: int # Integer ID of the segment to retrieve segment overrides for.
  --sort-direction: string@sort-direction-completer # * `ASC` - ASC * `DESC` - DESC (default: ASC)
  --sort-field: string@sort-field-completer # * `created_date` - created_date * `name` - name (default: created_date)
  --tag-strategy: string@tag-strategy-completer # * `UNION` - UNION * `INTERSECTION` - INTERSECTION (default: INTERSECTION)
  --tags: string # Comma separated list of tag ids to filter on (AND with INTERSECTION, and OR with UNION via tag_strategy)
  --type: string@type-completer-1 # Feature type to filter on (STANDARD or MULTIVARIATE).  * `STANDARD` - STANDARD * `MULTIVARIATE` - MULTIVARIATE
  --value-search: string # Value of type int, string, or boolean to filter features based on their values
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, type: any, default_enabled: bool, initial_value: string, created_date: string, description: string, tags: list, multivariate_options: list, is_archived: bool, owners: list, group_owners: list, uuid: string, project: int, environment_feature_state: any, segment_feature_state: any, num_segment_overrides: int, num_identity_overrides: int, is_num_identity_overrides_complete: bool, is_server_key_only: bool, last_modified_in_any_environment: string, last_modified_in_current_environment: string, metadata: list, code_references_counts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar") (serialize-qp "group_owners" $group_owners "scalar") (serialize-qp "identity" $identity "scalar") (serialize-qp "is_archived" $is_archived "scalar") (serialize-qp "is_enabled" $is_enabled "scalar") (serialize-qp "owners" $owners "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "segment" $segment "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "tag_strategy" $tag_strategy "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "value_search" $value_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new feature flag in the specified project with default settings.
#
# POST /api/v1/projects/{project_pk}/features/
# operationId: create_feature
# --multivariate_options item shape: {type?: any, integer_value?: int, string_value?: string, boolean_value?: bool, default_percentage_allocation?: float}
# --metadata item shape: {model_field: int, field_value: string}
# --code_references_counts item shape: {repository_url: string, count: int, last_successful_repository_scanned_at: string, last_feature_found_at: string}
export def "projects-features feature-by-project_pk" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --type: any
  --default-enabled: oneof<nothing, bool>
  --initial-value: string # nullable
  --description: string # nullable
  --tags: list
  --multivariate-options: list # item shape: {type?: any, integer_value?: int, string_value?: string, boolean_value?: bool, default_percentage_allocation?: float}
  --is-archived: oneof<nothing, bool>
  --owners: list
  --group-owners: list
  --is-server-key-only: oneof<nothing, bool>
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, name: string, type: any, default_enabled: bool, initial_value: string, created_date: string, description: string, tags: list<int>, multivariate_options: table<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string>, is_archived: bool, owners: list<int>, group_owners: list<int>, uuid: string, project: int, environment_feature_state: any, segment_feature_state: any, num_segment_overrides: int, num_identity_overrides: int, is_num_identity_overrides_complete: bool, is_server_key_only: bool, last_modified_in_any_environment: string, last_modified_in_current_environment: string, metadata: table<id: int, model_field: int, field_value: string>, code_references_counts: table<repository_url: string, count: int, last_successful_repository_scanned_at: string, last_feature_found_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/")
  let body = {name: $name, type: $type, default_enabled: $default_enabled, initial_value: $initial_value, description: $description, tags: $tags, multivariate_options: $multivariate_options, is_archived: $is_archived, owners: $owners, group_owners: $group_owners, is_server_key_only: $is_server_key_only, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves code references and usage information for the feature flag.
#
# GET /api/v1/projects/{project_pk}/features/{feature_pk}/code-references/
# operationId: get_feature_code_references
export def "projects-features-code-references references" [
  feature_pk: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<repository_url: string, vcs_provider: string, revision: string, last_successful_repository_scanned_at: string, last_feature_found_at: string, code_references: table<file_path: string, line_number: int, scanned_at: string, vcs_provider: string, repository_url: string, revision: string, permalink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/code-references/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves external resources linked to the feature flag.
#
# GET /api/v1/projects/{project_pk}/features/{feature_pk}/feature-external-resources/
# operationId: get_feature_external_resources
export def "projects-features-feature-external-resources resources" [
  feature_pk: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, url: string, type: string, metadata: any, feature: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/feature-external-resources/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/features/{feature_pk}/feature-external-resources/
#
# operationId: api_v1_projects_features_feature_external_resources_create
export def "projects-features-feature-external-resources create" [
  feature_pk: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # format: uri
  type: string@type-completer-2 # * `GITHUB_ISSUE` - GitHub Issue * `GITHUB_PR` - GitHub PR * `GITLAB_ISSUE` - GitLab Issue * `GITLAB_MR` - GitLab MR
  --metadata: any
  feature: int
]: any -> record<id: int, url: string, type: string, metadata: any, feature: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/feature-external-resources/")
  let body = {url: $body_url, type: $type, metadata: $metadata, feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/features/{feature_pk}/feature-external-resources/{id}/
#
# operationId: api_v1_projects_features_feature_external_resources_retrieve
export def "projects-features-feature-external-resources get" [
  feature_pk: int
  id: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, url: string, type: string, metadata: any, feature: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/feature-external-resources/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/features/{feature_pk}/feature-external-resources/{id}/
#
# operationId: api_v1_projects_features_feature_external_resources_update
export def "projects-features-feature-external-resources update" [
  feature_pk: int
  id: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # format: uri
  type: string@type-completer-2 # * `GITHUB_ISSUE` - GitHub Issue * `GITHUB_PR` - GitHub PR * `GITLAB_ISSUE` - GitLab Issue * `GITLAB_MR` - GitLab MR
  --metadata: any
  feature: int
]: any -> record<id: int, url: string, type: string, metadata: any, feature: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/feature-external-resources/($id)/")
  let body = {url: $body_url, type: $type, metadata: $metadata, feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/features/{feature_pk}/feature-external-resources/{id}/
#
# operationId: api_v1_projects_features_feature_external_resources_partial_update
export def "projects-features-feature-external-resources patch" [
  feature_pk: int
  id: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # format: uri
  --type: string@type-completer-2 # * `GITHUB_ISSUE` - GitHub Issue * `GITHUB_PR` - GitHub PR * `GITLAB_ISSUE` - GitLab Issue * `GITLAB_MR` - GitLab MR
  --metadata: any
  --feature: int
]: any -> record<id: int, url: string, type: string, metadata: any, feature: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/feature-external-resources/($id)/")
  let body = {url: $body_url, type: $type, metadata: $metadata, feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/features/{feature_pk}/feature-external-resources/{id}/
#
# operationId: api_v1_projects_features_feature_external_resources_destroy
export def "projects-features-feature-external-resources delete" [
  feature_pk: int
  id: int
  project_pk: string
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/feature-external-resources/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all multivariate options for a feature flag.
#
# GET /api/v1/projects/{project_pk}/features/{feature_pk}/mv-options/
# operationId: list_feature_multivariate_options
export def "projects-features-mv-options options" [
  feature_pk: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string, feature: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/mv-options/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new multivariate option for a feature flag.
#
# POST /api/v1/projects/{project_pk}/features/{feature_pk}/mv-options/
# operationId: create_feature_multivariate_option
export def "projects-features-mv-options option-by-feature_pk-project_pk" [
  feature_pk: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: any
  --integer-value: int # nullable
  --string-value: string # nullable
  --boolean-value: oneof<nothing, bool> # nullable
  --default-percentage-allocation: float # format: double
  --key: string # A stable, human-readable identifier for the variant. (nullable)
  feature: int
]: any -> record<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string, feature: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/mv-options/")
  let body = {type: $type, integer_value: $integer_value, string_value: $string_value, boolean_value: $boolean_value, default_percentage_allocation: $default_percentage_allocation, key: $key, feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/features/{feature_pk}/mv-options/{id}/
#
# operationId: api_v1_projects_features_mv_options_retrieve
export def "projects-features-mv-options get" [
  feature_pk: int
  id: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string, feature: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/mv-options/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing multivariate option.
#
# PUT /api/v1/projects/{project_pk}/features/{feature_pk}/mv-options/{id}/
# operationId: update_feature_multivariate_option
export def "projects-features-mv-options option-by-feature_pk-id-project_pk" [
  feature_pk: int
  id: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: any
  --integer-value: int # nullable
  --string-value: string # nullable
  --boolean-value: oneof<nothing, bool> # nullable
  --default-percentage-allocation: float # format: double
  --key: string # A stable, human-readable identifier for the variant. (nullable)
  feature: int
]: any -> record<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string, feature: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/mv-options/($id)/")
  let body = {type: $type, integer_value: $integer_value, string_value: $string_value, boolean_value: $boolean_value, default_percentage_allocation: $default_percentage_allocation, key: $key, feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/features/{feature_pk}/mv-options/{id}/
#
# operationId: api_v1_projects_features_mv_options_partial_update
export def "projects-features-mv-options patch" [
  feature_pk: int
  id: int
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: any
  --integer-value: int # nullable
  --string-value: string # nullable
  --boolean-value: oneof<nothing, bool> # nullable
  --default-percentage-allocation: float # format: double
  --key: string # A stable, human-readable identifier for the variant. (nullable)
  --feature: int
]: any -> record<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string, feature: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/mv-options/($id)/")
  let body = {type: $type, integer_value: $integer_value, string_value: $string_value, boolean_value: $boolean_value, default_percentage_allocation: $default_percentage_allocation, key: $key, feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a multivariate option.
#
# DELETE /api/v1/projects/{project_pk}/features/{feature_pk}/mv-options/{id}/
# operationId: delete_feature_multivariate_option
export def "projects-features-mv-options option-by-feature_pk-id-project_pk-1" [
  feature_pk: int
  id: int
  project_pk: string
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($feature_pk)/mv-options/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves detailed information about a specific feature flag.
#
# GET /api/v1/projects/{project_pk}/features/{id}/
# operationId: get_feature_flag
export def "projects-features flag" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, type: any, default_enabled: bool, initial_value: string, created_date: string, description: string, tags: list<int>, multivariate_options: table<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string>, is_archived: bool, owners: list<int>, group_owners: list<int>, uuid: string, project: int, environment_feature_state: any, segment_feature_state: any, num_segment_overrides: int, num_identity_overrides: int, is_num_identity_overrides_complete: bool, is_server_key_only: bool, last_modified_in_any_environment: string, last_modified_in_current_environment: string, metadata: table<id: int, model_field: int, field_value: string>, code_references_counts: table<repository_url: string, count: int, last_successful_repository_scanned_at: string, last_feature_found_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates feature flag properties such as name and description.
#
# PUT /api/v1/projects/{project_pk}/features/{id}/
# operationId: update_feature
# --multivariate_options item shape: {type?: any, integer_value?: int, string_value?: string, boolean_value?: bool, default_percentage_allocation?: float}
# --metadata item shape: {model_field: int, field_value: string}
# --code_references_counts item shape: {repository_url: string, count: int, last_successful_repository_scanned_at: string, last_feature_found_at: string}
export def "projects-features feature-by-id-project_pk" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: any
  --description: string # nullable
  --tags: list
  --multivariate-options: list # item shape: {type?: any, integer_value?: int, string_value?: string, boolean_value?: bool, default_percentage_allocation?: float}
  --is-archived: oneof<nothing, bool>
  --is-server-key-only: oneof<nothing, bool>
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, name: string, type: any, default_enabled: bool, initial_value: string, created_date: string, description: string, tags: list<int>, multivariate_options: table<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string>, is_archived: bool, owners: list<int>, group_owners: list<int>, uuid: string, project: int, environment_feature_state: any, segment_feature_state: any, num_segment_overrides: int, num_identity_overrides: int, is_num_identity_overrides_complete: bool, is_server_key_only: bool, last_modified_in_any_environment: string, last_modified_in_current_environment: string, metadata: table<id: int, model_field: int, field_value: string>, code_references_counts: table<repository_url: string, count: int, last_successful_repository_scanned_at: string, last_feature_found_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/")
  let body = {type: $type, description: $description, tags: $tags, multivariate_options: $multivariate_options, is_archived: $is_archived, is_server_key_only: $is_server_key_only, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/features/{id}/
#
# operationId: api_v1_projects_features_partial_update
# --multivariate_options item shape: {type?: any, integer_value?: int, string_value?: string, boolean_value?: bool, default_percentage_allocation?: float}
# --metadata item shape: {model_field: int, field_value: string}
# --code_references_counts item shape: {repository_url: string, count: int, last_successful_repository_scanned_at: string, last_feature_found_at: string}
export def "projects-features patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: any
  --description: string # nullable
  --tags: list
  --multivariate-options: list # item shape: {type?: any, integer_value?: int, string_value?: string, boolean_value?: bool, default_percentage_allocation?: float}
  --is-archived: oneof<nothing, bool>
  --is-server-key-only: oneof<nothing, bool>
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, name: string, type: any, default_enabled: bool, initial_value: string, created_date: string, description: string, tags: list<int>, multivariate_options: table<id: int, uuid: string, type: any, integer_value: int, string_value: string, boolean_value: bool, default_percentage_allocation: float, key: string>, is_archived: bool, owners: list<int>, group_owners: list<int>, uuid: string, project: int, environment_feature_state: any, segment_feature_state: any, num_segment_overrides: int, num_identity_overrides: int, is_num_identity_overrides_complete: bool, is_server_key_only: bool, last_modified_in_any_environment: string, last_modified_in_current_environment: string, metadata: table<id: int, model_field: int, field_value: string>, code_references_counts: table<repository_url: string, count: int, last_successful_repository_scanned_at: string, last_feature_found_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/")
  let body = {type: $type, description: $description, tags: $tags, multivariate_options: $multivariate_options, is_archived: $is_archived, is_server_key_only: $is_server_key_only, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/features/{id}/
#
# operationId: api_v1_projects_features_destroy
export def "projects-features delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/features/{id}/add-group-owners/
#
# operationId: api_v1_projects_features_add_group_owners_create
export def "projects-features-add-group-owners create" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group_ids: list
]: any -> record<id: int, name: string, created_date: string, description: string, initial_value: string, default_enabled: bool, type: any, owners: table<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, group_owners: table<id: int, name: string>, is_server_key_only: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/add-group-owners/")
  let body = {group_ids: $group_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/projects/{project_pk}/features/{id}/add-owners/
#
# operationId: api_v1_projects_features_add_owners_create
export def "projects-features-add-owners create" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list
]: any -> record<id: int, name: string, created_date: string, description: string, initial_value: string, default_enabled: bool, type: any, owners: table<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, group_owners: table<id: int, name: string>, is_server_key_only: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/add-owners/")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves evaluation data and analytics for a specific feature flag.
#
# GET /api/v1/projects/{project_pk}/features/{id}/evaluation-data/
# operationId: get_feature_evaluation_data
export def "projects-features-evaluation-data data" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-application-name: string
  --client-application-version: string
  --environment-id: int
  --period: int # number of days (default: 30)
  --user-agent: string
]: nothing -> record<day: string, count: int, labels: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_application_name" $client_application_name "scalar") (serialize-qp "client_application_version" $client_application_version "scalar") (serialize-qp "environment_id" $environment_id "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "user_agent" $user_agent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/evaluation-data/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Please use ​/api​/v1​/projects​/{project_pk}​/features​/{id}​/evaluation-data/
#
# GET /api/v1/projects/{project_pk}/features/{id}/influx-data/
# DEPRECATED
# operationId: api_v1_projects_features_influx_data_retrieve
@deprecated
export def "projects-features-influx-data get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --aggregate-every: string # default: 24h
  --environment-id: string
  --period: string # default: 24h
]: nothing -> record<events_list: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aggregate_every" $aggregate_every "scalar") (serialize-qp "environment_id" $environment_id "scalar") (serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/influx-data/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/features/{id}/remove-group-owners/
#
# operationId: api_v1_projects_features_remove_group_owners_create
export def "projects-features-remove-group-owners create" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group_ids: list
]: any -> record<id: int, name: string, created_date: string, description: string, initial_value: string, default_enabled: bool, type: any, owners: table<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, group_owners: table<id: int, name: string>, is_server_key_only: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/remove-group-owners/")
  let body = {group_ids: $group_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/projects/{project_pk}/features/{id}/remove-owners/
#
# operationId: api_v1_projects_features_remove_owners_create
export def "projects-features-remove-owners create" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list
]: any -> record<id: int, name: string, created_date: string, description: string, initial_value: string, default_enabled: bool, type: any, owners: table<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>, group_owners: table<id: int, name: string>, is_server_key_only: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/features/($id)/remove-owners/")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/gitlab/issues/
#
# operationId: api_v1_projects_gitlab_issues_list
export def "projects-gitlab-issues list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<page: int, page_size: int, gitlab_project_id: int, search_text: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/gitlab/issues/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/gitlab/merge-requests/
#
# operationId: api_v1_projects_gitlab_merge_requests_list
export def "projects-gitlab-merge-requests list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<page: int, page_size: int, gitlab_project_id: int, search_text: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/gitlab/merge-requests/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/gitlab/projects/
#
# operationId: api_v1_projects_gitlab_projects_list
export def "projects-gitlab-projects list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<page: int, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/gitlab/projects/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/imports/launch-darkly/
#
# operationId: api_v1_projects_imports_launch_darkly_list
export def "projects-imports-launch-darkly list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, created_by: string, created_at: string, updated_at: string, completed_at: string, status: record<requested_environment_count: int, requested_flag_count: int, deprecated_flag_count: int, result: any, error_messages: list>, project: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/imports/launch-darkly/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/imports/launch-darkly/
#
# operationId: api_v1_projects_imports_launch_darkly_create
export def "projects-imports-launch-darkly create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
  project_key: string
]: any -> record<id: int, created_by: string, created_at: string, updated_at: string, completed_at: string, status: record<requested_environment_count: int, requested_flag_count: int, deprecated_flag_count: int, result: any, error_messages: list<string>>, project: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/imports/launch-darkly/")
  let body = {token: $body_token, project_key: $project_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/imports/launch-darkly/{id}/
#
# operationId: api_v1_projects_imports_launch_darkly_retrieve
export def "projects-imports-launch-darkly get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, created_by: string, created_at: string, updated_at: string, completed_at: string, status: record<requested_environment_count: int, requested_flag_count: int, deprecated_flag_count: int, result: any, error_messages: list<string>>, project: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/imports/launch-darkly/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/integrations/datadog/
#
# operationId: api_v1_projects_integrations_datadog_list
export def "projects-integrations-datadog list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, base_url: string, api_key: string, use_custom_source: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/datadog/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/integrations/datadog/
#
# operationId: api_v1_projects_integrations_datadog_create
export def "projects-integrations-datadog create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # format: uri
  api_key: string
  --use-custom-source: oneof<nothing, bool>
]: any -> record<id: int, base_url: string, api_key: string, use_custom_source: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/datadog/")
  let body = {base_url: $body_base_url, api_key: $api_key, use_custom_source: $use_custom_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/integrations/datadog/{id}/
#
# operationId: api_v1_projects_integrations_datadog_retrieve
export def "projects-integrations-datadog get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, base_url: string, api_key: string, use_custom_source: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/datadog/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/integrations/datadog/{id}/
#
# operationId: api_v1_projects_integrations_datadog_update
export def "projects-integrations-datadog update" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # format: uri
  api_key: string
  --use-custom-source: oneof<nothing, bool>
]: any -> record<id: int, base_url: string, api_key: string, use_custom_source: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/datadog/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key, use_custom_source: $use_custom_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/integrations/datadog/{id}/
#
# operationId: api_v1_projects_integrations_datadog_partial_update
export def "projects-integrations-datadog patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # format: uri
  --api-key: string
  --use-custom-source: oneof<nothing, bool>
]: any -> record<id: int, base_url: string, api_key: string, use_custom_source: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/datadog/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key, use_custom_source: $use_custom_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/integrations/datadog/{id}/
#
# operationId: api_v1_projects_integrations_datadog_destroy
export def "projects-integrations-datadog delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/datadog/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/integrations/gitlab/
#
# operationId: api_v1_projects_integrations_gitlab_list
export def "projects-integrations-gitlab list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, gitlab_instance_url: string, access_token: string, labeling_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/gitlab/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/integrations/gitlab/
#
# operationId: api_v1_projects_integrations_gitlab_create
export def "projects-integrations-gitlab create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gitlab_instance_url: string # format: uri
  access_token: string
  --labeling-enabled: oneof<nothing, bool>
]: any -> record<id: int, gitlab_instance_url: string, access_token: string, labeling_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/gitlab/")
  let body = {gitlab_instance_url: $gitlab_instance_url, access_token: $access_token, labeling_enabled: $labeling_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/integrations/gitlab/{id}/
#
# operationId: api_v1_projects_integrations_gitlab_retrieve
export def "projects-integrations-gitlab get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, gitlab_instance_url: string, access_token: string, labeling_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/gitlab/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/integrations/gitlab/{id}/
#
# operationId: api_v1_projects_integrations_gitlab_update
export def "projects-integrations-gitlab update" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gitlab_instance_url: string # format: uri
  access_token: string
  --labeling-enabled: oneof<nothing, bool>
]: any -> record<id: int, gitlab_instance_url: string, access_token: string, labeling_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/gitlab/($id)/")
  let body = {gitlab_instance_url: $gitlab_instance_url, access_token: $access_token, labeling_enabled: $labeling_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/integrations/gitlab/{id}/
#
# operationId: api_v1_projects_integrations_gitlab_partial_update
export def "projects-integrations-gitlab patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gitlab-instance-url: string # format: uri
  --access-token: string
  --labeling-enabled: oneof<nothing, bool>
]: any -> record<id: int, gitlab_instance_url: string, access_token: string, labeling_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/gitlab/($id)/")
  let body = {gitlab_instance_url: $gitlab_instance_url, access_token: $access_token, labeling_enabled: $labeling_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/integrations/gitlab/{id}/
#
# operationId: api_v1_projects_integrations_gitlab_destroy
export def "projects-integrations-gitlab delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/gitlab/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/integrations/grafana/
#
# operationId: api_v1_projects_integrations_grafana_list
export def "projects-integrations-grafana list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, base_url: string, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/grafana/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/integrations/grafana/
#
# operationId: api_v1_projects_integrations_grafana_create
export def "projects-integrations-grafana create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/grafana/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/integrations/grafana/{id}/
#
# operationId: api_v1_projects_integrations_grafana_retrieve
export def "projects-integrations-grafana get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, base_url: string, api_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/grafana/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/integrations/grafana/{id}/
#
# operationId: api_v1_projects_integrations_grafana_update
export def "projects-integrations-grafana update" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/grafana/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/integrations/grafana/{id}/
#
# operationId: api_v1_projects_integrations_grafana_partial_update
export def "projects-integrations-grafana patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  --api-key: string
]: any -> record<id: int, base_url: string, api_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/grafana/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/integrations/grafana/{id}/
#
# operationId: api_v1_projects_integrations_grafana_destroy
export def "projects-integrations-grafana delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/grafana/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/integrations/new-relic/
#
# operationId: api_v1_projects_integrations_new_relic_list
export def "projects-integrations-new-relic list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, base_url: string, api_key: string, app_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/new-relic/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/integrations/new-relic/
#
# operationId: api_v1_projects_integrations_new_relic_create
export def "projects-integrations-new-relic create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
  app_id: string
]: any -> record<id: int, base_url: string, api_key: string, app_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/new-relic/")
  let body = {base_url: $body_base_url, api_key: $api_key, app_id: $app_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/integrations/new-relic/{id}/
#
# operationId: api_v1_projects_integrations_new_relic_retrieve
export def "projects-integrations-new-relic get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, base_url: string, api_key: string, app_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/new-relic/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/integrations/new-relic/{id}/
#
# operationId: api_v1_projects_integrations_new_relic_update
export def "projects-integrations-new-relic update" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  api_key: string
  app_id: string
]: any -> record<id: int, base_url: string, api_key: string, app_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/new-relic/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key, app_id: $app_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/integrations/new-relic/{id}/
#
# operationId: api_v1_projects_integrations_new_relic_partial_update
export def "projects-integrations-new-relic patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-base-url: string # nullable, format: uri
  --api-key: string
  --app-id: string
]: any -> record<id: int, base_url: string, api_key: string, app_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/new-relic/($id)/")
  let body = {base_url: $body_base_url, api_key: $api_key, app_id: $app_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/integrations/new-relic/{id}/
#
# operationId: api_v1_projects_integrations_new_relic_destroy
export def "projects-integrations-new-relic delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/integrations/new-relic/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/metadata/fields/
#
# operationId: api_v1_projects_metadata_fields_list
export def "projects-metadata-fields list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity: string@entity-completer # Filter by entity type (feature, segment, or environment).  * `feature` - feature * `segment` - segment * `environment` - environment
  --include-organisation: oneof<nothing, bool> # Include inherited organisation-level fields. Project-level fields override same-named org fields. (default: false)
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, type: string, description: string, organisation: int, project: int, model_fields: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity" $entity "scalar") (serialize-qp "include_organisation" $include_organisation "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/metadata/fields/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/metadata/fields/{id}/
#
# operationId: api_v1_projects_metadata_fields_retrieve
export def "projects-metadata-fields get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, type: string, description: string, organisation: int, project: int, model_fields: table<id: int, content_type: int, is_required_for: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/metadata/fields/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all release pipelines configured for the specified project.
#
# GET /api/v1/projects/{project_pk}/release-pipelines/
# operationId: list_project_release_pipelines
export def "projects-release-pipelines pipelines" [
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ordering: string # Which field to use when ordering the results.
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/release-pipelines/
#
# operationId: api_v1_projects_release_pipelines_create
# --stages item shape: {name: string, environment: int, order: int, trigger: record, actions: list}
export def "projects-release-pipelines create" [
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --published-at: string # nullable, format: date-time
  --published-by: int # nullable
  stages: list # item shape: {name: string, environment: int, order: int, trigger: record, actions: list}
]: any -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>, stages: table<id: int, name: string, pipeline: int, environment: int, order: int, trigger: record, actions: list, features: string>, completed_features: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/")
  let body = {name: $name, description: $description, published_at: $published_at, published_by: $published_by, stages: $stages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves detailed information about a specific release pipeline.
#
# GET /api/v1/projects/{project_pk}/release-pipelines/{id}/
# operationId: get_release_pipeline
export def "projects-release-pipelines pipeline" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>, stages: table<id: int, name: string, pipeline: int, environment: int, order: int, trigger: record, actions: list, features: string>, completed_features: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/release-pipelines/{id}/
#
# operationId: api_v1_projects_release_pipelines_update
# --stages item shape: {name: string, environment: int, order: int, trigger: record, actions: list}
export def "projects-release-pipelines update" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --published-at: string # nullable, format: date-time
  --published-by: int # nullable
  stages: list # item shape: {name: string, environment: int, order: int, trigger: record, actions: list}
]: any -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>, stages: table<id: int, name: string, pipeline: int, environment: int, order: int, trigger: record, actions: list, features: string>, completed_features: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/")
  let body = {name: $name, description: $description, published_at: $published_at, published_by: $published_by, stages: $stages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/release-pipelines/{id}/
#
# operationId: api_v1_projects_release_pipelines_partial_update
export def "projects-release-pipelines patch" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string # nullable
  --published-at: string # nullable, format: date-time
  --published-by: int # nullable
]: any -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/")
  let body = {name: $name, description: $description, published_at: $published_at, published_by: $published_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/release-pipelines/{id}/
#
# operationId: api_v1_projects_release_pipelines_destroy
export def "projects-release-pipelines delete" [
  id: string
  project_pk: string
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a feature flag to a release pipeline for staged rollout.
#
# POST /api/v1/projects/{project_pk}/release-pipelines/{id}/add-feature/
# operationId: add_feature_to_release_pipeline
export def "projects-release-pipelines-add-feature pipeline" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --published-at: string # nullable, format: date-time
  --published-by: int # nullable
]: any -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/add-feature/")
  let body = {name: $name, description: $description, published_at: $published_at, published_by: $published_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/projects/{project_pk}/release-pipelines/{id}/clone/
#
# operationId: api_v1_projects_release_pipelines_clone_create
# --stages item shape: {name: string, environment: int, order: int, trigger: record, actions: list}
export def "projects-release-pipelines-clone create" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --published-at: string # nullable, format: date-time
  --published-by: int # nullable
  stages: list # item shape: {name: string, environment: int, order: int, trigger: record, actions: list}
]: any -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>, stages: table<id: int, name: string, pipeline: int, environment: int, order: int, trigger: record, actions: list, features: string>, completed_features: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/clone/")
  let body = {name: $name, description: $description, published_at: $published_at, published_by: $published_by, stages: $stages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/projects/{project_pk}/release-pipelines/{id}/publish-pipeline/
#
# operationId: api_v1_projects_release_pipelines_publish_pipeline_create
export def "projects-release-pipelines-publish-pipeline create" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --published-at: string # nullable, format: date-time
  --published-by: int # nullable
]: any -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/publish-pipeline/")
  let body = {name: $name, description: $description, published_at: $published_at, published_by: $published_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/projects/{project_pk}/release-pipelines/{id}/remove-feature/
#
# operationId: api_v1_projects_release_pipelines_remove_feature_create
export def "projects-release-pipelines-remove-feature create" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --published-at: string # nullable, format: date-time
  --published-by: int # nullable
]: any -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/remove-feature/")
  let body = {name: $name, description: $description, published_at: $published_at, published_by: $published_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/projects/{project_pk}/release-pipelines/{id}/unpublish-pipeline/
#
# operationId: api_v1_projects_release_pipelines_unpublish_pipeline_create
export def "projects-release-pipelines-unpublish-pipeline create" [
  id: string
  project_pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  --published-at: string # nullable, format: date-time
  --published-by: int # nullable
]: any -> record<id: int, name: string, project: int, description: string, stages_count: int, published_at: string, published_by: int, features: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/release-pipelines/($id)/unpublish-pipeline/")
  let body = {name: $name, description: $description, published_at: $published_at, published_by: $published_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves all user segments defined for audience targeting within the project.
#
# GET /api/v1/projects/{project_pk}/segments/
# operationId: list_project_segments
export def "projects-segments segments" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # Optionally provide the id of an identity to get only the segments they match
  --include-feature-specific: oneof<nothing, bool> # default: true
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --q: string # Search term to find segment with given term in their name
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: list, metadata: list, membership_counts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity" $identity "scalar") (serialize-qp "include_feature_specific" $include_feature_specific "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/segments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new user segment for audience targeting within the project.
#
# POST /api/v1/projects/{project_pk}/segments/
# operationId: create_project_segment
# --rules item shape: {type: "ALL"|"ANY"|"NONE", rules?: list, conditions?: list, delete?: bool}
# --metadata item shape: {model_field: int, field_value: string}
export def "projects-segments segment-by-project_pk" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  project: int
  --feature: int # nullable
  --version-of: int # nullable
  rules: list # item shape: {type: "ALL"|"ANY"|"NONE", rules?: list, conditions?: list, delete?: bool}
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: table<id: int, type: string, rules: list, conditions: list, delete: bool>, metadata: table<id: int, model_field: int, field_value: string>, membership_counts: table<environment: int, count: int, last_synced_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/segments/")
  let body = {name: $name, description: $description, project: $project, feature: $feature, version_of: $version_of, rules: $rules, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves detailed information about a specific user segment.
#
# GET /api/v1/projects/{project_pk}/segments/{id}/
# operationId: get_project_segment
export def "projects-segments segment-by-id-project_pk" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: table<id: int, type: string, rules: list, conditions: list, delete: bool>, metadata: table<id: int, model_field: int, field_value: string>, membership_counts: table<environment: int, count: int, last_synced_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/segments/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing user segment's properties and rules.
#
# PUT /api/v1/projects/{project_pk}/segments/{id}/
# operationId: update_project_segment
# --rules item shape: {type: "ALL"|"ANY"|"NONE", rules?: list, conditions?: list, delete?: bool}
# --metadata item shape: {model_field: int, field_value: string}
export def "projects-segments segment-by-id-project_pk-1" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: string # nullable
  project: int
  --feature: int # nullable
  --version-of: int # nullable
  rules: list # item shape: {type: "ALL"|"ANY"|"NONE", rules?: list, conditions?: list, delete?: bool}
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: table<id: int, type: string, rules: list, conditions: list, delete: bool>, metadata: table<id: int, model_field: int, field_value: string>, membership_counts: table<environment: int, count: int, last_synced_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/segments/($id)/")
  let body = {name: $name, description: $description, project: $project, feature: $feature, version_of: $version_of, rules: $rules, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/segments/{id}/
#
# operationId: api_v1_projects_segments_partial_update
# --rules item shape: {type: "ALL"|"ANY"|"NONE", rules?: list, conditions?: list, delete?: bool}
# --metadata item shape: {model_field: int, field_value: string}
export def "projects-segments patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string # nullable
  --project: int
  --feature: int # nullable
  --version-of: int # nullable
  --rules: list # item shape: {type: "ALL"|"ANY"|"NONE", rules?: list, conditions?: list, delete?: bool}
  --metadata: list # item shape: {model_field: int, field_value: string}
]: any -> record<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: table<id: int, type: string, rules: list, conditions: list, delete: bool>, metadata: table<id: int, model_field: int, field_value: string>, membership_counts: table<environment: int, count: int, last_synced_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/segments/($id)/")
  let body = {name: $name, description: $description, project: $project, feature: $feature, version_of: $version_of, rules: $rules, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/segments/{id}/
#
# operationId: api_v1_projects_segments_destroy
export def "projects-segments delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/segments/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/segments/{id}/associated-features/
#
# operationId: api_v1_projects_segments_associated_features_retrieve
export def "projects-segments-associated-features get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: int
]: nothing -> record<id: int, feature: int, environment: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/segments/($id)/associated-features/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/segments/{id}/clone/
#
# operationId: api_v1_projects_segments_clone_create
export def "projects-segments-clone create" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: table<id: int, type: string, rules: list, conditions: list, delete: bool>, metadata: table<id: int, model_field: int, field_value: string>, membership_counts: table<environment: int, count: int, last_synced_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/segments/($id)/clone/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/tags/
#
# operationId: api_v1_projects_tags_list
export def "projects-tags list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A page number within the paginated result set.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, label: string, color: string, description: string, project: int, uuid: string, is_permanent: bool, is_system_tag: bool, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/tags/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/tags/
#
# operationId: api_v1_projects_tags_create
export def "projects-tags create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string
  --color: string # Hexadecimal value of the tag color
  --description: string # nullable
  --is-permanent: oneof<nothing, bool> # When applied to a feature, it means this feature should be excluded from stale flags logic.
]: any -> record<id: int, label: string, color: string, description: string, project: int, uuid: string, is_permanent: bool, is_system_tag: bool, type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/tags/")
  let body = {label: $label, color: $color, description: $description, is_permanent: $is_permanent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/tags/{id}/
#
# operationId: api_v1_projects_tags_retrieve
export def "projects-tags get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, label: string, color: string, description: string, project: int, uuid: string, is_permanent: bool, is_system_tag: bool, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/tags/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/tags/{id}/
#
# operationId: api_v1_projects_tags_update
export def "projects-tags update" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string
  --color: string # Hexadecimal value of the tag color
  --description: string # nullable
  --is-permanent: oneof<nothing, bool> # When applied to a feature, it means this feature should be excluded from stale flags logic.
]: any -> record<id: int, label: string, color: string, description: string, project: int, uuid: string, is_permanent: bool, is_system_tag: bool, type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/tags/($id)/")
  let body = {label: $label, color: $color, description: $description, is_permanent: $is_permanent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/tags/{id}/
#
# operationId: api_v1_projects_tags_partial_update
export def "projects-tags patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string
  --color: string # Hexadecimal value of the tag color
  --description: string # nullable
  --is-permanent: oneof<nothing, bool> # When applied to a feature, it means this feature should be excluded from stale flags logic.
]: any -> record<id: int, label: string, color: string, description: string, project: int, uuid: string, is_permanent: bool, is_system_tag: bool, type: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/tags/($id)/")
  let body = {label: $label, color: $color, description: $description, is_permanent: $is_permanent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/tags/{id}/
#
# operationId: api_v1_projects_tags_destroy
export def "projects-tags delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/tags/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/tags/get-by-uuid/{uuid}/
#
# operationId: api_v1_projects_tags_get_by_uuid_retrieve
export def "projects-tags-get-by-uuid get" [
  project_pk: int
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, label: string, color: string, description: string, project: int, uuid: string, is_permanent: bool, is_system_tag: bool, type: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/tags/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/user-group-permissions/
#
# operationId: api_v1_projects_user_group_permissions_list
export def "projects-user-group-permissions list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, permissions: list<string>, admin: bool, group: record<id: int, name: string, users: list, is_default: bool, external_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-group-permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/user-group-permissions/
#
# operationId: api_v1_projects_user_group_permissions_create
export def "projects-user-group-permissions create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  group: int
]: any -> record<id: int, permissions: list<string>, admin: bool, group: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-group-permissions/")
  let body = {permissions: $permissions, admin: $admin, group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/user-group-permissions/{id}/
#
# operationId: api_v1_projects_user_group_permissions_retrieve
export def "projects-user-group-permissions get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, permissions: list<string>, admin: bool, group: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-group-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/user-group-permissions/{id}/
#
# operationId: api_v1_projects_user_group_permissions_update
export def "projects-user-group-permissions update" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  group: int
]: any -> record<id: int, permissions: list<string>, admin: bool, group: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-group-permissions/($id)/")
  let body = {permissions: $permissions, admin: $admin, group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/user-group-permissions/{id}/
#
# operationId: api_v1_projects_user_group_permissions_partial_update
export def "projects-user-group-permissions patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  --group: int
]: any -> record<id: int, permissions: list<string>, admin: bool, group: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-group-permissions/($id)/")
  let body = {permissions: $permissions, admin: $admin, group: $group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/user-group-permissions/{id}/
#
# operationId: api_v1_projects_user_group_permissions_destroy
export def "projects-user-group-permissions delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-group-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/{project_pk}/user-permissions/
#
# operationId: api_v1_projects_user_permissions_list
export def "projects-user-permissions list" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, permissions: list<string>, admin: bool, user: record<id: int, email: string, first_name: string, last_name: string, last_login: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/projects/{project_pk}/user-permissions/
#
# operationId: api_v1_projects_user_permissions_create
export def "projects-user-permissions create" [
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  user: int
]: any -> record<id: int, permissions: list<string>, admin: bool, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-permissions/")
  let body = {permissions: $permissions, admin: $admin, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/projects/{project_pk}/user-permissions/{id}/
#
# operationId: api_v1_projects_user_permissions_retrieve
export def "projects-user-permissions get" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, permissions: list<string>, admin: bool, user: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/projects/{project_pk}/user-permissions/{id}/
#
# operationId: api_v1_projects_user_permissions_update
export def "projects-user-permissions update" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  user: int
]: any -> record<id: int, permissions: list<string>, admin: bool, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-permissions/($id)/")
  let body = {permissions: $permissions, admin: $admin, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/projects/{project_pk}/user-permissions/{id}/
#
# operationId: api_v1_projects_user_permissions_partial_update
export def "projects-user-permissions patch" [
  id: int
  project_pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --permissions: list
  --admin: oneof<nothing, bool>
  --user: int
]: any -> record<id: int, permissions: list<string>, admin: bool, user: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-permissions/($id)/")
  let body = {permissions: $permissions, admin: $admin, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/projects/{project_pk}/user-permissions/{id}/
#
# operationId: api_v1_projects_user_permissions_destroy
export def "projects-user-permissions delete" [
  id: int
  project_pk: int
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
  let full_url = (build-url $base $"/api/v1/projects/($project_pk)/user-permissions/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/get-by-uuid/{uuid}/
#
# operationId: api_v1_projects_get_by_uuid_retrieve
export def "projects-get-by-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, name: string, organisation: int, hide_disabled_flags: bool, enable_dynamo_db: bool, migration_status: string, use_edge_identities: bool, prevent_flag_defaults: bool, enable_realtime_updates: bool, only_allow_lower_case_feature_names: bool, feature_name_regex: string, show_edge_identity_overrides_for_feature: bool, stale_flags_limit_days: int, edge_v2_migration_status: record, minimum_change_request_approvals: int, enforce_feature_owners: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/projects/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/projects/permissions/
#
# operationId: api_v1_projects_permissions_list
export def "projects-permissions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, description: string, supports_tag: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/projects/permissions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/segments/get-by-uuid/{uuid}/
#
# operationId: api_v1_segments_get_by_uuid_retrieve
export def "segments-get-by-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, created_at: string, updated_at: string, name: string, description: string, project: int, feature: int, version_of: int, rules: table<id: int, type: string, rules: list, conditions: list, delete: bool>, metadata: table<id: int, model_field: int, field_value: string>, membership_counts: table<environment: int, count: int, last_synced_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/segments/get-by-uuid/($uuid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/traits/
#
# operationId: api_v1_traits_create
# --identity shape: {identifier: string}
export def "traits create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identity: record # shape: {identifier: string}
  trait_value: string # Can be string, integer, float, or boolean
  trait_key: string
]: any -> record<identity: record<identifier: string>, trait_value: string, trait_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/traits/")
  let body = {identity: $identity, trait_value: $trait_value, trait_key: $trait_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/traits/bulk/
#
# operationId: api_v1_traits_bulk_update
export def "traits-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<identity: record<identifier: string>, trait_value: string, trait_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/traits/bulk/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/traits/increment-value/
#
# operationId: api_v1_traits_increment_value_create
export def "traits-increment-value create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  trait_key: string
  increment_by: int
  identifier: string
]: any -> record<trait_key: string, increment_by: int, identifier: string, trait_value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/traits/increment-value/")
  let body = {trait_key: $trait_key, increment_by: $increment_by, identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/users/join/{hash}/
#
# operationId: api_v1_users_join_create
export def "users-join create" [
  hash: string
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
  let full_url = (build-url $base $"/api/v1/users/join/($hash)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/users/join/link/{hash}/
#
# operationId: api_v1_users_join_link_create
export def "users-join-link create" [
  hash: string
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
  let full_url = (build-url $base $"/api/v1/users/join/link/($hash)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/webhooks/test/
#
# operationId: api_v1_webhooks_test_create
# --scope shape: {type: "organisation"|"environment"}
export def "webhooks-test create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook_url: string # format: uri
  scope: record # shape: {type: "organisation"|"environment"}
  --secret: string # nullable
]: any -> record<detail: string, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/webhooks/test/")
  let body = {webhook_url: $webhook_url, scope: $scope, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v2/analytics/flags/
#
# operationId: api_v2_analytics_flags_create
# --evaluations item shape: {feature_name: string, identity_identifier?: string, enabled_when_evaluated: bool, count: int}
export def "analytics-flags create-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  evaluations: list # item shape: {feature_name: string, identity_identifier?: string, enabled_when_evaluated: bool, count: int}
]: any -> record<evaluations: table<feature_name: string, identity_identifier: string, enabled_when_evaluated: bool, count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/analytics/flags/")
  let body = {evaluations: $evaluations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RFC 7591 Dynamic Client Registration endpoint.
#
# POST /o/register/
# operationId: o_register_create
export def "o-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-environment-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/o/register/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /processor/monitoring/
#
# operationId: processor_monitoring_retrieve
export def "processor-monitoring get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<waiting: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/monitoring/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
