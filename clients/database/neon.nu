# Auto-generated client for Neon API vv2
# Source: https://neon.com/api_spec/release/v2.json
# Auth: --token flag or $env.NEON_API_TOKEN

const BASE_URL = "https://console.neon.tech/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NEON_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "cookie-zenith" => { {headers: {Cookie: $"zenith=($token_val)"}, query: ""} }
    "cookie-keycloak_token" => { {headers: {Cookie: $"keycloak_token=($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://console.neon.tech/api/v2"] }
def auth-scheme-completer [] { ["bearer" "cookie-zenith" "cookie-keycloak_token"] }

# Completers for enum parameters
def category-completer [] { ["PERFORMANCE" "SECURITY"] }
def min-severity-completer [] { ["ERROR" "INFO" "WARN"] }
def auth-provider-completer [] { ["external" "neon_auth"] }
def auth-provider-completer-1 [] { ["better_auth" "mock" "stack"] }
def id-completer [] { ["github" "google" "microsoft" "vercel"] }
def email-verification-method-completer [] { ["link" "otp"] }
def creator-role-completer [] { ["admin" "owner"] }
def sort-by-completer [] { ["created_at" "name" "updated_at"] }
def sort-order-completer [] { ["asc" "desc"] }
def granularity-completer [] { ["daily" "hourly" "monthly"] }
def sort-by-completer-1 [] { ["email" "joined_at" "role"] }
def role-completer [] { ["admin" "collaborator" "editor" "member" "viewer"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "projects-advisors get" } } | get name | first)
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

# Get advisor issues
#
# GET /projects/{project_id}/advisors
# operationId: getProjectAdvisorSecurityIssues
export def "projects-advisors get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-id: string # Branch ID to analyze. If not specified, the project's default branch is used.
  --database-name: string # Database name to analyze. Required if branch has multiple databases.
  --category: string@category-completer # Filter issues by category
  --min-severity: string@min-severity-completer # Minimum severity level to include. For example, WARN returns WARN and ERROR issues, excluding INFO.
]: nothing -> record<issues: table<name: string, title: string, level: string, facing: string, categories: list, description: string, detail: string, remediation: string, metadata: record, cache_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "database_name" $database_name "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "min_severity" $min_severity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/advisors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List API keys
#
# GET /api_keys
# operationId: listApiKeys
export def "api-keys listApiKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string, created_at: string, created_by: record<id: string, name: string, image: string>, last_used_at: string, last_used_from_addr: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create API key
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
  --dry-run(-n) # Return the request that would be sent without executing it
  key_name: string # A user-specified API key name. This value is required when creating an API key.
]: any -> record<id: int, key: string, name: string, created_at: string, created_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_keys")
  let body = {key_name: $key_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke API key
#
# DELETE /api_keys/{key_id}
# operationId: revokeApiKey
export def "api-keys revokeApiKey" [
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, created_at: string, created_by: string, last_used_at: string, last_used_from_addr: string, revoked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve operation details
#
# GET /projects/{project_id}/operations/{operation_id}
# operationId: getProjectOperation
export def "projects-operations get" [
  project_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<operation: record<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/operations/($operation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List projects
#
# GET /projects
# operationId: listProjects
export def "projects listProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Specify the cursor value from the previous response to retrieve the next batch of projects.
  --limit: int # Specify a value from 1 to 400 to limit number of projects in the response. (default: 10)
  --search: string # Search by project `name` or `id`. You can specify partial `name` or `id` values to filter results.
  --org-id: string # Search for projects by `org_id`.
  --timeout: int # Specify an explicit timeout in milliseconds to limit response delay. After timing out, the incomplete list of project data fetched so far will be returned. Projects still being fetched when the timeout occurred are listed in the "unavailable" attribute of the response. If not specified, an implicit implementation defined timeout is chosen with the same behaviour as above
  --recoverable: oneof<nothing, bool> # Show only deleted projects within the recovery window.  (default: false)
]: nothing -> record<projects: table<id: string, platform_id: string, region_id: string, name: string, provisioner: string, default_endpoint_settings: record, settings: record, pg_version: int, proxy_host: string, branch_logical_size_limit: int, branch_logical_size_limit_bytes: int, store_passwords: bool, active_time: int, cpu_used_sec: int, maintenance_starts_at: string, creation_source: string, created_at: string, updated_at: string, synthetic_storage_size: int, quota_reset_at: string, owner_id: string, compute_last_active_at: string, org_id: string, org_name: string, history_retention_seconds: int, hipaa_enabled_at: string, deleted_at: string, recoverable_until: string, effective_project_permission: string>, unavailable_project_ids: list<string>, pagination: record<cursor: string>, applications: record, integrations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "org_id" $org_id "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "recoverable" $recoverable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create project
#
# POST /projects
# operationId: createProject
# --project shape: {settings?: record, name?: string, branch?: record, autoscaling_limit_min_cu?: float, autoscaling_limit_max_cu?: float, provisioner?: string, region_id?: string, default_endpoint_settings?: record, pg_version?: int, store_passwords?: bool, history_retention_seconds?: int, org_id?: string}
export def "projects createProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project: record # shape: {settings?: record, name?: string, branch?: record, autoscaling_limit_min_cu?: float, autoscaling_limit_max_cu?: float, provisioner?: string, region_id?: string, default_endpoint_settings?: record, pg_version?: int, store_passwords?: bool, history_retention_seconds?: int, org_id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List shared projects
#
# GET /projects/shared
# operationId: listSharedProjects
export def "projects-shared listSharedProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Specify the cursor value from the previous response to get the next batch of projects.
  --limit: int # Specify a value from 1 to 400 to limit number of projects in the response. (default: 10)
  --search: string # Search query by name or id.
  --timeout: int # Specify an explicit timeout in milliseconds to limit response delay. After timing out, the incomplete list of project data fetched so far will be returned. Projects still being fetched when the timeout occurred are listed in the "unavailable" attribute of the response. If not specified, an implicit implementation defined timeout is chosen with the same behaviour as above
]: nothing -> record<projects: table<id: string, platform_id: string, region_id: string, name: string, provisioner: string, default_endpoint_settings: record, settings: record, pg_version: int, proxy_host: string, branch_logical_size_limit: int, branch_logical_size_limit_bytes: int, store_passwords: bool, active_time: int, cpu_used_sec: int, maintenance_starts_at: string, creation_source: string, created_at: string, updated_at: string, synthetic_storage_size: int, quota_reset_at: string, owner_id: string, compute_last_active_at: string, org_id: string, org_name: string, history_retention_seconds: int, hipaa_enabled_at: string, deleted_at: string, recoverable_until: string, effective_project_permission: string>, unavailable_project_ids: list<string>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/shared" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve project details
#
# GET /projects/{project_id}
# operationId: getProject
export def "projects get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project: record<data_storage_bytes_hour: int, data_transfer_bytes: int, written_data_bytes: int, compute_time_seconds: int, active_time_seconds: int, cpu_used_sec: int, id: string, platform_id: string, region_id: string, name: string, provisioner: string, default_endpoint_settings: record<pg_settings: record, pgbouncer_settings: record, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, suspend_timeout_seconds: int>, settings: record<quota: record, allowed_ips: record, enable_logical_replication: bool, maintenance_window: record, block_public_connections: bool, block_vpc_connections: bool, audit_log_level: string, hipaa: bool, preload_libraries: record>, pg_version: int, proxy_host: string, branch_logical_size_limit: int, branch_logical_size_limit_bytes: int, store_passwords: bool, maintenance_starts_at: string, creation_source: string, history_retention_seconds: int, created_at: string, updated_at: string, synthetic_storage_size: int, consumption_period_start: string, consumption_period_end: string, quota_reset_at: string, owner_id: string, owner: record<email: string, name: string, branches_limit: int, subscription_type: string>, compute_last_active_at: string, org_id: string, maintenance_scheduled_for: string, hipaa_enabled_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project
#
# PATCH /projects/{project_id}
# operationId: updateProject
# --project shape: {settings?: record, name?: string, default_endpoint_settings?: record, history_retention_seconds?: int}
export def "projects updateProject" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project: record # shape: {settings?: record, name?: string, default_endpoint_settings?: record, history_retention_seconds?: int}
]: any -> record<project: record<data_storage_bytes_hour: int, data_transfer_bytes: int, written_data_bytes: int, compute_time_seconds: int, active_time_seconds: int, cpu_used_sec: int, id: string, platform_id: string, region_id: string, name: string, provisioner: string, default_endpoint_settings: record<pg_settings: record, pgbouncer_settings: record, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, suspend_timeout_seconds: int>, settings: record<quota: record, allowed_ips: record, enable_logical_replication: bool, maintenance_window: record, block_public_connections: bool, block_vpc_connections: bool, audit_log_level: string, hipaa: bool, preload_libraries: record>, pg_version: int, proxy_host: string, branch_logical_size_limit: int, branch_logical_size_limit_bytes: int, store_passwords: bool, maintenance_starts_at: string, creation_source: string, history_retention_seconds: int, created_at: string, updated_at: string, synthetic_storage_size: int, consumption_period_start: string, consumption_period_end: string, quota_reset_at: string, owner_id: string, owner: record<email: string, name: string, branches_limit: int, subscription_type: string>, compute_last_active_at: string, org_id: string, maintenance_scheduled_for: string, hipaa_enabled_at: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)")
  let body = {project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete project
#
# DELETE /projects/{project_id}
# operationId: deleteProject
export def "projects delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project: record<data_storage_bytes_hour: int, data_transfer_bytes: int, written_data_bytes: int, compute_time_seconds: int, active_time_seconds: int, cpu_used_sec: int, id: string, platform_id: string, region_id: string, name: string, provisioner: string, default_endpoint_settings: record<pg_settings: record, pgbouncer_settings: record, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, suspend_timeout_seconds: int>, settings: record<quota: record, allowed_ips: record, enable_logical_replication: bool, maintenance_window: record, block_public_connections: bool, block_vpc_connections: bool, audit_log_level: string, hipaa: bool, preload_libraries: record>, pg_version: int, proxy_host: string, branch_logical_size_limit: int, branch_logical_size_limit_bytes: int, store_passwords: bool, maintenance_starts_at: string, creation_source: string, history_retention_seconds: int, created_at: string, updated_at: string, synthetic_storage_size: int, consumption_period_start: string, consumption_period_end: string, quota_reset_at: string, owner_id: string, owner: record<email: string, name: string, branches_limit: int, subscription_type: string>, compute_last_active_at: string, org_id: string, maintenance_scheduled_for: string, hipaa_enabled_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recover a deleted project
#
# POST /projects/{project_id}/recover
# operationId: recoverProject
export def "projects-recover recoverProject" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project: record<data_storage_bytes_hour: int, data_transfer_bytes: int, written_data_bytes: int, compute_time_seconds: int, active_time_seconds: int, cpu_used_sec: int, id: string, platform_id: string, region_id: string, name: string, provisioner: string, default_endpoint_settings: record<pg_settings: record, pgbouncer_settings: record, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, suspend_timeout_seconds: int>, settings: record<quota: record, allowed_ips: record, enable_logical_replication: bool, maintenance_window: record, block_public_connections: bool, block_vpc_connections: bool, audit_log_level: string, hipaa: bool, preload_libraries: record>, pg_version: int, proxy_host: string, branch_logical_size_limit: int, branch_logical_size_limit_bytes: int, store_passwords: bool, maintenance_starts_at: string, creation_source: string, history_retention_seconds: int, created_at: string, updated_at: string, synthetic_storage_size: int, consumption_period_start: string, consumption_period_end: string, quota_reset_at: string, owner_id: string, owner: record<email: string, name: string, branches_limit: int, subscription_type: string>, compute_last_active_at: string, org_id: string, maintenance_scheduled_for: string, hipaa_enabled_at: string>, branches: table<id: string, project_id: string, parent_id: string, parent_lsn: string, parent_timestamp: string, name: string, current_state: string, pending_state: string, state_changed_at: string, logical_size: int, creation_source: string, primary: bool, default: bool, protected: bool, cpu_used_sec: int, compute_time_seconds: int, active_time_seconds: int, written_data_bytes: int, data_transfer_bytes: int, created_at: string, updated_at: string, ttl_interval_seconds: int, expires_at: string, last_reset_at: string, created_by: record, init_source: string, restore_status: string, restored_from: string, restored_as: string, restricted_actions: list, recovery: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List operations
#
# GET /projects/{project_id}/operations
# operationId: listProjectOperations
export def "projects-operations listProjectOperations" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Specify the cursor value from the previous response to get the next batch of operations
  --limit: int # Specify a value from 1 to 1000 to limit number of operations in the response
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List project access
#
# GET /projects/{project_id}/permissions
# operationId: listProjectPermissions
export def "projects-permissions listProjectPermissions" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project_permissions: table<id: string, granted_to_email: string, granted_at: string, revoked_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Grant project access
#
# POST /projects/{project_id}/permissions
# operationId: grantPermissionToProject
export def "projects-permissions grantPermissionToProject" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
]: any -> record<id: string, granted_to_email: string, granted_at: string, revoked_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/permissions")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke project access
#
# DELETE /projects/{project_id}/permissions/{permission_id}
# operationId: revokePermissionFromProject
export def "projects-permissions revokePermissionFromProject" [
  project_id: string
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, granted_to_email: string, granted_at: string, revoked_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/permissions/($permission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available shared preload libraries
#
# GET /projects/{project_id}/available_preload_libraries
# operationId: getAvailablePreloadLibraries
export def "projects-available-preload-libraries get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<libraries: table<library_name: string, description: string, is_default: bool, is_experimental: bool, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/available_preload_libraries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project transfer request
#
# POST /projects/{project_id}/transfer_requests
# operationId: createProjectTransferRequest
export def "projects-transfer-requests createProjectTransferRequest" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl-seconds: int # Specifies the validity duration of the transfer request in seconds. If not provided, the request will expire after 24 hours (86,400 seconds).  (format: int64)
]: any -> record<id: string, project_id: string, created_at: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/transfer_requests")
  let body = {ttl_seconds: $ttl_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Accept a project transfer request
#
# PUT /projects/{project_id}/transfer_requests/{request_id}
# operationId: acceptProjectTransferRequest
export def "projects-transfer-requests acceptProjectTransferRequest" [
  project_id: string
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # The Neon organization ID to transfer the project to. If not provided, the project will be transferred to the current user or organization account.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/transfer_requests/($request_id)")
  let body = {org_id: $org_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List JWKS URLs
#
# GET /projects/{project_id}/jwks
# operationId: getProjectJWKS
export def "projects-jwks get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<jwks: table<id: string, project_id: string, branch_id: string, jwks_url: string, provider_name: string, created_at: string, updated_at: string, jwt_audience: string, role_names: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/jwks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add JWKS URL
#
# POST /projects/{project_id}/jwks
# operationId: addProjectJWKS
@deprecated --flag role-names
export def "projects-jwks addProjectJWKS" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  jwks_url: string # The URL that lists the JWKS
  provider_name: string # The name of the authentication provider (e.g., Clerk, Stytch, Auth0)
  --branch-id: string # Branch ID
  --jwt-audience: string # The name of the required JWT Audience to be used
  --role-names: list # DEPRECATED. This field should only be used when using Neon RLS. The roles the JWKS should be mapped to. By default, the JWKS is mapped to the `authenticator`, `authenticated` and `anonymous` roles. (DEPRECATED)
  --skip-role-creation: oneof<nothing, bool> # DEPRECATED. This field should only be used when using Neon RLS. If true, the role creation will be skipped. (default: false)
]: any -> record<jwks: record<id: string, project_id: string, branch_id: string, jwks_url: string, provider_name: string, created_at: string, updated_at: string, jwt_audience: string, role_names: list<string>>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/jwks")
  let body = {jwks_url: $jwks_url, provider_name: $provider_name, branch_id: $branch_id, jwt_audience: $jwt_audience, role_names: $role_names, skip_role_creation: $skip_role_creation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete JWKS URL
#
# DELETE /projects/{project_id}/jwks/{jwks_id}
# operationId: deleteProjectJWKS
export def "projects-jwks delete" [
  project_id: string
  jwks_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, project_id: string, branch_id: string, jwks_url: string, provider_name: string, created_at: string, updated_at: string, jwt_audience: string, role_names: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/jwks/($jwks_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Neon Data API
#
# POST /projects/{project_id}/branches/{branch_id}/data-api/{database_name}
# operationId: createProjectBranchDataAPI
# --settings shape: {db_aggregates_enabled?: bool, db_anon_role?: string, db_extra_search_path?: string, db_max_rows?: int, db_schemas?: list, jwt_role_claim_key?: string, jwt_cache_max_lifetime?: int, openapi_mode?: string, server_cors_allowed_origins?: string, server_timing_enabled?: bool}
export def "projects-branches-data-api createProjectBranchDataAPI" [
  project_id: string
  branch_id: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-provider: string@auth-provider-completer # The authentication provider to use for the Neon Data API
  --jwks-url: string # The URL that lists the JWKS (format: uri)
  --provider-name: string # The name of the authentication provider (e.g., Clerk, Stytch, Auth0)
  --jwt-audience: string # WARNING - using this setting will only reject tokens with a different audience claim. Tokens without audience claim will still be accepted.
  --add-default-grants: oneof<nothing, bool> # Grant all permissions to the tables in the public schema to authenticated users (default: false)
  --skip-auth-schema: oneof<nothing, bool> # Skip creating the auth schema and RLS functions (default: false)
  --settings: record # Configuration settings for the Neon Data API — shape: {db_aggregates_enabled?: bool, db_anon_role?: string, db_extra_search_path?: string, db_max_rows?: int, db_schemas?: list, jwt_role_claim_key?: string, jwt_cache_max_lifetime?: int, openapi_mode?: string, server_cors_allowed_origins?: string, server_timing_enabled?: bool}
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/data-api/($database_name)")
  let body = {auth_provider: $auth_provider, jwks_url: $jwks_url, provider_name: $provider_name, jwt_audience: $jwt_audience, add_default_grants: $add_default_grants, skip_auth_schema: $skip_auth_schema, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Neon Data API
#
# PATCH /projects/{project_id}/branches/{branch_id}/data-api/{database_name}
# operationId: updateProjectBranchDataAPI
# --settings shape: {db_aggregates_enabled?: bool, db_anon_role?: string, db_extra_search_path?: string, db_max_rows?: int, db_schemas?: list, jwt_role_claim_key?: string, jwt_cache_max_lifetime?: int, openapi_mode?: string, server_cors_allowed_origins?: string, server_timing_enabled?: bool}
export def "projects-branches-data-api updateProjectBranchDataAPI" [
  project_id: string
  branch_id: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record # Configuration settings for the Neon Data API — shape: {db_aggregates_enabled?: bool, db_anon_role?: string, db_extra_search_path?: string, db_max_rows?: int, db_schemas?: list, jwt_role_claim_key?: string, jwt_cache_max_lifetime?: int, openapi_mode?: string, server_cors_allowed_origins?: string, server_timing_enabled?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/data-api/($database_name)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Neon Data API
#
# DELETE /projects/{project_id}/branches/{branch_id}/data-api/{database_name}
# operationId: deleteProjectBranchDataAPI
export def "projects-branches-data-api delete" [
  project_id: string
  branch_id: string
  database_name: string
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
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/data-api/($database_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Neon Data API configuration
#
# GET /projects/{project_id}/branches/{branch_id}/data-api/{database_name}
# operationId: getProjectBranchDataAPI
export def "projects-branches-data-api get" [
  project_id: string
  branch_id: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string, status: string, settings: record, available_schemas: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/data-api/($database_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Neon Auth integration
#
# POST /projects/auth/create
# DEPRECATED
# operationId: createNeonAuthIntegration
@deprecated
@deprecated --flag role-name
export def "projects-auth-create createNeonAuthIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  auth_provider: string@auth-provider-completer-1
  project_id: string
  branch_id: string
  --database-name: string
  --role-name: string # DEPRECATED
]: any -> record<auth_provider: string, auth_provider_project_id: string, pub_client_key: string, secret_server_key: string, jwks_url: string, schema_name: string, table_name: string, base_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects/auth/create")
  let body = {auth_provider: $auth_provider, project_id: $project_id, branch_id: $branch_id, database_name: $database_name, role_name: $role_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Neon Auth details for the branch
#
# GET /projects/{project_id}/branches/{branch_id}/auth
# operationId: getNeonAuth
export def "projects-branches-auth get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auth_provider: string, auth_provider_project_id: string, branch_id: string, db_name: string, created_at: string, owned_by: string, transfer_status: string, jwks_url: string, base_url: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable Neon Auth for the branch
#
# POST /projects/{project_id}/branches/{branch_id}/auth
# operationId: createNeonAuth
export def "projects-branches-auth createNeonAuth" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  auth_provider: string@auth-provider-completer-1
  --database-name: string
]: any -> record<auth_provider: string, auth_provider_project_id: string, pub_client_key: string, secret_server_key: string, jwks_url: string, schema_name: string, table_name: string, base_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth")
  let body = {auth_provider: $auth_provider, database_name: $database_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable Neon Auth for the branch
#
# DELETE /projects/{project_id}/branches/{branch_id}/auth
# operationId: disableNeonAuth
export def "projects-branches-auth disableNeonAuth" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-data: oneof<nothing, bool> # If true, deletes the `neon_auth` schema from the database (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth")
  let body = {delete_data: $delete_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List trusted redirect URI domains
#
# GET /projects/{project_id}/auth/domains
# DEPRECATED
# operationId: listNeonAuthRedirectURIWhitelistDomains
@deprecated
export def "projects-auth-domains listNeonAuthRedirectURIWhitelistDomains" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domains: table<domain: string, auth_provider: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add trusted redirect URI domain
#
# POST /projects/{project_id}/auth/domains
# DEPRECATED
# operationId: addNeonAuthDomainToRedirectURIWhitelist
@deprecated
export def "projects-auth-domains addNeonAuthDomainToRedirectURIWhitelist" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  domain: string # format: uri
  auth_provider: string@auth-provider-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/domains")
  let body = {domain: $domain, auth_provider: $auth_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete trusted redirect URI domain
#
# DELETE /projects/{project_id}/auth/domains
# DEPRECATED
# operationId: deleteNeonAuthDomainFromRedirectURIWhitelist
# --domains item shape: {domain: string}
@deprecated
export def "projects-auth-domains delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  auth_provider: string@auth-provider-completer-1
  domains: list # item shape: {domain: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/domains")
  let body = {auth_provider: $auth_provider, domains: $domains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List domains in redirect_uri whitelist
#
# GET /projects/{project_id}/branches/{branch_id}/auth/domains
# operationId: listBranchNeonAuthTrustedDomains
export def "projects-branches-auth-domains listBranchNeonAuthTrustedDomains" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domains: table<domain: string, auth_provider: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add domain to redirect_uri whitelist
#
# POST /projects/{project_id}/branches/{branch_id}/auth/domains
# operationId: addBranchNeonAuthTrustedDomain
export def "projects-branches-auth-domains addBranchNeonAuthTrustedDomain" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  domain: string # format: uri
  auth_provider: string@auth-provider-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/domains")
  let body = {domain: $domain, auth_provider: $auth_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete domain from redirect_uri whitelist
#
# DELETE /projects/{project_id}/branches/{branch_id}/auth/domains
# operationId: deleteBranchNeonAuthTrustedDomain
# --domains item shape: {domain: string}
export def "projects-branches-auth-domains delete" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  auth_provider: string@auth-provider-completer-1
  domains: list # item shape: {domain: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/domains")
  let body = {auth_provider: $auth_provider, domains: $domains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Auth Provider SDK keys
#
# POST /projects/auth/keys
# operationId: createNeonAuthProviderSDKKeys
export def "projects-auth-keys createNeonAuthProviderSDKKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project_id: string
  auth_provider: string@auth-provider-completer-1
]: any -> record<auth_provider: string, auth_provider_project_id: string, pub_client_key: string, secret_server_key: string, jwks_url: string, schema_name: string, table_name: string, base_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects/auth/keys")
  let body = {project_id: $project_id, auth_provider: $auth_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create new auth user
#
# POST /projects/auth/user
# DEPRECATED
# operationId: createNeonAuthNewUser
@deprecated
export def "projects-auth-user createNeonAuthNewUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project_id: string
  auth_provider: string@auth-provider-completer-1
  email: string # format: email
  --name: string
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects/auth/user")
  let body = {project_id: $project_id, auth_provider: $auth_provider, email: $email, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create new auth user
#
# POST /projects/{project_id}/branches/{branch_id}/auth/users
# operationId: createBranchNeonAuthNewUser
export def "projects-branches-auth-users createBranchNeonAuthNewUser" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
  --name: string
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/users")
  let body = {email: $email, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete auth user
#
# DELETE /projects/{project_id}/branches/{branch_id}/auth/users/{auth_user_id}
# operationId: deleteBranchNeonAuthUser
export def "projects-branches-auth-users delete" [
  project_id: string
  branch_id: string
  auth_user_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/users/($auth_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update auth user role
#
# PUT /projects/{project_id}/branches/{branch_id}/auth/users/{auth_user_id}/role
# operationId: updateNeonAuthUserRole
export def "projects-branches-auth-users-role updateNeonAuthUserRole" [
  project_id: string
  branch_id: string
  auth_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roles: list # Array of roles to assign to the user (e.g. [admin])
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/users/($auth_user_id)/role")
  let body = {roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete auth user
#
# DELETE /projects/{project_id}/auth/users/{auth_user_id}
# DEPRECATED
# operationId: deleteNeonAuthUser
@deprecated
export def "projects-auth-users delete" [
  project_id: string
  auth_user_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/auth/users/($auth_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transfer Neon-managed auth project to your own account
#
# POST /projects/auth/transfer_ownership
# operationId: transferNeonAuthProviderProject
export def "projects-auth-transfer-ownership transferNeonAuthProviderProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  project_id: string
  auth_provider: string@auth-provider-completer-1
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects/auth/transfer_ownership")
  let body = {project_id: $project_id, auth_provider: $auth_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List active integrations with auth providers
#
# GET /projects/{project_id}/auth/integrations
# DEPRECATED
# operationId: listNeonAuthIntegrations
@deprecated
export def "projects-auth-integrations listNeonAuthIntegrations" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<auth_provider: string, auth_provider_project_id: string, branch_id: string, db_name: string, created_at: string, owned_by: string, transfer_status: string, jwks_url: string, base_url: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List OAuth providers
#
# GET /projects/{project_id}/auth/oauth_providers
# DEPRECATED
# operationId: listNeonAuthOauthProviders
@deprecated
export def "projects-auth-oauth-providers listNeonAuthOauthProviders" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<providers: table<id: string, type: string, client_id: string, client_secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/oauth_providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an OAuth provider
#
# POST /projects/{project_id}/auth/oauth_providers
# DEPRECATED
# operationId: addNeonAuthOauthProvider
@deprecated
export def "projects-auth-oauth-providers addNeonAuthOauthProvider" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string@id-completer
  --client-id: string
  --client-secret: string
  --microsoft-tenant-id: string
]: any -> record<id: string, type: string, client_id: string, client_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/oauth_providers")
  let body = {id: $id, client_id: $client_id, client_secret: $client_secret, microsoft_tenant_id: $microsoft_tenant_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List OAuth providers for the branch
#
# GET /projects/{project_id}/branches/{branch_id}/auth/oauth_providers
# operationId: listBranchNeonAuthOauthProviders
export def "projects-branches-auth-oauth-providers listBranchNeonAuthOauthProviders" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<providers: table<id: string, type: string, client_id: string, client_secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/oauth_providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an OAuth provider
#
# POST /projects/{project_id}/branches/{branch_id}/auth/oauth_providers
# operationId: addBranchNeonAuthOauthProvider
export def "projects-branches-auth-oauth-providers addBranchNeonAuthOauthProvider" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string@id-completer
  --client-id: string
  --client-secret: string
  --microsoft-tenant-id: string
]: any -> record<id: string, type: string, client_id: string, client_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/oauth_providers")
  let body = {id: $id, client_id: $client_id, client_secret: $client_secret, microsoft_tenant_id: $microsoft_tenant_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update OAuth provider
#
# PATCH /projects/{project_id}/auth/oauth_providers/{oauth_provider_id}
# DEPRECATED
# operationId: updateNeonAuthOauthProvider
@deprecated
export def "projects-auth-oauth-providers updateNeonAuthOauthProvider" [
  project_id: string
  oauth_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
  --microsoft-tenant-id: string
]: any -> record<id: string, type: string, client_id: string, client_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/oauth_providers/($oauth_provider_id)")
  let body = {client_id: $client_id, client_secret: $client_secret, microsoft_tenant_id: $microsoft_tenant_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete OAuth provider
#
# DELETE /projects/{project_id}/auth/oauth_providers/{oauth_provider_id}
# DEPRECATED
# operationId: deleteNeonAuthOauthProvider
@deprecated
export def "projects-auth-oauth-providers delete" [
  project_id: string
  oauth_provider_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/auth/oauth_providers/($oauth_provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update OAuth provider
#
# PATCH /projects/{project_id}/branches/{branch_id}/auth/oauth_providers/{oauth_provider_id}
# operationId: updateBranchNeonAuthOauthProvider
export def "projects-branches-auth-oauth-providers updateBranchNeonAuthOauthProvider" [
  project_id: string
  branch_id: string
  oauth_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
  --microsoft-tenant-id: string
]: any -> record<id: string, type: string, client_id: string, client_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/oauth_providers/($oauth_provider_id)")
  let body = {client_id: $client_id, client_secret: $client_secret, microsoft_tenant_id: $microsoft_tenant_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete OAuth provider
#
# DELETE /projects/{project_id}/branches/{branch_id}/auth/oauth_providers/{oauth_provider_id}
# operationId: deleteBranchNeonAuthOauthProvider
export def "projects-branches-auth-oauth-providers delete" [
  project_id: string
  branch_id: string
  oauth_provider_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/oauth_providers/($oauth_provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve email server configuration
#
# GET /projects/{project_id}/auth/email_server
# DEPRECATED
# Discriminator (response): type = standard, shared
# operationId: getNeonAuthEmailServer
@deprecated
export def "projects-auth-email-server get" [
  project_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/auth/email_server")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update email server configuration
#
# PATCH /projects/{project_id}/auth/email_server
# DEPRECATED
# Discriminator (request): type = standard, shared
# operationId: updateNeonAuthEmailServer
@deprecated
export def "projects-auth-email-server updateNeonAuthEmailServer" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string
  --port: int
  --username: string
  --password: string
  --sender-email: string
  --sender-name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/email_server")
  let body = {host: $host, port: $port, username: $username, password: $password, sender_email: $sender_email, sender_name: $sender_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send test email
#
# POST /projects/{project_id}/branches/{branch_id}/auth/send_test_email
# operationId: sendNeonAuthTestEmail
export def "projects-branches-auth-send-test-email sendNeonAuthTestEmail" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string
  port: int
  username: string
  password: string
  sender_email: string
  sender_name: string
  recipient_email: string # The email address to send the test email to. (format: email)
]: any -> record<success: bool, error_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/send_test_email")
  let body = {host: $host, port: $port, username: $username, password: $password, sender_email: $sender_email, sender_name: $sender_name, recipient_email: $recipient_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve email and password configuration
#
# GET /projects/{project_id}/branches/{branch_id}/auth/email_and_password
# operationId: getNeonAuthEmailAndPasswordConfig
export def "projects-branches-auth-email-and-password get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, email_verification_method: string, require_email_verification: bool, auto_sign_in_after_verification: bool, send_verification_email_on_sign_up: bool, send_verification_email_on_sign_in: bool, disable_sign_up: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/email_and_password")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update email and password configuration
#
# PATCH /projects/{project_id}/branches/{branch_id}/auth/email_and_password
# operationId: updateNeonAuthEmailAndPasswordConfig
export def "projects-branches-auth-email-and-password updateNeonAuthEmailAndPasswordConfig" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether email and password authentication is enabled
  --email-verification-method: string@email-verification-method-completer # The email verification method to use. - `link`: Sends a verification link via email - `otp`: Sends a one-time password (OTP) via email
  --require-email-verification: oneof<nothing, bool> # Whether email verification is required before users can sign in
  --auto-sign-in-after-verification: oneof<nothing, bool> # Whether users are automatically signed in after verifying their email
  --send-verification-email-on-sign-up: oneof<nothing, bool> # Whether to send a verification email when users sign up
  --send-verification-email-on-sign-in: oneof<nothing, bool> # Whether to send a verification email when users sign in
  --disable-sign-up: oneof<nothing, bool> # Whether to disable new user sign ups
]: any -> record<enabled: bool, email_verification_method: string, require_email_verification: bool, auto_sign_in_after_verification: bool, send_verification_email_on_sign_up: bool, send_verification_email_on_sign_in: bool, disable_sign_up: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/email_and_password")
  let body = {enabled: $enabled, email_verification_method: $email_verification_method, require_email_verification: $require_email_verification, auto_sign_in_after_verification: $auto_sign_in_after_verification, send_verification_email_on_sign_up: $send_verification_email_on_sign_up, send_verification_email_on_sign_in: $send_verification_email_on_sign_in, disable_sign_up: $disable_sign_up} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve email provider configuration
#
# GET /projects/{project_id}/branches/{branch_id}/auth/email_provider
# Discriminator (response): type = standard, shared
# operationId: getNeonAuthEmailProvider
export def "projects-branches-auth-email-provider get" [
  project_id: string
  branch_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/email_provider")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update email provider configuration
#
# PATCH /projects/{project_id}/branches/{branch_id}/auth/email_provider
# Discriminator (request): type = standard, shared
# operationId: updateNeonAuthEmailProvider
export def "projects-branches-auth-email-provider updateNeonAuthEmailProvider" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string
  --port: int
  --username: string
  --password: string
  --sender-email: string
  --sender-name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/email_provider")
  let body = {host: $host, port: $port, username: $username, password: $password, sender_email: $sender_email, sender_name: $sender_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete integration with auth provider
#
# DELETE /projects/{project_id}/auth/integration/{auth_provider}
# DEPRECATED
# operationId: deleteNeonAuthIntegration
@deprecated
export def "projects-auth-integration delete" [
  project_id: string
  auth_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-data: oneof<nothing, bool> # If true, deletes the `neon_auth` schema from the database (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/auth/integration/($auth_provider)")
  let body = {delete_data: $delete_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve connection URI
#
# GET /projects/{project_id}/connection_uri
# operationId: getConnectionURI
export def "projects-connection-uri get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-id: string # The branch ID. Defaults to your project's default `branch_id` if not specified.
  --endpoint-id: string # The endpoint ID. Defaults to the read-write `endpoint_id` associated with the `branch_id` if not specified.
  --database-name: string # The database name
  --role-name: string # The role name
  --pooled: oneof<nothing, bool> # Adds the `-pooler` option to the connection URI when set to `true`, creating a pooled connection URI.
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "endpoint_id" $endpoint_id "scalar") (serialize-qp "database_name" $database_name "scalar") (serialize-qp "role_name" $role_name "scalar") (serialize-qp "pooled" $pooled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/connection_uri" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve localhost allow setting
#
# GET /projects/{project_id}/branches/{branch_id}/auth/allow_localhost
# operationId: getNeonAuthAllowLocalhost
export def "projects-branches-auth-allow-localhost get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_localhost: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/allow_localhost")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update localhost allow setting
#
# PATCH /projects/{project_id}/branches/{branch_id}/auth/allow_localhost
# operationId: updateNeonAuthAllowLocalhost
export def "projects-branches-auth-allow-localhost updateNeonAuthAllowLocalhost" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-localhost: oneof<nothing, bool> # Whether to allow localhost connections
]: any -> record<allow_localhost: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/allow_localhost")
  let body = {allow_localhost: $allow_localhost} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Neon Auth plugin configurations
#
# GET /projects/{project_id}/branches/{branch_id}/auth/plugins
# operationId: getNeonAuthPluginConfigs
export def "projects-branches-auth-plugins get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<organization: record<enabled: bool, organization_limit: int, membership_limit: int, creator_role: string, send_invitation_email: bool>, magic_link: record<enabled: bool, expires_in: int, disable_sign_up: bool>, phone_number: record<enabled: bool, otp_expires_in: int>, email_provider: record, email_and_password: record<enabled: bool, email_verification_method: string, require_email_verification: bool, auto_sign_in_after_verification: bool, send_verification_email_on_sign_up: bool, send_verification_email_on_sign_in: bool, disable_sign_up: bool>, oauth_providers: table<id: string, type: string, client_id: string, client_secret: string>, allow_localhost: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/plugins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update organization plugin configuration
#
# PATCH /projects/{project_id}/branches/{branch_id}/auth/plugins/organization
# operationId: updateNeonAuthOrganizationPlugin
export def "projects-branches-auth-plugins-organization updateNeonAuthOrganizationPlugin" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether the organization plugin is enabled
  --organization-limit: int # Maximum number of organizations a user can create (format: int32)
  --membership-limit: int # Maximum number of members per organization (format: int32)
  --creator-role: string@creator-role-completer # The role assigned to the user who creates an organization
  --send-invitation-email: oneof<nothing, bool> # Whether to send invitation emails when inviting members to an organization
]: any -> record<enabled: bool, organization_limit: int, membership_limit: int, creator_role: string, send_invitation_email: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/plugins/organization")
  let body = {enabled: $enabled, organization_limit: $organization_limit, membership_limit: $membership_limit, creator_role: $creator_role, send_invitation_email: $send_invitation_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update auth configuration
#
# PATCH /projects/{project_id}/branches/{branch_id}/auth/config
# operationId: updateNeonAuthConfig
export def "projects-branches-auth-config updateNeonAuthConfig" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The application name used in auth emails and communications.
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/config")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update magic link plugin configuration
#
# PATCH /projects/{project_id}/branches/{branch_id}/auth/plugins/magic-link
# operationId: updateNeonAuthMagicLinkPlugin
export def "projects-branches-auth-plugins-magic-link updateNeonAuthMagicLinkPlugin" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether the magic link plugin is enabled
  --expires-in: int # Time in minutes before the magic link expires (format: int32)
  --disable-sign-up: oneof<nothing, bool> # Whether to disable sign-up via magic link
]: any -> record<enabled: bool, expires_in: int, disable_sign_up: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/plugins/magic-link")
  let body = {enabled: $enabled, expires_in: $expires_in, disable_sign_up: $disable_sign_up} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve phone number plugin configuration
#
# GET /projects/{project_id}/branches/{branch_id}/auth/plugins/phone-number
# operationId: getNeonAuthPhoneNumberPlugin
export def "projects-branches-auth-plugins-phone-number get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, otp_expires_in: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/plugins/phone-number")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update phone number plugin configuration
#
# PATCH /projects/{project_id}/branches/{branch_id}/auth/plugins/phone-number
# operationId: updateNeonAuthPhoneNumberPlugin
export def "projects-branches-auth-plugins-phone-number updateNeonAuthPhoneNumberPlugin" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether the phone number plugin is enabled
  --otp-expires-in: int # Time in seconds before the OTP expires
]: any -> record<enabled: bool, otp_expires_in: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/plugins/phone-number")
  let body = {enabled: $enabled, otp_expires_in: $otp_expires_in} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Neon Auth webhook configuration
#
# GET /projects/{project_id}/branches/{branch_id}/auth/webhooks
# operationId: getNeonAuthWebhookConfig
export def "projects-branches-auth-webhooks get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, webhook_url: string, enabled_events: list<string>, timeout_seconds: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Neon Auth webhook configuration
#
# PUT /projects/{project_id}/branches/{branch_id}/auth/webhooks
# operationId: updateNeonAuthWebhookConfig
export def "projects-branches-auth-webhooks updateNeonAuthWebhookConfig" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --webhook-url: string
  --enabled-events: list
  --timeout-seconds: int # default: 5
]: any -> record<enabled: bool, webhook_url: string, enabled_events: list<string>, timeout_seconds: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/auth/webhooks")
  let body = {enabled: $enabled, webhook_url: $webhook_url, enabled_events: $enabled_events, timeout_seconds: $timeout_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create branch
#
# POST /projects/{project_id}/branches
# operationId: createProjectBranch
# --endpoints item shape: {type: "read_only"|"read_write", settings?: record, autoscaling_limit_min_cu?: float, autoscaling_limit_max_cu?: float, provisioner?: string, suspend_timeout_seconds?: int}
# --branch shape: {parent_id?: string, name?: string, parent_lsn?: string, parent_timestamp?: string, protected?: bool, archived?: bool, init_source?: string, expires_at?: string}
export def "projects-branches createProjectBranch" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoints: list # item shape: {type: "read_only"|"read_write", settings?: record, autoscaling_limit_min_cu?: float, autoscaling_limit_max_cu?: float, provisioner?: string, suspend_timeout_seconds?: int}
  --branch: record # shape: {parent_id?: string, name?: string, parent_lsn?: string, parent_timestamp?: string, protected?: bool, archived?: bool, init_source?: string, expires_at?: string}
  --annotation-value: record # Annotation properties. (e.g. {github-commit-ref: github-branch-name})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches")
  let body = {endpoints: $endpoints, branch: $branch, annotation_value: $annotation_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List branches
#
# GET /projects/{project_id}/branches
# operationId: listProjectBranches
export def "projects-branches listProjectBranches" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search by branch `name` or `id`. You can specify partial `name` or `id` values to filter results.
  --sort-by: string@sort-by-completer # Sort the branches by sort_field. If not provided, branches will be sorted by updated_at descending order (default: updated_at)
  --cursor: string # A cursor to use in pagination. A cursor defines your place in the data list. Include `response.pagination.next` in subsequent API calls to fetch next page of the list.
  --sort-order: string@sort-order-completer # Defines the sorting order of entities. (default: desc)
  --limit: int # The maximum number of records to be returned in the response
  --include-deleted: oneof<nothing, bool> # If true, return recoverable deleted branches too (soft-deleted within the recovery window). If false or not provided, return only active (non-deleted) branches.  This parameter is part of the Branch Recovery feature, which is in preview and not available to all users.  (default: false)
]: nothing -> record<branches: table<id: string, project_id: string, parent_id: string, parent_lsn: string, parent_timestamp: string, name: string, current_state: string, pending_state: string, state_changed_at: string, logical_size: int, creation_source: string, primary: bool, default: bool, protected: bool, cpu_used_sec: int, compute_time_seconds: int, active_time_seconds: int, written_data_bytes: int, data_transfer_bytes: int, created_at: string, updated_at: string, ttl_interval_seconds: int, expires_at: string, last_reset_at: string, created_by: record, init_source: string, restore_status: string, restored_from: string, restored_as: string, restricted_actions: list, recovery: record>, annotations: record, pagination: record<next: string, sort_by: string, sort_order: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include_deleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/branches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create anonymized branch
#
# POST /projects/{project_id}/branch_anonymized
# operationId: createProjectBranchAnonymized
# --branch_create shape: {endpoints?: list, branch?: record}
# --masking_rules item shape: {database_name: string, schema_name: string, table_name: string, column_name: string, masking_function?: string, masking_value?: string}
export def "projects-branch-anonymized createProjectBranchAnonymized" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --annotation-value: record # Annotation properties. (e.g. {github-commit-ref: github-branch-name})
  --branch-create: record # shape: {endpoints?: list, branch?: record}
  --masking-rules: list # List of masking rules to apply to the branch. — item shape: {database_name: string, schema_name: string, table_name: string, column_name: string, masking_function?: string, masking_value?: string}
  --start-anonymization: oneof<nothing, bool> # If true, automatically start anonymization after the branch is created. Defaults to false.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branch_anonymized")
  let body = {annotation_value: $annotation_value, branch_create: $branch_create, masking_rules: $masking_rules, start_anonymization: $start_anonymization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve number of branches
#
# GET /projects/{project_id}/branches/count
# operationId: countProjectBranches
export def "projects-branches-count countProjectBranches" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Count branches matching the `name` in search query
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/branches/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve branch details
#
# GET /projects/{project_id}/branches/{branch_id}
# operationId: getProjectBranch
export def "projects-branches get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<branch: record<id: string, project_id: string, parent_id: string, parent_lsn: string, parent_timestamp: string, name: string, current_state: string, pending_state: string, state_changed_at: string, logical_size: int, creation_source: string, primary: bool, default: bool, protected: bool, cpu_used_sec: int, compute_time_seconds: int, active_time_seconds: int, written_data_bytes: int, data_transfer_bytes: int, created_at: string, updated_at: string, ttl_interval_seconds: int, expires_at: string, last_reset_at: string, created_by: record<name: string, image: string>, init_source: string, restore_status: string, restored_from: string, restored_as: string, restricted_actions: list<record>, recovery: record<deleted_at: string, recoverable_until: string, deletion_method: string>>, annotation: record<object: record<type: string, id: string>, value: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete branch
#
# DELETE /projects/{project_id}/branches/{branch_id}
# operationId: deleteProjectBranch
export def "projects-branches delete" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard-delete: oneof<nothing, bool> # If true, the branch is permanently deleted immediately without a recovery window. If false (default), the branch can be recovered within 7 days via the recover endpoint.  This parameter is part of the Branch Recovery feature, which is in preview and not available to all users.  (default: false)
]: nothing -> record<branch: record<id: string, project_id: string, parent_id: string, parent_lsn: string, parent_timestamp: string, name: string, current_state: string, pending_state: string, state_changed_at: string, logical_size: int, creation_source: string, primary: bool, default: bool, protected: bool, cpu_used_sec: int, compute_time_seconds: int, active_time_seconds: int, written_data_bytes: int, data_transfer_bytes: int, created_at: string, updated_at: string, ttl_interval_seconds: int, expires_at: string, last_reset_at: string, created_by: record<name: string, image: string>, init_source: string, restore_status: string, restored_from: string, restored_as: string, restricted_actions: list<record>, recovery: record<deleted_at: string, recoverable_until: string, deletion_method: string>>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hard_delete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update branch
#
# PATCH /projects/{project_id}/branches/{branch_id}
# operationId: updateProjectBranch
# --branch shape: {name?: string, protected?: bool, expires_at?: string}
export def "projects-branches updateProjectBranch" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branch: record # shape: {name?: string, protected?: bool, expires_at?: string}
]: any -> record<branch: record<id: string, project_id: string, parent_id: string, parent_lsn: string, parent_timestamp: string, name: string, current_state: string, pending_state: string, state_changed_at: string, logical_size: int, creation_source: string, primary: bool, default: bool, protected: bool, cpu_used_sec: int, compute_time_seconds: int, active_time_seconds: int, written_data_bytes: int, data_transfer_bytes: int, created_at: string, updated_at: string, ttl_interval_seconds: int, expires_at: string, last_reset_at: string, created_by: record<name: string, image: string>, init_source: string, restore_status: string, restored_from: string, restored_as: string, restricted_actions: list<record>, recovery: record<deleted_at: string, recoverable_until: string, deletion_method: string>>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)")
  let body = {branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restore branch to a historical state
#
# POST /projects/{project_id}/branches/{branch_id}/restore
# operationId: restoreProjectBranch
export def "projects-branches-restore restoreProjectBranch" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  source_branch_id: string # The `branch_id` of the restore source branch. If `source_timestamp` and `source_lsn` are omitted, the branch will be restored to head. If `source_branch_id` is equal to the branch's id, `source_timestamp` or `source_lsn` is required.
  --source-lsn: string # A Log Sequence Number (LSN) on the source branch. The branch will be restored with data from this LSN.
  --source-timestamp: string # A timestamp identifying a point in time on the source branch. The branch will be restored with data starting from this point in time. The timestamp must be provided in ISO 8601 format; for example: `2024-02-26T12:00:00Z`.  (format: date-time)
  --preserve-under-name: string # If not empty, the previous state of the branch will be saved to a branch with this name. If the branch has children or the `source_branch_id` is equal to the branch id, this field is required. All existing child branches will be moved to the newly created branch under the name `preserve_under_name`.
]: any -> record<branch: record<id: string, project_id: string, parent_id: string, parent_lsn: string, parent_timestamp: string, name: string, current_state: string, pending_state: string, state_changed_at: string, logical_size: int, creation_source: string, primary: bool, default: bool, protected: bool, cpu_used_sec: int, compute_time_seconds: int, active_time_seconds: int, written_data_bytes: int, data_transfer_bytes: int, created_at: string, updated_at: string, ttl_interval_seconds: int, expires_at: string, last_reset_at: string, created_by: record<name: string, image: string>, init_source: string, restore_status: string, restored_from: string, restored_as: string, restricted_actions: list<record>, recovery: record<deleted_at: string, recoverable_until: string, deletion_method: string>>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/restore")
  let body = {source_branch_id: $source_branch_id, source_lsn: $source_lsn, source_timestamp: $source_timestamp, preserve_under_name: $preserve_under_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve database schema
#
# GET /projects/{project_id}/branches/{branch_id}/schema
# operationId: getProjectBranchSchema
export def "projects-branches-schema get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-name: string # Name of the database for which the schema is retrieved
  --lsn: string # The Log Sequence Number (LSN) for which the schema is retrieved
  --timestamp: string # The point in time for which the schema is retrieved  (format: date-time, e.g. 2022-11-30T20:09:48Z)
  --format: string # The format of the schema to retrieve. Possible values: - `sql` (default) - `json`
]: nothing -> record<sql: string, json: record<tables: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "db_name" $db_name "scalar") (serialize-qp "lsn" $lsn "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compare database schema
#
# GET /projects/{project_id}/branches/{branch_id}/compare_schema
# operationId: getProjectBranchSchemaComparison
export def "projects-branches-compare-schema get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --base-branch-id: string # The branch ID to compare the schema with
  --db-name: string # Name of the database for which the schema is retrieved
  --lsn: string # The Log Sequence Number (LSN) for which the schema is retrieved
  --timestamp: string # The point in time for which the schema is retrieved  (format: date-time, e.g. 2022-11-30T20:09:48Z)
  --base-lsn: string # The Log Sequence Number (LSN) for the base branch schema
  --base-timestamp: string # The point in time for the base branch schema  (format: date-time, e.g. 2022-11-30T20:09:48Z)
]: nothing -> record<diff: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_branch_id" $base_branch_id "scalar") (serialize-qp "db_name" $db_name "scalar") (serialize-qp "lsn" $lsn "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "base_lsn" $base_lsn "scalar") (serialize-qp "base_timestamp" $base_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/compare_schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve masking rules
#
# GET /projects/{project_id}/branches/{branch_id}/masking_rules
# operationId: getMaskingRules
export def "projects-branches-masking-rules get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<masking_rules: table<database_name: string, schema_name: string, table_name: string, column_name: string, masking_function: string, masking_value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/masking_rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update masking rules
#
# PATCH /projects/{project_id}/branches/{branch_id}/masking_rules
# operationId: updateMaskingRules
# --masking_rules item shape: {database_name: string, schema_name: string, table_name: string, column_name: string, masking_function?: string, masking_value?: string}
export def "projects-branches-masking-rules updateMaskingRules" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  masking_rules: list # List of masking rules to apply to the branch. This will replace all existing masking rules for the branch. — item shape: {database_name: string, schema_name: string, table_name: string, column_name: string, masking_function?: string, masking_value?: string}
]: any -> record<masking_rules: table<database_name: string, schema_name: string, table_name: string, column_name: string, masking_function: string, masking_value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/masking_rules")
  let body = {masking_rules: $masking_rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve anonymized branch status
#
# GET /projects/{project_id}/branches/{branch_id}/anonymized_status
# operationId: getAnonymizedBranchStatus
export def "projects-branches-anonymized-status get" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project_id: string, branch_id: string, state: string, status_message: string, created_at: string, updated_at: string, failed_at: string, last_run: record<started_at: string, completed_at: string, triggered_by: string, triggered_by_username: string, masked_columns: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/anonymized_status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start anonymization
#
# POST /projects/{project_id}/branches/{branch_id}/anonymize
# operationId: startAnonymization
export def "projects-branches-anonymize startAnonymization" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project_id: string, branch_id: string, state: string, status_message: string, created_at: string, updated_at: string, failed_at: string, last_run: record<started_at: string, completed_at: string, triggered_by: string, triggered_by_username: string, masked_columns: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/anonymize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set branch as default
#
# POST /projects/{project_id}/branches/{branch_id}/set_as_default
# operationId: setDefaultProjectBranch
export def "projects-branches-set-as-default setDefaultProjectBranch" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<branch: record<id: string, project_id: string, parent_id: string, parent_lsn: string, parent_timestamp: string, name: string, current_state: string, pending_state: string, state_changed_at: string, logical_size: int, creation_source: string, primary: bool, default: bool, protected: bool, cpu_used_sec: int, compute_time_seconds: int, active_time_seconds: int, written_data_bytes: int, data_transfer_bytes: int, created_at: string, updated_at: string, ttl_interval_seconds: int, expires_at: string, last_reset_at: string, created_by: record<name: string, image: string>, init_source: string, restore_status: string, restored_from: string, restored_as: string, restricted_actions: list<record>, recovery: record<deleted_at: string, recoverable_until: string, deletion_method: string>>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/set_as_default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recover a deleted branch
#
# POST /projects/{project_id}/branches/{branch_id}/recover
# operationId: recoverProjectBranch
export def "projects-branches-recover recoverProjectBranch" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<branch: record<id: string, project_id: string, parent_id: string, parent_lsn: string, parent_timestamp: string, name: string, current_state: string, pending_state: string, state_changed_at: string, logical_size: int, creation_source: string, primary: bool, default: bool, protected: bool, cpu_used_sec: int, compute_time_seconds: int, active_time_seconds: int, written_data_bytes: int, data_transfer_bytes: int, created_at: string, updated_at: string, ttl_interval_seconds: int, expires_at: string, last_reset_at: string, created_by: record<name: string, image: string>, init_source: string, restore_status: string, restored_from: string, restored_as: string, restricted_actions: list<record>, recovery: record<deleted_at: string, recoverable_until: string, deletion_method: string>>, endpoints: table<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finalize branch restore from snapshot
#
# POST /projects/{project_id}/branches/{branch_id}/finalize_restore
# operationId: finalizeRestoreBranch
export def "projects-branches-finalize-restore finalizeRestoreBranch" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # used to rename the existing branch when it is replaced. if omitted, a default name is generated and used
]: any -> record<operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/finalize_restore")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List branch endpoints
#
# GET /projects/{project_id}/branches/{branch_id}/endpoints
# operationId: listProjectBranchEndpoints
export def "projects-branches-endpoints listProjectBranchEndpoints" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoints: table<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List databases
#
# GET /projects/{project_id}/branches/{branch_id}/databases
# operationId: listProjectBranchDatabases
export def "projects-branches-databases listProjectBranchDatabases" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<databases: table<id: int, branch_id: string, name: string, owner_name: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/databases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create database
#
# POST /projects/{project_id}/branches/{branch_id}/databases
# operationId: createProjectBranchDatabase
# --database shape: {name: string, owner_name: string}
export def "projects-branches-databases createProjectBranchDatabase" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  database: record # shape: {name: string, owner_name: string}
]: any -> record<database: record<id: int, branch_id: string, name: string, owner_name: string, created_at: string, updated_at: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/databases")
  let body = {database: $database} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve database details
#
# GET /projects/{project_id}/branches/{branch_id}/databases/{database_name}
# operationId: getProjectBranchDatabase
export def "projects-branches-databases get" [
  project_id: string
  branch_id: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<database: record<id: int, branch_id: string, name: string, owner_name: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/databases/($database_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update database
#
# PATCH /projects/{project_id}/branches/{branch_id}/databases/{database_name}
# operationId: updateProjectBranchDatabase
# --database shape: {name?: string, owner_name?: string}
export def "projects-branches-databases updateProjectBranchDatabase" [
  project_id: string
  branch_id: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  database: record # shape: {name?: string, owner_name?: string}
]: any -> record<database: record<id: int, branch_id: string, name: string, owner_name: string, created_at: string, updated_at: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/databases/($database_name)")
  let body = {database: $database} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete database
#
# DELETE /projects/{project_id}/branches/{branch_id}/databases/{database_name}
# operationId: deleteProjectBranchDatabase
export def "projects-branches-databases delete" [
  project_id: string
  branch_id: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<database: record<id: int, branch_id: string, name: string, owner_name: string, created_at: string, updated_at: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/databases/($database_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List roles
#
# GET /projects/{project_id}/branches/{branch_id}/roles
# operationId: listProjectBranchRoles
export def "projects-branches-roles listProjectBranchRoles" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<roles: table<branch_id: string, name: string, password: string, protected: bool, authentication_method: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create role
#
# POST /projects/{project_id}/branches/{branch_id}/roles
# operationId: createProjectBranchRole
# --role shape: {name: string, no_login?: bool}
export def "projects-branches-roles createProjectBranchRole" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role: record # shape: {name: string, no_login?: bool}
]: any -> record<role: record<branch_id: string, name: string, password: string, protected: bool, authentication_method: string, created_at: string, updated_at: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/roles")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve role details
#
# GET /projects/{project_id}/branches/{branch_id}/roles/{role_name}
# operationId: getProjectBranchRole
export def "projects-branches-roles get" [
  project_id: string
  branch_id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<role: record<branch_id: string, name: string, password: string, protected: bool, authentication_method: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/roles/($role_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete role
#
# DELETE /projects/{project_id}/branches/{branch_id}/roles/{role_name}
# operationId: deleteProjectBranchRole
export def "projects-branches-roles delete" [
  project_id: string
  branch_id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<role: record<branch_id: string, name: string, password: string, protected: bool, authentication_method: string, created_at: string, updated_at: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/roles/($role_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve role password
#
# GET /projects/{project_id}/branches/{branch_id}/roles/{role_name}/reveal_password
# operationId: getProjectBranchRolePassword
export def "projects-branches-roles-reveal-password get" [
  project_id: string
  branch_id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<password: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/roles/($role_name)/reveal_password")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset role password
#
# POST /projects/{project_id}/branches/{branch_id}/roles/{role_name}/reset_password
# operationId: resetProjectBranchRolePassword
export def "projects-branches-roles-reset-password resetProjectBranchRolePassword" [
  project_id: string
  branch_id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<role: record<branch_id: string, name: string, password: string, protected: bool, authentication_method: string, created_at: string, updated_at: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/roles/($role_name)/reset_password")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List VPC endpoint restrictions
#
# GET /projects/{project_id}/vpc_endpoints
# operationId: listProjectVPCEndpoints
export def "projects-vpc-endpoints listProjectVPCEndpoints" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoints: table<vpc_endpoint_id: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/vpc_endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set VPC endpoint restriction
#
# POST /projects/{project_id}/vpc_endpoints/{vpc_endpoint_id}
# operationId: assignProjectVPCEndpoint
export def "projects-vpc-endpoints assignProjectVPCEndpoint" [
  project_id: string
  vpc_endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/vpc_endpoints/($vpc_endpoint_id)")
  let body = {label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete VPC endpoint restriction
#
# DELETE /projects/{project_id}/vpc_endpoints/{vpc_endpoint_id}
# operationId: deleteProjectVPCEndpoint
export def "projects-vpc-endpoints delete" [
  project_id: string
  vpc_endpoint_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/vpc_endpoints/($vpc_endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create compute endpoint
#
# POST /projects/{project_id}/endpoints
# operationId: createProjectEndpoint
# --endpoint shape: {branch_id: string, region_id?: string, type: "read_only"|"read_write", settings?: record, autoscaling_limit_min_cu?: float, autoscaling_limit_max_cu?: float, provisioner?: string, pooler_enabled?: bool, pooler_mode?: "transaction", disabled?: bool, passwordless_access?: bool, suspend_timeout_seconds?: int, name?: string}
export def "projects-endpoints createProjectEndpoint" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  endpoint: record # shape: {branch_id: string, region_id?: string, type: "read_only"|"read_write", settings?: record, autoscaling_limit_min_cu?: float, autoscaling_limit_max_cu?: float, provisioner?: string, pooler_enabled?: bool, pooler_mode?: "transaction", disabled?: bool, passwordless_access?: bool, suspend_timeout_seconds?: int, name?: string}
]: any -> record<endpoint: record<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record<pg_settings: record, pgbouncer_settings: record, preload_libraries: record>, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/endpoints")
  let body = {endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List compute endpoints
#
# GET /projects/{project_id}/endpoints
# operationId: listProjectEndpoints
export def "projects-endpoints listProjectEndpoints" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoints: table<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve compute endpoint details
#
# GET /projects/{project_id}/endpoints/{endpoint_id}
# operationId: getProjectEndpoint
export def "projects-endpoints get" [
  project_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoint: record<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record<pg_settings: record, pgbouncer_settings: record, preload_libraries: record>, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/endpoints/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete compute endpoint
#
# DELETE /projects/{project_id}/endpoints/{endpoint_id}
# operationId: deleteProjectEndpoint
export def "projects-endpoints delete" [
  project_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoint: record<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record<pg_settings: record, pgbouncer_settings: record, preload_libraries: record>, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/endpoints/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update compute endpoint
#
# PATCH /projects/{project_id}/endpoints/{endpoint_id}
# operationId: updateProjectEndpoint
# --endpoint shape: {branch_id?: string, autoscaling_limit_min_cu?: float, autoscaling_limit_max_cu?: float, provisioner?: string, settings?: record, pooler_enabled?: bool, pooler_mode?: "transaction", disabled?: bool, passwordless_access?: bool, suspend_timeout_seconds?: int, name?: string}
export def "projects-endpoints updateProjectEndpoint" [
  project_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  endpoint: record # shape: {branch_id?: string, autoscaling_limit_min_cu?: float, autoscaling_limit_max_cu?: float, provisioner?: string, settings?: record, pooler_enabled?: bool, pooler_mode?: "transaction", disabled?: bool, passwordless_access?: bool, suspend_timeout_seconds?: int, name?: string}
]: any -> record<endpoint: record<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record<pg_settings: record, pgbouncer_settings: record, preload_libraries: record>, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/endpoints/($endpoint_id)")
  let body = {endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start compute endpoint
#
# POST /projects/{project_id}/endpoints/{endpoint_id}/start
# operationId: startProjectEndpoint
export def "projects-endpoints-start startProjectEndpoint" [
  project_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoint: record<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record<pg_settings: record, pgbouncer_settings: record, preload_libraries: record>, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/endpoints/($endpoint_id)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suspend compute endpoint
#
# POST /projects/{project_id}/endpoints/{endpoint_id}/suspend
# operationId: suspendProjectEndpoint
export def "projects-endpoints-suspend suspendProjectEndpoint" [
  project_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoint: record<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record<pg_settings: record, pgbouncer_settings: record, preload_libraries: record>, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/endpoints/($endpoint_id)/suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restart compute endpoint
#
# POST /projects/{project_id}/endpoints/{endpoint_id}/restart
# operationId: restartProjectEndpoint
export def "projects-endpoints-restart restartProjectEndpoint" [
  project_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoint: record<host: string, id: string, name: string, project_id: string, branch_id: string, autoscaling_limit_min_cu: float, autoscaling_limit_max_cu: float, region_id: string, type: string, current_state: string, pending_state: string, settings: record<pg_settings: record, pgbouncer_settings: record, preload_libraries: record>, pooler_enabled: bool, pooler_mode: string, disabled: bool, passwordless_access: bool, last_active: string, creation_source: string, created_at: string, updated_at: string, started_at: string, suspended_at: string, proxy_host: string, suspend_timeout_seconds: int, provisioner: string, compute_release_version: string>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/endpoints/($endpoint_id)/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve account consumption metrics (legacy plans)
#
# GET /consumption_history/account
# DEPRECATED
# operationId: getConsumptionHistoryPerAccount
@deprecated
@deprecated --flag include-v1-metrics
export def "consumption-history-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Specify the start `date-time` for the consumption period. The `date-time` value is rounded according to the specified `granularity`. For example, `2024-03-15T15:30:00Z` for `daily` granularity will be rounded to `2024-03-15T00:00:00Z`. The specified `date-time` value must respect the specified granularity: - For `hourly`, consumption metrics are limited to the last 168 hours. - For `daily`, consumption metrics are limited to the last 60 days. - For `monthly`, consumption metrics are limited to the past year.  The consumption history is available starting from `March 1, 2024, at 00:00:00 UTC`.  (format: date-time)
  --qp-to: string # Specify the end `date-time` for the consumption period. The `date-time` value is rounded according to the specified granularity. For example, `2024-03-15T15:30:00Z` for `daily` granularity will be rounded to `2024-03-15T00:00:00Z`. The specified `date-time` value must respect the specified granularity: - For `hourly`, consumption metrics are limited to the last 168 hours. - For `daily`, consumption metrics are limited to the last 60 days. - For `monthly`, consumption metrics are limited to the past year.  (format: date-time)
  --granularity: string@granularity-completer # Specify the granularity of consumption metrics. Hourly, daily, and monthly metrics are available for the last 168 hours, 60 days, and 1 year, respectively.
  --org-id: string # Specify the organization for which the consumption metrics should be returned. If this parameter is not provided, the endpoint will return the metrics for the authenticated user's account.
  --include-v1-metrics: oneof<nothing, bool> # The field is deprecated. Please use `metrics` instead. If `metrics` is specified, this field is ignored. Include metrics utilized in previous pricing models. - **data_storage_bytes_hour**: The sum of the maximum observed storage values for each hour   for each project, which never decreases.  (DEPRECATED)
  --metrics: list # Specify a list of metrics to include in the response. If omitted, active_time, compute_time, written_data, synthetic_storage_size are returned. Possible values: - `active_time_seconds` - `compute_time_seconds` - `written_data_bytes` - `synthetic_storage_size_bytes` - `data_storage_bytes_hour`  A list of metrics can be specified as an array of parameter values or as a comma-separated list in a single parameter value. - As an array of parameter values: `metrics=cpu_seconds&metrics=ram_bytes` - As a comma-separated list in a single parameter value: `metrics=cpu_seconds,ram_bytes`
]: nothing -> record<periods: table<period_id: string, period_plan: string, period_start: string, period_end: string, consumption: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "org_id" $org_id "scalar") (serialize-qp "include_v1_metrics" $include_v1_metrics "scalar") (serialize-qp "metrics" $metrics "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/consumption_history/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve project consumption metrics (legacy plans)
#
# GET /consumption_history/projects
# operationId: getConsumptionHistoryPerProject
@deprecated --flag include-v1-metrics
export def "consumption-history-projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Specify the cursor value from the previous response to get the next batch of projects.
  --limit: int # Specify a value from 1 to 100 to limit number of projects in the response. (default: 10)
  --project-ids: list # Specify a list of project IDs to filter the response. If omitted, the response will contain all projects. A list of project IDs can be specified as an array of parameter values or as a comma-separated list in a single parameter value. - As an array of parameter values: `project_ids=cold-poetry-09157238%20&project_ids=quiet-snow-71788278` - As a comma-separated list in a single parameter value: `project_ids=cold-poetry-09157238,quiet-snow-71788278`
  --qp-from: string # Specify the start `date-time` for the consumption period. The `date-time` value is rounded according to the specified `granularity`. For example, `2024-03-15T15:30:00Z` for `daily` granularity will be rounded to `2024-03-15T00:00:00Z`. The specified `date-time` value must respect the specified `granularity`: - For `hourly`, consumption metrics are limited to the last 168 hours. - For `daily`, consumption metrics are limited to the last 60 days. - For `monthly`, consumption metrics are limited to the last year.  The consumption history is available starting from `March 1, 2024, at 00:00:00 UTC`.  (format: date-time)
  --qp-to: string # Specify the end `date-time` for the consumption period. The `date-time` value is rounded according to the specified granularity. For example, `2024-03-15T15:30:00Z` for `daily` granularity will be rounded to `2024-03-15T00:00:00Z`. The specified `date-time` value must respect the specified `granularity`: - For `hourly`, consumption metrics are limited to the last 168 hours. - For `daily`, consumption metrics are limited to the last 60 days. - For `monthly`, consumption metrics are limited to the last year.  (format: date-time)
  --granularity: string@granularity-completer # Specify the granularity of consumption metrics. Hourly, daily, and monthly metrics are available for the last 168 hours, 60 days, and 1 year, respectively.
  --org-id: string # Specify the organization for which the project consumption metrics should be returned. If this parameter is not provided, the endpoint will return the metrics for the authenticated user's projects.
  --include-v1-metrics: oneof<nothing, bool> # The field is deprecated. Please use `metrics` instead. If `metrics` is specified, this field is ignored. Include metrics utilized in previous pricing models. - **data_storage_bytes_hour**: The sum of the maximum observed storage values for each hour,   which never decreases.  (DEPRECATED)
  --metrics: list # Specify a list of metrics to include in the response. If omitted, active_time, compute_time, written_data, synthetic_storage_size are returned. Possible values: - `active_time_seconds` - `compute_time_seconds` - `written_data_bytes` - `synthetic_storage_size_bytes` - `data_storage_bytes_hour` - `logical_size_bytes` - `logical_size_bytes_hour`  A list of metrics can be specified as an array of parameter values or as a comma-separated list in a single parameter value. - As an array of parameter values: `metrics=cpu_seconds&metrics=ram_bytes` - As a comma-separated list in a single parameter value: `metrics=cpu_seconds,ram_bytes`
]: nothing -> record<projects: table<project_id: string, periods: list>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "org_id" $org_id "scalar") (serialize-qp "include_v1_metrics" $include_v1_metrics "scalar") (serialize-qp "metrics" $metrics "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/consumption_history/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve project consumption metrics
#
# GET /consumption_history/v2/projects
# operationId: getConsumptionHistoryPerProjectV2
export def "consumption-history-projects get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor from the previous response (`pagination.cursor`). Pass it to fetch the next page of projects. Pages are ordered by project creation order (newest first).
  --limit: int # Maximum number of projects per page. Allowed range: 1 to 100. Default: 10.  (default: 10)
  --project-ids: list # Optional project IDs to filter the response (up to 100). If omitted, projects in the organization are included across pages (use `cursor` and `limit`).  Pass multiple IDs as repeated query parameters or a comma-separated list: - `project_ids=cold-poetry-09157238&project_ids=quiet-snow-71788278` - `project_ids=cold-poetry-09157238,quiet-snow-71788278`
  --qp-from: string # Specify the start `date-time` for the consumption period. The `date-time` value is rounded according to the specified `granularity`. For example, `2024-03-15T15:30:00Z` for `daily` granularity will be rounded to `2024-03-15T00:00:00Z`. The specified `date-time` value must respect the specified `granularity`: - For `hourly`, consumption metrics are limited to the last 168 hours. - For `daily`, consumption metrics are limited to the last 60 days. - For `monthly`, consumption metrics are limited to the last year.  The earliest allowed `from` value is `March 1, 2024, at 00:00:00 UTC`. Metrics are returned from when the account upgraded to an eligible plan, which may be later than that date.  (format: date-time)
  --qp-to: string # Specify the end `date-time` for the consumption period. The `date-time` value is rounded according to the specified `granularity`. For example, `2024-03-15T15:30:00Z` for `daily` granularity will be rounded to `2024-03-15T00:00:00Z`. The specified `date-time` value must respect the specified `granularity`: - For `hourly`, consumption metrics are limited to the last 168 hours. - For `daily`, consumption metrics are limited to the last 60 days. - For `monthly`, consumption metrics are limited to the last year.  (format: date-time)
  --granularity: string@granularity-completer # Specify the granularity of consumption metrics. Hourly, daily, and monthly metrics are available for the last 168 hours, 60 days, and 1 year, respectively.
  --org-id: string # Organization ID. Metrics are returned for projects in this organization.
  --metrics: list # Required. List the metrics to return. Supported values: - `compute_unit_seconds` - `root_branch_bytes_month` - `child_branch_bytes_month` - `instant_restore_bytes_month` - `public_network_transfer_bytes` - `private_network_transfer_bytes` - `extra_branches_month` - `snapshot_storage_bytes_month`  Pass multiple values as repeated query parameters or a comma-separated list: - `metrics=compute_unit_seconds&metrics=extra_branches_month` - `metrics=compute_unit_seconds,extra_branches_month`
]: nothing -> record<projects: table<project_id: string, periods: list>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "org_id" $org_id "scalar") (serialize-qp "metrics" $metrics "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/consumption_history/v2/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve branch consumption metrics
#
# GET /consumption_history/v2/branches
# operationId: getConsumptionHistoryPerBranchV2
export def "consumption-history-branches get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor from the previous response (`pagination.cursor`). Pass it to fetch the next page of branches. Pages are ordered by project ID, then branch ID.
  --limit: int # Maximum number of branches per page. Allowed range: 1 to 1000. Default: 100.  (default: 100)
  --project-ids: list # Project IDs to include (required, 1 to 100). Returns metrics for branches in these projects.  Pass multiple IDs as repeated query parameters or a comma-separated list: - `project_ids=cold-poetry-09157238&project_ids=quiet-snow-71788278` - `project_ids=cold-poetry-09157238,quiet-snow-71788278`
  --branch-ids: list # Optional branch IDs to filter the response (up to 100). If omitted, all branches in the listed projects are included.  Pass multiple IDs as repeated query parameters or a comma-separated list: - `branch_ids=br-aged-salad-637688&branch_ids=br-sweet-breeze-497520` - `branch_ids=br-aged-salad-637688,br-sweet-breeze-497520`
  --qp-from: string # Specify the start `date-time` for the consumption period. The `date-time` value is rounded according to the specified `granularity`. For example, `2024-03-15T15:30:00Z` for `daily` granularity will be rounded to `2024-03-15T00:00:00Z`. The specified `date-time` value must respect the specified `granularity`: - For `hourly`, consumption metrics are limited to the last 168 hours. - For `daily`, consumption metrics are limited to the last 60 days. - For `monthly`, consumption metrics are limited to the last year.  Branch-level metrics are returned from when the account first ingests branch-level consumption data. Periods before that time contain no branch metrics.  (format: date-time)
  --qp-to: string # Specify the end `date-time` for the consumption period. The `date-time` value is rounded according to the specified `granularity`. For example, `2024-03-15T15:30:00Z` for `daily` granularity will be rounded to `2024-03-15T00:00:00Z`. The specified `date-time` value must respect the specified `granularity`: - For `hourly`, consumption metrics are limited to the last 168 hours. - For `daily`, consumption metrics are limited to the last 60 days. - For `monthly`, consumption metrics are limited to the last year.  (format: date-time)
  --granularity: string@granularity-completer # Specify the granularity of consumption metrics. Hourly, daily, and monthly metrics are available for the last 168 hours, 60 days, and 1 year, respectively.
  --org-id: string # Organization ID. Metrics are returned for projects in this organization.
  --metrics: list # Required. List the metrics to return. Only these values are supported: - `compute_unit_seconds` - `root_branch_bytes_month` - `child_branch_bytes_month` - `instant_restore_bytes_month` - `public_network_transfer_bytes` - `private_network_transfer_bytes`  Not supported on this endpoint: `extra_branches_month`, `snapshot_storage_bytes_month`. Use `GET /consumption_history/v2/projects` for those.  Pass multiple values as repeated query parameters or a comma-separated list: - `metrics=compute_unit_seconds&metrics=public_network_transfer_bytes` - `metrics=compute_unit_seconds,public_network_transfer_bytes`
]: nothing -> record<branches: table<project_id: string, branch_id: string, periods: list>, pagination: record<cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "branch_ids" $branch_ids "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "granularity" $granularity "scalar") (serialize-qp "org_id" $org_id "scalar") (serialize-qp "metrics" $metrics "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/consumption_history/v2/branches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve organization details
#
# GET /organizations/{org_id}
# operationId: getOrganization
export def "organizations get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, handle: string, plan: string, created_at: string, managed_by: string, updated_at: string, allow_hipaa_projects: bool, require_mfa: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List organization API keys
#
# GET /organizations/{org_id}/api_keys
# operationId: listOrgApiKeys
export def "organizations-api-keys listOrgApiKeys" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string, created_at: string, created_by: record<id: string, name: string, image: string>, last_used_at: string, last_used_from_addr: string, project_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/api_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create organization API key
#
# POST /organizations/{org_id}/api_keys
# operationId: createOrgApiKey
export def "organizations-api-keys createOrgApiKey" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key_name: string # A user-specified API key name. This value is required when creating an API key.
  --project-id: string # If set, the API key can access only this project
]: any -> record<id: int, key: string, name: string, created_at: string, created_by: string, project_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/api_keys")
  let body = {key_name: $key_name, project_id: $project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke organization API key
#
# DELETE /organizations/{org_id}/api_keys/{key_id}
# operationId: revokeOrgApiKey
export def "organizations-api-keys revokeOrgApiKey" [
  org_id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, created_at: string, created_by: string, last_used_at: string, last_used_from_addr: string, revoked: bool, project_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/api_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve organization spending limit
#
# GET /organizations/{org_id}/billing/spending_limit
# operationId: getOrganizationSpendingLimit
export def "organizations-billing-spending-limit get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<spending_limit_cents: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/billing/spending_limit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set organization spending limit
#
# PUT /organizations/{org_id}/billing/spending_limit
# operationId: setOrganizationSpendingLimit
export def "organizations-billing-spending-limit setOrganizationSpendingLimit" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  spending_limit_cents: int # Monthly spending cap in cents. Must be positive. To remove a previously configured limit, send a DELETE request to the spending_limit endpoint — `0` and `null` are rejected here. The cap is alert-only: notifications fire at 80% and 100%, but computes are not suspended. Setting a cap below the period's already-accrued spend is permitted and will trigger the over-limit notification on the next worker run.  (format: int64)
]: any -> record<spending_limit_cents: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/billing/spending_limit")
  let body = {spending_limit_cents: $spending_limit_cents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove organization spending limit
#
# DELETE /organizations/{org_id}/billing/spending_limit
# operationId: deleteOrganizationSpendingLimit
export def "organizations-billing-spending-limit delete" [
  org_id: string
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
  let full_url = (build-url $base $"/organizations/($org_id)/billing/spending_limit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List organization members
#
# GET /organizations/{org_id}/members
# operationId: getOrganizationMembers
export def "organizations-members list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer-1 # Sort the members by the specified field. Defaults to `joined_at`. (default: joined_at)
  --cursor: string # A cursor to use in pagination. A cursor defines your place in the data list. Include `response.pagination.next` in subsequent API calls to fetch next page of the list.
  --sort-order: string@sort-order-completer # Defines the sorting order of entities. (default: desc)
  --limit: int # The maximum number of members to return in the response
]: nothing -> record<members: table<member: record, user: record>, pagination: record<next: string, sort_by: string, sort_order: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($org_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve organization member details
#
# GET /organizations/{org_id}/members/{member_id}
# operationId: getOrganizationMember
export def "organizations-members get" [
  org_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, user_id: string, org_id: string, role: string, joined_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update role for organization member
#
# PATCH /organizations/{org_id}/members/{member_id}
# operationId: updateOrganizationMember
export def "organizations-members updateOrganizationMember" [
  org_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role: string@role-completer # The role of the organization member. Some role values may not be available for all organizations.
]: any -> record<id: string, user_id: string, org_id: string, role: string, joined_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/members/($member_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove organization member
#
# DELETE /organizations/{org_id}/members/{member_id}
# operationId: removeOrganizationMember
export def "organizations-members removeOrganizationMember" [
  org_id: string
  member_id: string
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
  let full_url = (build-url $base $"/organizations/($org_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List organization invitations
#
# GET /organizations/{org_id}/invitations
# operationId: getOrganizationInvitations
export def "organizations-invitations get" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<invitations: table<id: string, email: string, org_id: string, invited_by: string, invited_at: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/invitations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create organization invitations
#
# POST /organizations/{org_id}/invitations
# operationId: createOrganizationInvitations
# --invitations item shape: {email: string, role: "admin"|"member"|"editor"|"viewer"|"collaborator"}
export def "organizations-invitations createOrganizationInvitations" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  invitations: list # item shape: {email: string, role: "admin"|"member"|"editor"|"viewer"|"collaborator"}
]: any -> record<invitations: table<id: string, email: string, org_id: string, invited_by: string, invited_at: string, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/invitations")
  let body = {invitations: $invitations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transfer projects between organizations
#
# POST /organizations/{source_org_id}/projects/transfer
# operationId: transferProjectsFromOrgToOrg
export def "organizations-projects-transfer transferProjectsFromOrgToOrg" [
  source_org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_org_id: string # The destination organization identifier
  project_ids: list # The list of projects ids to transfer. Maximum of 400 project ids
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($source_org_id)/projects/transfer")
  let body = {destination_org_id: $destination_org_id, project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List VPC endpoints across all regions
#
# GET /organizations/{org_id}/vpc/vpc_endpoints
# operationId: listOrganizationVPCEndpointsAllRegions
export def "organizations-vpc-vpc-endpoints listOrganizationVPCEndpointsAllRegions" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoints: table<vpc_endpoint_id: string, label: string, region_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/vpc/vpc_endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List VPC endpoints
#
# GET /organizations/{org_id}/vpc/region/{region_id}/vpc_endpoints
# operationId: listOrganizationVPCEndpoints
export def "organizations-vpc-region-vpc-endpoints listOrganizationVPCEndpoints" [
  org_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoints: table<vpc_endpoint_id: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/vpc/region/($region_id)/vpc_endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve VPC endpoint details
#
# GET /organizations/{org_id}/vpc/region/{region_id}/vpc_endpoints/{vpc_endpoint_id}
# operationId: getOrganizationVPCEndpointDetails
export def "organizations-vpc-region-vpc-endpoints get" [
  org_id: string
  region_id: string
  vpc_endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<vpc_endpoint_id: string, label: string, state: string, num_restricted_projects: int, example_restricted_projects: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/vpc/region/($region_id)/vpc_endpoints/($vpc_endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign or update VPC endpoint
#
# POST /organizations/{org_id}/vpc/region/{region_id}/vpc_endpoints/{vpc_endpoint_id}
# operationId: assignOrganizationVPCEndpoint
export def "organizations-vpc-region-vpc-endpoints assignOrganizationVPCEndpoint" [
  org_id: string
  region_id: string
  vpc_endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($org_id)/vpc/region/($region_id)/vpc_endpoints/($vpc_endpoint_id)")
  let body = {label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete VPC endpoint
#
# DELETE /organizations/{org_id}/vpc/region/{region_id}/vpc_endpoints/{vpc_endpoint_id}
# operationId: deleteOrganizationVPCEndpoint
export def "organizations-vpc-region-vpc-endpoints delete" [
  org_id: string
  region_id: string
  vpc_endpoint_id: string
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
  let full_url = (build-url $base $"/organizations/($org_id)/vpc/region/($region_id)/vpc_endpoints/($vpc_endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List supported regions
#
# GET /regions
# operationId: getActiveRegions
export def "regions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: string # Organization ID. When provided, returns only regions available to this organization. Recommended for accurate region availability.
]: nothing -> record<regions: table<region_id: string, name: string, default: bool, geo_lat: string, geo_long: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org_id" $org_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve current user details
#
# GET /users/me
# operationId: getCurrentUserInfo
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active_seconds_limit: int, billing_account: record<state: string, payment_source: record<type: string, card: record>, subscription_type: string, payment_method: string, quota_reset_at_last: string, name: string, email: string, address_city: string, address_country: string, address_country_name: string, address_line1: string, address_line2: string, address_postal_code: string, address_state: string, orb_portal_url: string, tax_id: string, tax_id_type: string, plan_details: record<name: string, version: record>, spending_limit_cents: int>, auth_accounts: table<email: string, image: string, login: string, name: string, provider: string>, email: string, id: string, image: string, login: string, name: string, last_name: string, projects_limit: int, branches_limit: int, max_autoscaling_limit: float, compute_seconds_limit: int, plan: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List organizations for the current user
#
# GET /users/me/organizations
# operationId: getCurrentUserOrganizations
export def "users-me-organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<organizations: table<id: string, name: string, handle: string, plan: string, created_at: string, managed_by: string, updated_at: string, allow_hipaa_projects: bool, require_mfa: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transfer projects from personal account to organization
#
# POST /users/me/projects/transfer
# DEPRECATED
# operationId: transferProjectsFromUserToOrg
@deprecated
export def "users-me-projects-transfer transferProjectsFromUserToOrg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_org_id: string # The destination organization identifier
  project_ids: list # The list of projects ids to transfer. Maximum of 400 project ids
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/projects/transfer")
  let body = {destination_org_id: $destination_org_id, project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve request authentication details
#
# GET /auth
# operationId: getAuthDetails
export def "auth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, auth_method: string, auth_data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create snapshot
#
# POST /projects/{project_id}/branches/{branch_id}/snapshot
# operationId: createSnapshot
export def "projects-branches-snapshot createSnapshot" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lsn: string # The target Log Sequence Number (LSN) to take the snapshot from. Must fall within the restore window. Cannot be used with `timestamp`
  --timestamp: string # The target timestamp for the snapshot. Must fall within the restore window. Use ISO 8601 format (e.g. 2025-08-05T22:00:00Z). Cannot be used with `lsn`.
  --name: string # A name for the snapshot.
  --expires-at: string # The time at which the snapshot will be automatically deleted. Use ISO 8601 format (e.g. 2025-08-05T22:00:00Z).
]: nothing -> record<snapshot: record<id: string, name: string, lsn: string, timestamp: string, source_branch_id: string, created_at: string, expires_at: string, manual: bool, full_size: int, diff_size: int>, operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lsn" $lsn "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "expires_at" $expires_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List project snapshots
#
# GET /projects/{project_id}/snapshots
# operationId: listSnapshots
export def "projects-snapshots listSnapshots" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<snapshots: table<id: string, name: string, lsn: string, timestamp: string, source_branch_id: string, created_at: string, expires_at: string, manual: bool, full_size: int, diff_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete snapshot
#
# DELETE /projects/{project_id}/snapshots/{snapshot_id}
# operationId: deleteSnapshot
export def "projects-snapshots delete" [
  project_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<operations: table<id: string, project_id: string, branch_id: string, endpoint_id: string, action: string, status: string, error: string, failures_count: int, retry_at: string, created_at: string, updated_at: string, total_duration_ms: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/snapshots/($snapshot_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update snapshot
#
# PATCH /projects/{project_id}/snapshots/{snapshot_id}
# operationId: updateSnapshot
# --snapshot shape: {name?: string}
export def "projects-snapshots updateSnapshot" [
  project_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  snapshot: record # shape: {name?: string}
]: any -> record<snapshot: record<id: string, name: string, lsn: string, timestamp: string, source_branch_id: string, created_at: string, expires_at: string, manual: bool, full_size: int, diff_size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/snapshots/($snapshot_id)")
  let body = {snapshot: $snapshot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restore snapshot
#
# POST /projects/{project_id}/snapshots/{snapshot_id}/restore
# operationId: restoreSnapshot
@deprecated --flag name
export def "projects-snapshots-restore restoreSnapshot" [
  project_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # DEPRECATED. Use the `name` field in the request body instead. A name for the newly restored branch. If omitted, a default name will be generated.  (DEPRECATED)
  --name: string # A name for the newly restored branch. If omitted, a default name will be generated.
  --target-branch-id: string # The ID of the branch to restore the snapshot into. If not specified, the branch from which the snapshot was originally created (`snapshot.source_branch_id`) will be used.
  --finalize-restore: oneof<nothing, bool> # Set to `true` to finalize the restore operation immediately. This will complete the restore and move any associated computes to the new branch, similar to the `finalizeRestoreBranch` operation. Defaults to `false` to allow previewing the restored snapshot data first.  (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/snapshots/($snapshot_id)/restore" $qp)
  let body = {name: $name, target_branch_id: $target_branch_id, finalize_restore: $finalize_restore} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve backup schedule
#
# GET /projects/{project_id}/branches/{branch_id}/backup_schedule
# operationId: getSnapshotSchedule
export def "projects-branches-backup-schedule get" [
  project_id: string
  branch_id: string
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
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/backup_schedule")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update backup schedule
#
# PUT /projects/{project_id}/branches/{branch_id}/backup_schedule
# operationId: setSnapshotSchedule
# --schedule item shape: {frequency: string, hour?: int, day?: int, month?: int, retention_seconds?: int}
export def "projects-branches-backup-schedule setSnapshotSchedule" [
  project_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule: list # item shape: {frequency: string, hour?: int, day?: int, month?: int, retention_seconds?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/branches/($branch_id)/backup_schedule")
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
