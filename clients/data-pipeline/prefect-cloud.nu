# Auto-generated client for Prefect Cloud API v0.8.4
# Source: https://api.prefect.cloud/api/openapi.json
# Auth: --token flag or $env.PREFECT_CLOUD_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PREFECT_CLOUD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def permission-completer [] { ["add:account_member" "administrate:sso" "administrate:workspace" "bypass:sso" "create:account_role" "create:audit_event" "create:bot" "create:invitation" "create:team" "create:workspace" "create:workspace_invitation" "create:workspace_role" "delete:account" "delete:account_membership" "delete:account_role" "delete:bot" "delete:mex-storage" "delete:team" "delete:workspace" "delete:workspace_role" "read:account" "read:account_membership" "read:account_role" "read:audit_event" "read:billing" "read:bot" "read:integrations" "read:invitation" "read:ip_allowlist" "read:mex-storage" "read:sso" "read:team" "read:workspace" "read:workspace_invitation" "read:workspace_role" "update:account" "update:account_membership" "update:account_role" "update:billing" "update:bot" "update:integrations" "update:invitation" "update:ip_allowlist" "update:mex-storage" "update:team" "update:workspace_invitation" "update:workspace_role"] }
def scope-completer [] { ["manage_acls" "manage_artifacts" "manage_assets" "manage_automations" "manage_blocks" "manage_concurrency_limits" "manage_deployments" "manage_event_publications" "manage_event_subscriptions" "manage_events" "manage_flows" "manage_incidents" "manage_mex_deploy" "manage_mex_storage" "manage_notifications" "manage_saved_search" "manage_tags" "manage_variables" "manage_webhooks" "manage_work_pools" "manage_work_queues" "manage_workers" "manage_workspace_service_accounts" "manage_workspace_settings" "manage_workspace_teams" "manage_workspace_users" "run_deployments" "run_flows" "run_tasks" "see_artifacts" "see_assets" "see_automations" "see_blocks" "see_concurrency_limits" "see_deployments" "see_event_publications" "see_event_subscriptions" "see_events" "see_flows" "see_incidents" "see_notifications" "see_secret_blocks" "see_tags" "see_variables" "see_webhooks" "see_work_pools" "see_work_queues" "see_workers" "see_workspace_service_accounts" "see_workspace_settings" "see_workspace_users" "write_artifacts" "write_assets" "write_deployments" "write_incidents" "write_notifications" "write_variables" "write_work_pools" "write_work_queues" "write_workers" "write_workspace_settings"] }
def tier-completer [] { ["ENTERPRISE" "FREE_2025_04" "PRO" "PRO_2024_04" "STARTER" "TEAM"] }
def time-unit-completer [] { ["day" "hour" "minute" "second" "week"] }
def order-completer [] { ["ASC" "DESC"] }
def sort-completer [] { ["CREATED_DESC" "NAME_ASC" "NAME_DESC" "UPDATED_DESC"] }
def severity-completer [] { ["critical" "high" "low" "minor" "moderate"] }
def sort-completer-1 [] { ["CREATED_ASC" "CREATED_DESC" "KEY_EXPIRATION_ASC" "KEY_EXPIRATION_DESC" "NAME_ASC" "NAME_DESC" "UPDATED_ASC" "UPDATED_DESC"] }
def resolution-completer [] { ["1" "1440" "15" "360" "5" "60"] }
def group-by-completer [] { ["deployment" "flow" "tag" "work-pool"] }
def sort-completer-2 [] { ["LAST_SEEN_ASC" "LAST_SEEN_DESC" "NAME_ASC" "NAME_DESC"] }
def sort-completer-3 [] { ["asc" "desc"] }
def sort-completer-4 [] { ["TIMESTAMP_ASC" "TIMESTAMP_DESC"] }
def order-by-completer [] { ["LAST_SEEN_DESC" "NAME_ASC"] }
def sort-completer-5 [] { ["CREATED_DESC" "ID_DESC" "KEY_ASC" "KEY_DESC" "UPDATED_DESC"] }
def sort-completer-6 [] { ["CREATED_ASC" "CREATED_DESC" "NAME_ASC" "NAME_DESC" "UPDATED_ASC" "UPDATED_DESC"] }
def sort-completer-7 [] { ["DURATION_DESC" "END_TIME_DESC" "EXPECTED_START_TIME_ASC" "EXPECTED_START_TIME_DESC" "ID_DESC" "LATENESS_DESC" "NAME_ASC" "NAME_DESC" "NEXT_SCHEDULED_START_TIME_ASC" "START_TIME_ASC" "START_TIME_DESC"] }
def sort-completer-8 [] { ["END_TIME_DESC" "EXPECTED_START_TIME_ASC" "EXPECTED_START_TIME_DESC" "ID_DESC" "NAME_ASC" "NAME_DESC" "NEXT_SCHEDULED_START_TIME_ASC"] }
def resource-type-completer [] { ["deployment" "flow" "work_pool"] }
def mode-completer [] { ["concurrency" "rate_limit"] }
def sort-completer-9 [] { ["NAME_ASC" "NAME_DESC"] }
def sort-completer-10 [] { ["CLIENT_VERSION_ASC" "CLIENT_VERSION_DESC" "LAST_HEARTBEAT_ASC" "LAST_HEARTBEAT_DESC" "NAME_ASC" "NAME_DESC" "STATUS_ASC" "STATUS_DESC"] }
def direction-completer [] { ["asc" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "workspace-scopes get" } } | get name | first)
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

# Get Workspace Scopes
#
# GET /api/workspace_scopes
# operationId: get_workspace_scopes_api_workspace_scopes_get
export def "workspace-scopes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, title: string, feature_group: string, includes_scopes: list<string>, see_scope: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/workspace_scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Permissions
#
# GET /api/accounts/permissions
# operationId: list_permissions_api_accounts_permissions_get
export def "accounts-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/accounts/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Account
#
# GET /api/accounts/{account_id}
# operationId: read_account_api_accounts__account_id__get
export def "accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<location: any, link: any, image_location: any, stripe_customer_id: any, auth_expiration_seconds: any, status_last_updated: any, id: string, created: any, updated: any, name: string, handle: string, settings: record<allow_public_workspaces: bool, ai_log_summaries: bool, managed_execution: bool, enforce_ip_allowlist: bool, enforce_webhook_authentication: bool, self_healing_enabled: bool, enabled_feature_flags: list<string>, default_result_storage: any>, status: string, workos_connection_ids: list<string>, workos_directory_ids: list<string>, workos_organization_id: any, plan_type: string, plan_tier: any, self_serve: bool, scim_state: string, sso_state: string, billing_email: any, features: list<string>, max_deployments_per_workspace: any, work_pool_limit: any, non_mex_work_pool_limit: any, mex_work_pool_limit: int, run_retention_days: int, audit_log_retention_days: int, automations_limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Account
#
# PATCH /api/accounts/{account_id}
# operationId: update_account_api_accounts__account_id__patch
export def "accounts patch" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: any # The account name.
  --handle: any # A unique identifier for the account containing only lowercase letters, numbers, and dashes.
  --location: any # An optional physical location for the account, e.g. Washington, D.C.
  --link: any # An optional for an external url associated with the account, e.g. https://prefect.io/.
  --auth-expiration-seconds: any # The number of seconds a user should be considered to be authenticated against this Account.
  --settings: any # The account settings.
  --billing-email: any # Billing email to apply to the account's stripe customer.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)")
  let body = {name: $name, handle: $handle, location: $location, link: $link, auth_expiration_seconds: $auth_expiration_seconds, settings: $settings, billing_email: $billing_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Account
#
# DELETE /api/accounts/{account_id}
# operationId: delete_account_api_accounts__account_id__delete
export def "accounts delete" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Account Settings
#
# GET /api/accounts/{account_id}/settings
# operationId: read_account_settings_api_accounts__account_id__settings_get
export def "accounts-settings get" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Account Settings
#
# PATCH /api/accounts/{account_id}/settings
# operationId: update_account_settings_api_accounts__account_id__settings_patch
export def "accounts-settings patch" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-public-workspaces: any # Whether or not this account allows public workspaces.
  --ai-log-summaries: any # Whether to use AI to generate log summaries.
  --managed-execution: any # Whether to enable the use of managed work pools
  --enforce-ip-allowlist: any # Whether to enforce account's IP allowlist.
  --enforce-webhook-authentication: any # Whether to enforce webhook authentication.
  --self-healing-enabled: any # Whether to automatically create managed automations for new workspaces.
  --default-result-storage: any # The account-owned template to use when materializing the account's default result storage into inheriting workspaces.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/settings")
  let body = {allow_public_workspaces: $allow_public_workspaces, ai_log_summaries: $ai_log_summaries, managed_execution: $managed_execution, enforce_ip_allowlist: $enforce_ip_allowlist, enforce_webhook_authentication: $enforce_webhook_authentication, self_healing_enabled: $self_healing_enabled, default_result_storage: $default_result_storage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Account Domains
#
# GET /api/accounts/{account_id}/domains
# operationId: read_account_domains_api_accounts__account_id__domains_get
export def "accounts-domains get" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Account Domains
#
# PATCH /api/accounts/{account_id}/domains
# operationId: update_account_domains_api_accounts__account_id__domains_patch
export def "accounts-domains patch" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain_names: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/domains")
  let body = {domain_names: $domain_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Account Usage Limits
#
# GET /api/accounts/{account_id}/usage_limits
# operationId: read_account_usage_limits_api_accounts__account_id__usage_limits_get
export def "accounts-usage-limits get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<audit_log_retention_days: any, automations_limit: any, log_rate_limit: any, max_deployments_per_workspace: any, mex_compute_limit: any, mex_concurrency_limit: any, mex_work_pool_limit: any, non_mex_work_pool_limit: any, orchestration_rate_limit: any, run_retention_days: any, user_limit: any, free_user_slots: any, work_pool_limit: any, workspace_limit: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/usage_limits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Account Usage
#
# GET /api/accounts/{account_id}/usage
# operationId: read_account_usage_api_accounts__account_id__usage_get
export def "accounts-usage get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, automations: int, deployments: int, mex_compute: int, work_pools: int, non_managed_work_pools: int, managed_work_pools: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Account Image
#
# GET /api/accounts/{account_id}/image
# operationId: get_account_image_api_accounts__account_id__image_get
export def "accounts-image get" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/image")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Account Image
#
# PUT /api/accounts/{account_id}/image
# operationId: upload_account_image_api_accounts__account_id__image_put
export def "accounts-image put" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/image")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete Account Image
#
# DELETE /api/accounts/{account_id}/image
# operationId: delete_account_image_api_accounts__account_id__image_delete
export def "accounts-image delete" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/image")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Team
#
# POST /api/accounts/{account_id}/teams/
# operationId: create_team_api_accounts__account_id__teams__post
export def "accounts-teams post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the team.
  --description: any # An optional description of the team. (default: )
]: any -> record<id: string, created: any, updated: any, account_id: string, name: string, description: any, workos_directory_group_id: any, memberships: table<id: string, handle: string, name: string, email: any, type: string>, workspaces: table<workspace_id: string, workspace_handle: string, workspace_role_id: string, workspace_role_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/teams/")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Team
#
# GET /api/accounts/{account_id}/teams/{id}
# operationId: read_team_api_accounts__account_id__teams__id__get
export def "accounts-teams get" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, account_id: string, name: string, description: any, workos_directory_group_id: any, memberships: table<id: string, handle: string, name: string, email: any, type: string>, workspaces: table<workspace_id: string, workspace_handle: string, workspace_role_id: string, workspace_role_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team
#
# PUT /api/accounts/{account_id}/teams/{id}
# operationId: update_team_api_accounts__account_id__teams__id__put
export def "accounts-teams put" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the team.
  --description: any # An optional description of the team. (default: )
  --workos-directory-group-id: any # The id of the WorkOS directory group that this team should be associated with.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/teams/($id)")
  let body = {name: $name, description: $description, workos_directory_group_id: $workos_directory_group_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Team
#
# DELETE /api/accounts/{account_id}/teams/{id}
# operationId: delete_team_api_accounts__account_id__teams__id__delete
export def "accounts-teams delete" [
  id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Teams
#
# POST /api/accounts/{account_id}/teams/filter
# operationId: read_teams_api_accounts__account_id__teams_filter_post
# --teams shape: {id?: any, name?: any, directory_id?: any, workspace_id?: any, workspace_role_id?: any, member_id?: any}
# --users shape: {id?: any, email?: any, handle?: any, name?: any}
# --bots shape: {id?: any, name?: any}
export def "accounts-teams-filter post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teams: record # shape: {id?: any, name?: any, directory_id?: any, workspace_id?: any, workspace_role_id?: any, member_id?: any}
  --users: record # shape: {id?: any, email?: any, handle?: any, name?: any}
  --bots: record # shape: {id?: any, name?: any}
  --body-sort: any
  --limit: int # default: 200
  --offset: int # default: 0
]: any -> table<id: string, created: any, updated: any, account_id: string, name: string, description: any, workos_directory_group_id: any, memberships: list<record>, workspaces: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/teams/filter")
  let body = {teams: $teams, users: $users, bots: $bots, sort: $body_sort, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert Team Members
#
# PUT /api/accounts/{account_id}/teams/{id}/members
# operationId: upsert_team_members_api_accounts__account_id__teams__id__members_put
# --members item shape: {member_id: string, member_type: "user"|"service_account"}
export def "accounts-teams-members put" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # item shape: {member_id: string, member_type: "user"|"service_account"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/teams/($id)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Team Member
#
# DELETE /api/accounts/{account_id}/teams/{team_id}/members/{actor_id}
# operationId: remove_team_member_api_accounts__account_id__teams__team_id__members__actor_id__delete
export def "accounts-teams-members delete" [
  account_id: string
  team_id: string
  actor_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/teams/($team_id)/members/($actor_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Account Memberships
#
# POST /api/accounts/{account_id}/account_memberships/filter
# operationId: read_account_memberships_api_accounts__account_id__account_memberships_filter_post
export def "accounts-account-memberships-filter post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --offset: int # default: 0
  --account-memberships: any
  --body-sort: any
  --only-users: string@bool-completer # default: false
  --only-bots: string@bool-completer # default: false
  --active: any
]: any -> table<id: string, actor_id: string, user_id: any, first_name: any, last_name: any, handle: any, email: any, account_role_name: string, account_role_id: string, last_login: any, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/filter")
  let body = {limit: $limit, offset: $offset, account_memberships: $account_memberships, sort: $body_sort, only_users: $only_users, only_bots: $only_bots, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download User Account Memberships Csv
#
# GET /api/accounts/{account_id}/account_memberships/download
# operationId: download_user_account_memberships_csv_api_accounts__account_id__account_memberships_download_get
export def "accounts-account-memberships-download get" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Account Memberships
#
# POST /api/accounts/{account_id}/account_memberships/count
# operationId: count_account_memberships_api_accounts__account_id__account_memberships_count_post
export def "accounts-account-memberships-count post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-memberships: any
  --filter: any
  --only-users: string@bool-completer # default: false
  --only-bots: string@bool-completer # default: false
  --active: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/count")
  let body = {account_memberships: $account_memberships, filter: $filter, only_users: $only_users, only_bots: $only_bots, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Account Membership By User
#
# GET /api/accounts/{account_id}/account_memberships/by-user/{user_id}
# operationId: read_account_membership_by_user_api_accounts__account_id__account_memberships_by_user__user_id__get
export def "accounts-account-memberships-by-user get" [
  user_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: string, updated: string, actor_id: string, account_id: string, user_id: any, handle: string, first_name: any, last_name: any, email: any, account_role_id: string, account_role_name: string, directory_id: any, timezone: any, teams: table<id: string, name: string>, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/by-user/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Account Membership By Bot
#
# GET /api/accounts/{account_id}/account_memberships/by-bot/{bot_id}
# operationId: read_account_membership_by_bot_api_accounts__account_id__account_memberships_by_bot__bot_id__get
export def "accounts-account-memberships-by-bot get" [
  bot_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: string, updated: string, actor_id: string, account_id: string, user_id: any, handle: string, first_name: any, last_name: any, email: any, account_role_id: string, account_role_name: string, directory_id: any, timezone: any, teams: table<id: string, name: string>, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/by-bot/($bot_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Account Membership
#
# GET /api/accounts/{account_id}/account_memberships/{id}
# operationId: read_account_membership_api_accounts__account_id__account_memberships__id__get
export def "accounts-account-memberships get" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: string, updated: string, actor_id: string, account_id: string, user_id: any, handle: string, first_name: any, last_name: any, email: any, account_role_id: string, account_role_name: string, directory_id: any, timezone: any, teams: table<id: string, name: string>, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Account Membership
#
# PATCH /api/accounts/{account_id}/account_memberships/{id}
# operationId: update_account_membership_api_accounts__account_id__account_memberships__id__patch
export def "accounts-account-memberships patch" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_role_id: string # The account role id. The account role defines permissions for the actor in this account. (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/($id)")
  let body = {account_role_id: $account_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Account Membership
#
# DELETE /api/accounts/{account_id}/account_memberships/{id}
# operationId: delete_account_membership_api_accounts__account_id__account_memberships__id__delete
export def "accounts-account-memberships delete" [
  id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle Account Membership Active
#
# PATCH /api/accounts/{account_id}/account_memberships/{id}/active
# operationId: toggle_account_membership_active_api_accounts__account_id__account_memberships__id__active_patch
export def "accounts-account-memberships-active patch" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/($id)/active")
  let body = {active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Set Account Membership Active
#
# POST /api/accounts/{account_id}/account_memberships/set_active
# operationId: bulk_set_account_membership_active_api_accounts__account_id__account_memberships_set_active_post
export def "accounts-account-memberships-set-active post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  membership_ids: list
  --active: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_memberships/set_active")
  let body = {membership_ids: $membership_ids, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Account Role
#
# GET /api/accounts/{account_id}/account_roles/{id}
# operationId: read_account_role_api_accounts__account_id__account_roles__id__get
export def "accounts-account-roles get" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, account_id: any, name: string, permissions: list<string>, is_system_role: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Account Role
#
# PATCH /api/accounts/{account_id}/account_roles/{id}
# operationId: update_account_role_api_accounts__account_id__account_roles__id__patch
export def "accounts-account-roles patch" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: any # The name of the account role.
  --permissions: any # The list of account permissions held by this role. Defines the actions account members assigned this role are allowed to take.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_roles/($id)")
  let body = {name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Account Role
#
# DELETE /api/accounts/{account_id}/account_roles/{id}
# operationId: delete_account_role_api_accounts__account_id__account_roles__id__delete
export def "accounts-account-roles delete" [
  id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Account Roles
#
# POST /api/accounts/{account_id}/account_roles/filter
# operationId: read_account_roles_api_accounts__account_id__account_roles_filter_post
export def "accounts-account-roles-filter post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --offset: int # default: 0
  --account-roles: any
]: any -> table<id: string, created: any, updated: any, account_id: any, name: string, permissions: list<string>, is_system_role: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/account_roles/filter")
  let body = {limit: $limit, offset: $offset, account_roles: $account_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Sso Setup Url
#
# GET /api/accounts/{account_id}/sso/setup_url
# operationId: read_sso_setup_url_api_accounts__account_id__sso_setup_url_get
export def "accounts-sso-setup-url get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/sso/setup_url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Dsync Setup Url
#
# GET /api/accounts/{account_id}/sso/dsync_setup_url
# operationId: read_dsync_setup_url_api_accounts__account_id__sso_dsync_setup_url_get
export def "accounts-sso-dsync-setup-url get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/sso/dsync_setup_url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate
#
# POST /api/accounts/{account_id}/sso/validate
# operationId: validate_api_accounts__account_id__sso_validate_post
export def "accounts-sso-validate post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --redirect-uri: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/sso/validate")
  let body = {redirect_uri: $redirect_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Integrations
#
# GET /api/accounts/{account_id}/sso/integrations
# operationId: integrations_api_accounts__account_id__sso_integrations_get
export def "accounts-sso-integrations get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_id: any, connections: list<record>, directories: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/sso/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Integration
#
# DELETE /api/accounts/{account_id}/sso/integrations/{integration_id}
# operationId: remove_integration_api_accounts__account_id__sso_integrations__integration_id__delete
export def "accounts-sso-integrations delete" [
  account_id: string
  integration_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/sso/integrations/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Bot
#
# POST /api/accounts/{account_id}/bots/
# operationId: create_bot_api_accounts__account_id__bots__post
export def "accounts-bots post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the bot.
  --api-key-expiration: any # The time at which bot's api key expires. If `None`, the api key will not expire.
  --account-role-id: any # The account role id to assign the bot. If `None` the bot will be assignedthe MEMBER role by `models.bots.create_bot`
]: any -> record<id: string, created: any, updated: any, actor_id: string, account_id: string, name: string, account_role_name: string, api_key: record<id: string, created: any, name: string, expiration: any, key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/bots/")
  let body = {name: $name, api_key_expiration: $api_key_expiration, account_role_id: $account_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Bot
#
# GET /api/accounts/{account_id}/bots/{id}
# operationId: read_bot_api_accounts__account_id__bots__id__get
export def "accounts-bots get" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, actor_id: string, account_id: string, name: string, account_role_name: string, api_key: record<id: string, created: any, name: string, expiration: any, masked_key: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/bots/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Bot
#
# PATCH /api/accounts/{account_id}/bots/{id}
# operationId: update_bot_api_accounts__account_id__bots__id__patch
export def "accounts-bots patch" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: any # The name of the bot.
  --account-role-id: any # The account role id to assign the bot.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/bots/($id)")
  let body = {name: $name, account_role_id: $account_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Bot
#
# DELETE /api/accounts/{account_id}/bots/{id}
# operationId: delete_bot_api_accounts__account_id__bots__id__delete
export def "accounts-bots delete" [
  id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/bots/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Bots
#
# POST /api/accounts/{account_id}/bots/filter
# operationId: read_bots_api_accounts__account_id__bots_filter_post
export def "accounts-bots-filter post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --offset: int # default: 0
  --service-accounts: any
]: any -> table<id: string, created: any, updated: any, actor_id: string, account_id: string, name: string, account_role_name: string, api_key: record<id: string, created: any, name: string, expiration: any, masked_key: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/bots/filter")
  let body = {limit: $limit, offset: $offset, service_accounts: $service_accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate Api Key
#
# POST /api/accounts/{account_id}/bots/{id}/rotate_api_key
# operationId: rotate_api_key_api_accounts__account_id__bots__id__rotate_api_key_post
export def "accounts-bots-rotate-api-key post" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-key-expiration: any # The time at which the bot's new api key (the one created by calling this endpoint) will expire. If `None`, the api key will not expire.
  --old-key-expires-in-seconds: any # Provide this field to set an expiration for the currently active api key. If not provided or provided Null, the current key will be deleted. If provided, it cannot be more than 48 hours (172800 seconds) in the future.
]: any -> record<id: string, created: any, updated: any, actor_id: string, account_id: string, name: string, account_role_name: string, api_key: record<id: string, created: any, name: string, expiration: any, key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/bots/($id)/rotate_api_key")
  let body = {api_key_expiration: $api_key_expiration, old_key_expires_in_seconds: $old_key_expires_in_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Bot Api Keys
#
# GET /api/accounts/{account_id}/bots/{id}/read_bot_api_keys
# operationId: read_bot_api_keys_api_accounts__account_id__bots__id__read_bot_api_keys_get
export def "accounts-bots-read-bot-api-keys get" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active_key: record<id: string, created: any, name: string, expiration: any, masked_key: any>, rotating_keys: table<id: string, created: any, name: string, expiration: any, masked_key: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/bots/($id)/read_bot_api_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Bot Api Key
#
# DELETE /api/accounts/{account_id}/bots/{id}/delete_bot_api_key/{api_key_id}
# operationId: delete_bot_api_key_api_accounts__account_id__bots__id__delete_bot_api_key__api_key_id__delete
export def "accounts-bots-delete-bot-api-key delete" [
  id: string
  api_key_id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/bots/($id)/delete_bot_api_key/($api_key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Invitation
#
# POST /api/accounts/{account_id}/invitations/
# operationId: create_invitation_api_accounts__account_id__invitations__post
export def "accounts-invitations post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, created: any, updated: any, email: string, account_id: string, account_role_id: string, status: string, expiration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/invitations/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Invitation
#
# GET /api/accounts/{account_id}/invitations/{id}
# operationId: read_invitation_api_accounts__account_id__invitations__id__get
export def "accounts-invitations get" [
  account_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, email: string, account_id: string, account_role_id: string, status: string, expiration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/invitations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Invitations
#
# POST /api/accounts/{account_id}/invitations/filter
# operationId: read_invitations_api_accounts__account_id__invitations_filter_post
export def "accounts-invitations-filter post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invitations: any
  --limit: int # default: 200
  --offset: int # default: 0
]: any -> table<id: string, created: any, updated: any, email: string, account_id: string, account_role_id: string, status: string, expiration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/invitations/filter")
  let body = {invitations: $invitations, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Invitations
#
# POST /api/accounts/{account_id}/invitations/count
# operationId: count_invitations_api_accounts__account_id__invitations_count_post
export def "accounts-invitations-count post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invitations: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/invitations/count")
  let body = {invitations: $invitations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke Invitation
#
# POST /api/accounts/{account_id}/invitations/{id}/revoke
# operationId: revoke_invitation_api_accounts__account_id__invitations__id__revoke_post
export def "accounts-invitations-revoke post" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/invitations/($id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Workspace
#
# POST /api/accounts/{account_id}/workspaces/
# operationId: create_workspace_api_accounts__account_id__workspaces__post
export def "accounts-workspaces post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The workspace name
  --description: any # A description of the workspace (default: )
  handle: string # A unique handle for the workspace
]: any -> record<id: string, created: any, updated: any, account_id: string, name: string, description: any, handle: string, default_workspace_role_id: any, is_public: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/")
  let body = {name: $name, description: $description, handle: $handle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}
# operationId: read_workspace_api_accounts__account_id__workspaces__workspace_id__get
export def "accounts-workspaces get" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, account_id: string, name: string, description: any, handle: string, default_workspace_role_id: any, is_public: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Workspace
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}
# operationId: update_workspace_api_accounts__account_id__workspaces__workspace_id__patch
export def "accounts-workspaces patch" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: any # The workspace name
  --handle: any # A unique handle for the workspace
  --description: any # A description of the workspace (default: )
  --default-workspace-role-id: any # The default workspace role id.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)")
  let body = {name: $name, handle: $handle, description: $description, default_workspace_role_id: $default_workspace_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Workspace
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}
# operationId: delete_workspace_api_accounts__account_id__workspaces__workspace_id__delete
export def "accounts-workspaces delete" [
  workspace_id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Workspaces
#
# POST /api/accounts/{account_id}/workspaces/filter
# operationId: read_workspaces_api_accounts__account_id__workspaces_filter_post
export def "accounts-workspaces-filter post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --offset: int # default: 0
  --workspaces: any
]: any -> table<id: string, created: any, updated: any, account_id: string, name: string, description: any, handle: string, default_workspace_role_id: any, is_public: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/filter")
  let body = {limit: $limit, offset: $offset, workspaces: $workspaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer Workspace
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/transfer
# operationId: transfer_workspace_api_accounts__account_id__workspaces__workspace_id__transfer_post
export def "accounts-workspaces-transfer post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  to_account_id: string # format: uuid
  --new-handle: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/transfer")
  let body = {to_account_id: $to_account_id, new_handle: $new_handle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate Transfer Workspace
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/validate_transfer
# operationId: validate_transfer_workspace_api_accounts__account_id__workspaces__workspace_id__validate_transfer_post
export def "accounts-workspaces-validate-transfer post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  to_account_id: string # format: uuid
  --new-handle: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/validate_transfer")
  let body = {to_account_id: $to_account_id, new_handle: $new_handle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Workspace Without Account Id
#
# GET /api/workspaces/{workspace_id}
# operationId: find_workspace_without_account_id_api_workspaces__workspace_id__get
export def "workspaces get" [
  workspace_id: string
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
  let full_url = (build-url $base $"/api/workspaces/($workspace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Workspace Settings
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/settings
# operationId: read_workspace_settings_api_accounts__account_id__workspaces__workspace_id__settings_get
export def "accounts-workspaces-settings get" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<inherit_default_result_storage: bool, default_result_storage_block_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Workspace Settings
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/settings
# operationId: update_workspace_settings_api_accounts__account_id__workspaces__workspace_id__settings_patch
export def "accounts-workspaces-settings patch" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inherit-default-result-storage: any # Whether the workspace should inherit its default result storage from the account.
  --default-result-storage-block-id: any # The block document ID of the workspace's default result storage block.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/settings")
  let body = {inherit_default_result_storage: $inherit_default_result_storage, default_result_storage_block_id: $default_result_storage_block_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Workspace Role
#
# POST /api/accounts/{account_id}/workspace_roles/
# operationId: create_workspace_role_api_accounts__account_id__workspace_roles__post
export def "accounts-workspace-roles post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The workspace role name
  --description: string # A short description of the role. (default: )
  --scopes: list # The workspace role's scopes.
  --inherited-role-id: any # An optional built-in workspace role id from which this workspace role inherits.
]: any -> record<id: string, created: any, updated: any, account_id: any, name: string, description: string, permissions: list<string>, scopes: list<string>, inherited_role_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspace_roles/")
  let body = {name: $name, description: $description, scopes: $scopes, inherited_role_id: $inherited_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Workspace Role
#
# PATCH /api/accounts/{account_id}/workspace_roles/{id}
# operationId: update_workspace_role_api_accounts__account_id__workspace_roles__id__patch
export def "accounts-workspace-roles patch" [
  account_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: any # The workspace role name.
  --description: any # A short description of the role.
  --scopes: list # The workspace role's scopes.
  --inherited-role-id: any # An optional built-in workspace role id from which this workspace role inherits.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspace_roles/($id)")
  let body = {name: $name, description: $description, scopes: $scopes, inherited_role_id: $inherited_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Workspace Role
#
# DELETE /api/accounts/{account_id}/workspace_roles/{id}
# operationId: delete_workspace_role_api_accounts__account_id__workspace_roles__id__delete
export def "accounts-workspace-roles delete" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspace_roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Workspace Role
#
# GET /api/accounts/{account_id}/workspace_roles/{id}
# operationId: read_workspace_role_api_accounts__account_id__workspace_roles__id__get
export def "accounts-workspace-roles get" [
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, account_id: any, name: string, description: string, permissions: list<string>, scopes: list<string>, inherited_role_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspace_roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Workspace Roles
#
# POST /api/accounts/{account_id}/workspace_roles/filter
# operationId: read_workspace_roles_api_accounts__account_id__workspace_roles_filter_post
export def "accounts-workspace-roles-filter post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --offset: int # default: 0
  --workspace-roles: any
]: any -> table<id: string, created: any, updated: any, account_id: any, name: string, description: string, permissions: list<string>, scopes: list<string>, inherited_role_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspace_roles/filter")
  let body = {limit: $limit, offset: $offset, workspace_roles: $workspace_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Rate Limit Status
#
# GET /api/accounts/{account_id}/rate-limits/status
# operationId: read_rate_limit_status_api_accounts__account_id__rate_limits_status_get
export def "accounts-rate-limits-status get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<exceeded_buckets: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limits/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Rate Limit Usage
#
# GET /api/accounts/{account_id}/rate-limits/usage
# operationId: read_rate_limit_usage_api_accounts__account_id__rate_limits_usage_get
export def "accounts-rate-limits-usage get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start date of the usage period (format: date-time)
  --until: string # The end date of the usage period (format: date-time)
  --keys: list # The keys to query usage for
]: nothing -> record<account: string, since: string, until: string, minutes: list<string>, keys: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "keys" $keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limits/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Rate Limit Usage
#
# GET /api/accounts/{account_id}/rate-limits/usage/download
# operationId: download_rate_limit_usage_api_accounts__account_id__rate_limits_usage_download_get
export def "accounts-rate-limits-usage-download get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The start date of the usage period (format: date-time)
  --until: string # The end date of the usage period (format: date-time)
  --keys: list # The keys to query usage for
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "keys" $keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limits/usage/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Orchestration Api Grouped Usage
#
# GET /api/accounts/{account_id}/rate-limits/orchestration-api
# operationId: read_orchestration_api_grouped_usage_api_accounts__account_id__rate_limits_orchestration_api_get
export def "accounts-rate-limits-orchestration-api get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start time of the usage period (inclusive) (format: date-time)
  --until: string # End time of the usage period (inclusive) (format: date-time)
  --group-by: string # The dimension to group usage by (e.g., workspace_id, api_key_name)
  --workspace-id: string # Filter by workspace ID
  --api-key-name: string # Filter by API key name
  --actor-name: string # Filter by actor name
]: nothing -> record<account: string, since: string, until: string, limit: int, minutes: list<string>, groups: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "workspace_id" $workspace_id "scalar") (serialize-qp "api_key_name" $api_key_name "scalar") (serialize-qp "actor_name" $actor_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limits/orchestration-api" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Events Grouped Usage
#
# GET /api/accounts/{account_id}/rate-limits/events
# operationId: read_events_grouped_usage_api_accounts__account_id__rate_limits_events_get
export def "accounts-rate-limits-events get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start time of the usage period (inclusive) (format: date-time)
  --until: string # End time of the usage period (inclusive) (format: date-time)
  --group-by: string # The dimension to group usage by (e.g., workspace_id, event_name)
  --workspace-id: string # Filter by workspace ID
  --api-key-name: string # Filter by API key name
  --actor-name: string # Filter by actor name
]: nothing -> record<account: string, since: string, until: string, limit: int, minutes: list<string>, groups: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "workspace_id" $workspace_id "scalar") (serialize-qp "api_key_name" $api_key_name "scalar") (serialize-qp "actor_name" $actor_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limits/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Api Key Names
#
# GET /api/accounts/{account_id}/rate-limits/api-key-names
# operationId: list_api_key_names_api_accounts__account_id__rate_limits_api_key_names_get
export def "accounts-rate-limits-api-key-names get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start time of the search period (inclusive) (format: date-time)
  --until: string # End time of the search period (inclusive) (format: date-time)
  --search: string # Fuzzy search string (case-insensitive substring match)
  --limit: int # Maximum number of results to return (default: 50)
  --keys: string # Filter to specific rate limit keys (e.g., orchestration-api, logs-and-events)
]: nothing -> record<values: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "keys" $keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limits/api-key-names" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Actor Names
#
# GET /api/accounts/{account_id}/rate-limits/actor-names
# operationId: list_actor_names_api_accounts__account_id__rate_limits_actor_names_get
export def "accounts-rate-limits-actor-names get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Start time of the search period (inclusive) (format: date-time)
  --until: string # End time of the search period (inclusive) (format: date-time)
  --search: string # Fuzzy search string (case-insensitive substring match)
  --limit: int # Maximum number of results to return (default: 50)
  --keys: string # Filter to specific rate limit keys (e.g., orchestration-api, logs-and-events)
]: nothing -> record<values: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "keys" $keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limits/actor-names" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Managed Execution Details
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/managed_execution/details
# operationId: read_managed_execution_details_api_accounts__account_id__workspaces__workspace_id__managed_execution_details_get
export def "accounts-workspaces-managed-execution-details get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<compute_usage_seconds: int, compute_usage_limit_seconds: int, mex_concurrency_limit: int, mex_work_pool_limit: int, next_compute_usage_reset_date: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/managed_execution/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Managed Execution Usage
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/managed_execution/usage
# operationId: read_managed_execution_usage_api_accounts__account_id__workspaces__workspace_id__managed_execution_usage_get
export def "accounts-workspaces-managed-execution-usage get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string
  --until: string
  --group-by: string
  --max-groups: int # Maximum number of resource groups to return separately before __other__. (default: 10)
]: nothing -> record<account: string, workspace: string, since: string, until: string, current: record<limit_seconds: float, period_usage_seconds: float, remaining_seconds: float, utilization_percent: any, period_start: string, resets_at: string, as_of: string>, total_used_seconds: float, total_run_count: int, group_by: any, buckets: table<start: string, used_seconds: float, run_count: int, latest_total_usage_seconds: any, latest_limit_seconds: any, latest_remaining_seconds: any, groups: any>, groups: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "max_groups" $max_groups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/managed_execution/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Workspace Rate Limit Allocations
#
# GET /api/accounts/{account_id}/rate-limit-allocations/
# operationId: read_workspace_rate_limit_allocations_api_accounts__account_id__rate_limit_allocations__get
export def "accounts-rate-limit-allocations get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, created: any, updated: any, account_id: string, workspace_id: string, rate_limit_percentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limit-allocations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert Workspace Rate Limit Allocations
#
# PUT /api/accounts/{account_id}/rate-limit-allocations/
# operationId: upsert_workspace_rate_limit_allocations_api_accounts__account_id__rate_limit_allocations__put
# --allocations item shape: {workspace_id: string, rate_limit_percentage: float}
export def "accounts-rate-limit-allocations put" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allocations: list # List of workspace allocations. Workspaces not in this list will have their allocations removed. — item shape: {workspace_id: string, rate_limit_percentage: float}
]: any -> table<id: string, created: any, updated: any, account_id: string, workspace_id: string, rate_limit_percentage: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/rate-limit-allocations/")
  let body = {allocations: $allocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Workspace Invitation
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/invitations/
# operationId: create_workspace_invitation_api_accounts__account_id__workspaces__workspace_id__invitations__post
export def "accounts-workspaces-invitations post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email of the user to invite (format: email)
]: any -> record<id: string, created: any, updated: any, email: string, account_id: string, account_role_id: string, workspace_id: string, workspace_role_id: string, status: string, expiration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/invitations/")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace Invitation
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/invitations/{id}
# operationId: read_workspace_invitation_api_accounts__account_id__workspaces__workspace_id__invitations__id__get
export def "accounts-workspaces-invitations get" [
  account_id: string
  id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, email: string, account_id: string, account_role_id: string, workspace_id: string, workspace_role_id: string, status: string, expiration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/invitations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Workspace Invitations
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/invitations/filter
# operationId: read_workspace_invitations_api_accounts__account_id__workspaces__workspace_id__invitations_filter_post
export def "accounts-workspaces-invitations-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workspace-invitations: any
  --limit: int # default: 200
  --offset: int # default: 0
]: any -> table<id: string, created: any, updated: any, email: string, account_id: string, account_role_id: string, workspace_id: string, workspace_role_id: string, status: string, expiration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/invitations/filter")
  let body = {workspace_invitations: $workspace_invitations, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke Workspace Invitation
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/invitations/{id}/revoke
# operationId: revoke_workspace_invitation_api_accounts__account_id__workspaces__workspace_id__invitations__id__revoke_post
export def "accounts-workspaces-invitations-revoke post" [
  account_id: string
  id: string
  workspace_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/invitations/($id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert Workspace User Access
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/user_access/
# operationId: upsert_workspace_user_access_api_accounts__account_id__workspaces__workspace_id__user_access__post
export def "accounts-workspaces-user-access post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # id of user to create a workspace access for (format: uuid)
  --workspace-role-id: string # The workspace role id (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/user_access/")
  let body = {user_id: $user_id, workspace_role_id: $workspace_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace User Accesses
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/user_access/filter
# operationId: read_workspace_user_accesses_api_accounts__account_id__workspaces__workspace_id__user_access_filter_post
export def "accounts-workspaces-user-access-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --offset: int # default: 0
  --workspace-accesses: any
  --users: any
  --body-sort: any
]: any -> table<id: string, created: any, updated: any, workspace_id: string, workspace_role_id: string, actor_id: string, user_id: string, first_name: string, last_name: string, email: string, handle: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/user_access/filter")
  let body = {limit: $limit, offset: $offset, workspace_accesses: $workspace_accesses, users: $users, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace User Access
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/user_access/{id}
# operationId: read_workspace_user_access_api_accounts__account_id__workspaces__workspace_id__user_access__id__get
export def "accounts-workspaces-user-access get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, workspace_id: string, workspace_role_id: string, actor_id: string, user_id: string, first_name: string, last_name: string, email: string, handle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/user_access/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Workspace User Access
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/user_access/{id}
# operationId: delete_workspace_user_access_api_accounts__account_id__workspaces__workspace_id__user_access__id__delete
export def "accounts-workspaces-user-access delete" [
  account_id: string
  id: string
  workspace_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/user_access/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert Workspace Bot Access
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/bot_access/
# operationId: upsert_workspace_bot_access_api_accounts__account_id__workspaces__workspace_id__bot_access__post
export def "accounts-workspaces-bot-access post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bot-id: string # id of bot to create a workspace access for (format: uuid)
  --workspace-role-id: string # The workspace role id (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/bot_access/")
  let body = {bot_id: $bot_id, workspace_role_id: $workspace_role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace Bot Accesses
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/bot_access/filter
# operationId: read_workspace_bot_accesses_api_accounts__account_id__workspaces__workspace_id__bot_access_filter_post
export def "accounts-workspaces-bot-access-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --offset: int # default: 0
  --workspace-accesses: any
  --bots: any
  --body-sort: any
]: any -> table<id: string, created: any, updated: any, workspace_id: string, workspace_role_id: string, actor_id: string, bot_id: string, bot_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/bot_access/filter")
  let body = {limit: $limit, offset: $offset, workspace_accesses: $workspace_accesses, bots: $bots, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace Bot Access
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/bot_access/{id}
# operationId: read_workspace_bot_access_api_accounts__account_id__workspaces__workspace_id__bot_access__id__get
export def "accounts-workspaces-bot-access get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, updated: any, workspace_id: string, workspace_role_id: string, actor_id: string, bot_id: string, bot_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/bot_access/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Workspace Bot Access
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/bot_access/{id}
# operationId: delete_workspace_bot_access_api_accounts__account_id__workspaces__workspace_id__bot_access__id__delete
export def "accounts-workspaces-bot-access delete" [
  id: string
  account_id: string
  workspace_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/bot_access/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert Workspace Team Access
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/team_access/
# operationId: upsert_workspace_team_access_api_accounts__account_id__workspaces__workspace_id__team_access__put
export def "accounts-workspaces-team-access put" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, created: any, updated: any, team_id: string, workspace_id: string, workspace_role_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/team_access/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace Team Accesses
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/team_access/filter
# operationId: read_workspace_team_accesses_api_accounts__account_id__workspaces__workspace_id__team_access_filter_post
export def "accounts-workspaces-team-access-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --offset: int # default: 0
]: any -> table<id: string, created: any, updated: any, workspace_id: string, workspace_role_id: string, team_id: string, team_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/team_access/filter")
  let body = {limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Workspace Team Access
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/team_access/{team_id}
# operationId: remove_workspace_team_access_api_accounts__account_id__workspaces__workspace_id__team_access__team_id__delete
export def "accounts-workspaces-team-access delete" [
  account_id: string
  workspace_id: string
  team_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/team_access/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Actor Access
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/access/
# operationId: read_actor_access_api_accounts__account_id__workspaces__workspace_id__access__get
export def "accounts-workspaces-access get" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: any, name: string, email: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/access/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read My Profile
#
# GET /api/me/
# operationId: read_my_profile_api_me__get
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, handle: string, first_name: string, last_name: string, email: string, location: any, personal_account_id: any, settings: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/me/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read My Sessions
#
# GET /api/me/sessions
# operationId: read_my_sessions_api_me_sessions_get
export def "me-sessions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, created: any, updated: any, user_id: string, ip_address: string, location: any, user_agent: any, expires_at: int, restricted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/me/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Filter My Sessions
#
# POST /api/me/sessions/filter
# operationId: filter_my_sessions_api_me_sessions_filter_post
export def "me-sessions-filter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: any
  --limit: int # default: 200
  --offset: int # default: 0
]: any -> table<id: string, created: any, updated: any, user_id: string, ip_address: string, location: any, user_agent: any, expires_at: int, restricted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/me/sessions/filter")
  let body = {filter: $filter, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Terminate My Session
#
# POST /api/me/sessions/{session_id}/terminate
# operationId: terminate_my_session_api_me_sessions__session_id__terminate_post
export def "me-sessions-terminate post" [
  session_id: string
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
  let full_url = (build-url $base $"/api/me/sessions/($session_id)/terminate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read My Api Keys
#
# GET /api/me/api_keys
# operationId: read_my_api_keys_api_me_api_keys_get
export def "me-api-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: nothing -> table<id: string, created: any, name: string, expiration: any, masked_key: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/me/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Filter My Api Keys
#
# POST /api/me/api_keys/filter
# operationId: filter_my_api_keys_api_me_api_keys_filter_post
export def "me-api-keys-filter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-keys: any
  --limit: int # default: 200
  --offset: int # default: 0
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/me/api_keys/filter")
  let body = {api_keys: $api_keys, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read My Accounts
#
# GET /api/me/accounts
# operationId: read_my_accounts_api_me_accounts_get
export def "me-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<account_membership_id: string, account_id: string, account_name: string, account_role_name: string, account_handle: string, account_plan_type: string, account_plan_tier: any, account_plan_features: list<string>, self_serve: bool, annual_billing: bool, annual_self_serve_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/me/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read My Organizations
#
# GET /api/me/organizations
# operationId: read_my_organizations_api_me_organizations_get
export def "me-organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<account_membership_id: string, account_id: string, account_name: string, account_role_name: string, account_handle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/me/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read My Account Permissions
#
# GET /api/me/accounts/{account_id}/permissions
# operationId: read_my_account_permissions_api_me_accounts__account_id__permissions_get
export def "me-accounts-permissions get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/me/accounts/($account_id)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read My Accounts With Permission
#
# GET /api/me/accounts/has_permission
# operationId: read_my_accounts_with_permission_api_me_accounts_has_permission_get
export def "me-accounts-has-permission list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string@permission-completer
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/me/accounts/has_permission" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check My Account Permissions
#
# GET /api/me/accounts/{account_id}/has_permission
# operationId: check_my_account_permissions_api_me_accounts__account_id__has_permission_get
export def "me-accounts-has-permission get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string@permission-completer
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/me/accounts/($account_id)/has_permission" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Leave Account
#
# DELETE /api/me/accounts/{account_id}
# operationId: leave_account_api_me_accounts__account_id__delete
export def "me-accounts delete" [
  account_id: string
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
  let full_url = (build-url $base $"/api/me/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read My Workspaces
#
# GET /api/me/workspaces
# operationId: read_my_workspaces_api_me_workspaces_get
export def "me-workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<account_id: string, account_name: string, account_handle: string, workspace_id: string, workspace_name: string, workspace_description: string, workspace_handle: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/me/workspaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read My Workspace Scopes
#
# GET /api/me/workspaces/{workspace_id}/scopes
# operationId: read_my_workspace_scopes_api_me_workspaces__workspace_id__scopes_get
export def "me-workspaces-scopes get" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/me/workspaces/($workspace_id)/scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check My Workspace Scopes
#
# GET /api/me/workspaces/{workspace_id}/has_scope
# operationId: check_my_workspace_scopes_api_me_workspaces__workspace_id__has_scope_get
export def "me-workspaces-has-scope get" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scope: string@scope-completer
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/me/workspaces/($workspace_id)/has_scope" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Leave Workspace
#
# DELETE /api/me/workspaces/{workspace_id}
# operationId: leave_workspace_api_me_workspaces__workspace_id__delete
export def "me-workspaces delete" [
  workspace_id: string
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
  let full_url = (build-url $base $"/api/me/workspaces/($workspace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload My Profile Image
#
# PUT /api/me/profile-image
# operationId: upload_my_profile_image_api_me_profile_image_put
export def "me-profile-image put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/me/profile-image")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete My Profile Image
#
# DELETE /api/me/profile-image
# operationId: delete_my_profile_image_api_me_profile_image_delete
export def "me-profile-image delete" [
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
  let full_url = (build-url $base "/api/me/profile-image")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset My Profile Image
#
# POST /api/me/profile-image/reset
# operationId: reset_my_profile_image_api_me_profile_image_reset_post
export def "me-profile-image-reset post" [
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
  let full_url = (build-url $base "/api/me/profile-image/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read User
#
# GET /api/users/{id}
# operationId: read_user_api_users__id__get
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<title: any, image_location: any, personal_account_id: any, settings: any, last_login: any, id: string, created: any, updated: any, handle: string, actor_id: string, idp_user_id: string, first_name: string, last_name: string, email: string, location: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User
#
# PATCH /api/users/{id}
# operationId: update_user_api_users__id__patch
export def "users patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --handle: any # A unique handle for the user, containing only lowercase letters, numbers, and dashes.
  --first-name: any # The first name of a user.
  --last-name: any # The last name of a user.
  --email: any # User email.
  --location: any # An optional physical location for a user, e.g. Washington, D.C.
  --title: any # An optional title for the user.
  --image-location: any # A url linking to an image for the user.
  --settings: any # The user's default color settings (default: {tutorial_completed: false, feature_previews: []})
  --last-login: any # The last time the user logged in.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)")
  let body = {handle: $handle, first_name: $first_name, last_name: $last_name, email: $email, location: $location, title: $title, image_location: $image_location, settings: $settings, last_login: $last_login} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User
#
# DELETE /api/users/{id}
# operationId: delete_user_api_users__id__delete
export def "users delete" [
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
  let full_url = (build-url $base $"/api/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User Api Key
#
# POST /api/users/{id}/api_keys
# operationId: create_user_api_key_api_users__id__api_keys_post
export def "users-api-keys post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the api key.
  --expiration: any # The time at which the api key expires. If `None`, the api key will not expire.
]: any -> record<id: string, created: any, name: string, expiration: any, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/api_keys")
  let body = {name: $name, expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read User Api Keys
#
# GET /api/users/{id}/api_keys
# operationId: read_user_api_keys_api_users__id__api_keys_get
export def "users-api-keys list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: nothing -> table<id: string, created: any, name: string, expiration: any, masked_key: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read User Api Key
#
# GET /api/users/{id}/api_keys/{api_key_id}
# operationId: read_user_api_key_api_users__id__api_keys__api_key_id__get
export def "users-api-keys get" [
  id: string
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: any, name: string, expiration: any, masked_key: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/api_keys/($api_key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Api Key
#
# DELETE /api/users/{id}/api_keys/{api_key_id}
# operationId: delete_user_api_key_api_users__id__api_keys__api_key_id__delete
export def "users-api-keys delete" [
  id: string
  api_key_id: string
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
  let full_url = (build-url $base $"/api/users/($id)/api_keys/($api_key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Billing Details
#
# GET /api/billing/{account_id}/details
# operationId: get_billing_details_api_billing__account_id__details_get
export def "billing-details get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stripe_customer_id: any, self_serve: bool, has_payment_method: bool, plan_type: string, plan_tier: any, users: record<free_slots: int, minimum_slots: int, used_slots: int, slots: any, price: any>, workspaces: record<free_slots: int, minimum_slots: int, used_slots: int, slots: any, price: any>, annual_billing: bool, cancel_at_period_end: bool, trial_start: any, trial_end: any, billing_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billing/($account_id)/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Subscription Restrictions
#
# GET /api/billing/{account_id}/subscription_restrictions
# operationId: get_subscription_restrictions_api_billing__account_id__subscription_restrictions_get
export def "billing-subscription-restrictions get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<can_upgrade: bool, can_cancel: bool, available_tiers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billing/($account_id)/subscription_restrictions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Org Subscription At Period End
#
# POST /api/billing/{account_id}/cancel_org_subscription
# operationId: cancel_org_subscription_at_period_end_api_billing__account_id__cancel_org_subscription_post
export def "billing-cancel-org-subscription post" [
  account_id: string
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
  let full_url = (build-url $base $"/api/billing/($account_id)/cancel_org_subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Slots
#
# POST /api/billing/{account_id}/update_slots
# operationId: update_slots_api_billing__account_id__update_slots_post
export def "billing-update-slots post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additional-workspace-slots: any # The number of additional workspace slots to update to.
  --additional-user-slots: any # The number of additional user slots to update to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billing/($account_id)/update_slots")
  let body = {additional_workspace_slots: $additional_workspace_slots, additional_user_slots: $additional_user_slots} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Billing Portal Session
#
# POST /api/billing/{account_id}/create_billing_portal_session
# operationId: create_billing_portal_session_api_billing__account_id__create_billing_portal_session_post
export def "billing-create-billing-portal-session post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  return_url: string # The url to return to after leaving the billing portal.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billing/($account_id)/create_billing_portal_session")
  let body = {return_url: $return_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate Subscription Status
#
# POST /api/billing/{account_id}/validate_subscription_status
# operationId: validate_subscription_status_api_billing__account_id__validate_subscription_status_post
export def "billing-validate-subscription-status post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  stripe_session_id: string # The id of the stripe session to validate.
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billing/($account_id)/validate_subscription_status")
  let body = {stripe_session_id: $stripe_session_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Checkout Link
#
# POST /api/billing/{account_id}/subscribe
# operationId: get_checkout_link_api_billing__account_id__subscribe_post
export def "billing-subscribe post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tier: string@tier-completer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billing/($account_id)/subscribe")
  let body = {tier: $tier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manage Subscription
#
# POST /api/billing/{account_id}/manage_subscription
# operationId: manage_subscription_api_billing__account_id__manage_subscription_post
export def "billing-manage-subscription post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  return_url: string # The URL to return to after managing the subscription.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/billing/($account_id)/manage_subscription")
  let body = {return_url: $return_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read View Content
#
# GET /api/collections/views/{view}
# operationId: read_view_content_api_collections_views__view__get
export def "collections-views get" [
  view: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/collections/views/($view)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept Invitation
#
# POST /api/invitations/{id}/accept
# operationId: accept_invitation_api_invitations__id__accept_post
export def "invitations-accept post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invite-code: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "invite_code" $invite_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/invitations/($id)/accept" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reject Invitation
#
# POST /api/invitations/{id}/reject
# operationId: reject_invitation_api_invitations__id__reject_post
export def "invitations-reject post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invite-code: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "invite_code" $invite_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/invitations/($id)/reject" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Account Events
#
# POST /api/accounts/{account_id}/events
# operationId: create_account_events_api_accounts__account_id__events_post
export def "accounts-events post" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/events")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Account Events
#
# POST /api/accounts/{account_id}/events/filter
# operationId: read_account_events_api_accounts__account_id__events_filter_post
export def "accounts-events-filter post" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of events to return with each page (default: 50)
  --filter: any # Additional optional filter criteria to narrow down the set of Events
]: any -> record<events: table<occurred: string, event: string, resource: record, related: list, payload: record, id: string, follows: any, account: string, workspace: any, received: string>, total: int, next_page: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/events/filter")
  let body = {limit: $limit, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Account Events Page
#
# GET /api/accounts/{account_id}/events/filter/next
# operationId: read_account_events_page_api_accounts__account_id__events_filter_next_get
export def "accounts-events-filter-next get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string
]: nothing -> record<events: table<occurred: string, event: string, resource: record, related: list, payload: record, id: string, follows: any, account: string, workspace: any, received: string>, total: int, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page-token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/events/filter/next" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Account Events
#
# POST /api/accounts/{account_id}/events/count-by/{countable}
# operationId: count_account_events_api_accounts__account_id__events_count_by__countable__post
export def "accounts-events-count-by post" [
  countable: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time-unit: string@time-unit-completer
  --time-interval: float # default: 1.0
  --filter: any # Additional optional filter criteria to narrow down the set of Events
]: any -> table<value: string, label: string, count: int, start_time: string, end_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/events/count-by/($countable)")
  let body = {time_unit: $time_unit, time_interval: $time_interval, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Workspace Events
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/events
# operationId: create_workspace_events_api_accounts__account_id__workspaces__workspace_id__events_post
export def "accounts-workspaces-events post" [
  account_id: string
  workspace_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/events")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace Events
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/events/filter
# operationId: read_workspace_events_api_accounts__account_id__workspaces__workspace_id__events_filter_post
export def "accounts-workspaces-events-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of events to return with each page (default: 50)
  --filter: any # Additional optional filter criteria to narrow down the set of Events
]: any -> record<events: table<occurred: string, event: string, resource: record, related: list, payload: record, id: string, follows: any, account: string, workspace: any, received: string>, total: int, next_page: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/events/filter")
  let body = {limit: $limit, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workspace Events Page
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/events/filter/next
# operationId: read_workspace_events_page_api_accounts__account_id__workspaces__workspace_id__events_filter_next_get
export def "accounts-workspaces-events-filter-next get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string
]: nothing -> record<events: table<occurred: string, event: string, resource: record, related: list, payload: record, id: string, follows: any, account: string, workspace: any, received: string>, total: int, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page-token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/events/filter/next" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Workspace Events
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/events/count-by/{countable}
# operationId: count_workspace_events_api_accounts__account_id__workspaces__workspace_id__events_count_by__countable__post
export def "accounts-workspaces-events-count-by post" [
  countable: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time-unit: string@time-unit-completer
  --time-interval: float # default: 1.0
  --filter: any # Additional optional filter criteria to narrow down the set of Events
]: any -> table<value: string, label: string, count: int, start_time: string, end_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/events/count-by/($countable)")
  let body = {time_unit: $time_unit, time_interval: $time_interval, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Events For Flow Run
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{flow_run_id}/events
# operationId: get_events_for_flow_run_api_accounts__account_id__workspaces__workspace_id__flow_runs__flow_run_id__events_get
export def "accounts-workspaces-flow-runs-events get" [
  flow_run_id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # default: 0
  --order: string@order-completer
  --with-task-runs: string@bool-completer # default: true
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
  --if-none-match: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "with_task_runs" $with_task_runs "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($flow_run_id)/events" $qp)
  let extra_headers = {"if-none-match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Resources Hierarchy
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/resources/hierarchy/filter
# operationId: read_resources_hierarchy_api_accounts__account_id__workspaces__workspace_id__resources_hierarchy_filter_post
export def "accounts-workspaces-resources-hierarchy-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  depth: int # The depth of the hierarchy to return
  --limit: int # The number of events to return with each page (default: 50)
  --filter: any # Additional optional filter criteria to narrow down the set of Resources
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/hierarchy/filter")
  let body = {depth: $depth, limit: $limit, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Filter Workspace Resources
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/resources/filter
# operationId: filter_workspace_resources_api_accounts__account_id__workspaces__workspace_id__resources_filter_post
export def "accounts-workspaces-resources-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of events to return with each page (default: 50)
  --filter: any # Additional optional filter criteria to narrow down the set of Resources
]: any -> record<resources: list<record>, total: int, next_page: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/filter")
  let body = {limit: $limit, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Resources Page
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/resources/filter/next
# operationId: read_resources_page_api_accounts__account_id__workspaces__workspace_id__resources_filter_next_get
export def "accounts-workspaces-resources-filter-next get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string
]: nothing -> record<resources: list<record>, total: int, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page-token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/filter/next" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Filtered Resources Count
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/resources/filter/count
# operationId: get_filtered_resources_count_api_accounts__account_id__workspaces__workspace_id__resources_filter_count_post
export def "accounts-workspaces-resources-filter-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of events to return with each page (default: 50)
  --filter: any # Additional optional filter criteria to narrow down the set of Resources
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/filter/count")
  let body = {limit: $limit, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Filter Related Workspace Resources
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/resources/related
# operationId: filter_related_workspace_resources_api_accounts__account_id__workspaces__workspace_id__resources_related_post
# --filter shape: {id?: any, id_prefix?: any, labels?: any, exclude_id?: any, exclude_id_prefix?: any, occurred?: record, limit?: any, offset?: any, order?: "ASC"|"DESC", scope?: record, group_level?: any, direction?: "downstream"|"upstream", related_role?: any, exclude_related_role?: any}
export def "accounts-workspaces-resources-related post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of events to return with each page (default: 50)
  --filter: record # shape: {id?: any, id_prefix?: any, labels?: any, exclude_id?: any, exclude_id_prefix?: any, occurred?: record, limit?: any, offset?: any, order?: "ASC"|"DESC", scope?: record, group_level?: any, direction?: "downstream"|"upstream", related_role?: any, exclude_related_role?: any}
]: any -> record<resources: table<direction: string, resources: list>, total: int, next_page: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/related")
  let body = {limit: $limit, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Related Resources Page
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/resources/related/next
# operationId: read_related_resources_page_api_accounts__account_id__workspaces__workspace_id__resources_related_next_get
export def "accounts-workspaces-resources-related-next get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string
]: nothing -> record<resources: table<direction: string, resources: list>, total: int, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page-token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/related/next" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Related Resources Count
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/resources/related/count
# operationId: get_related_resources_count_api_accounts__account_id__workspaces__workspace_id__resources_related_count_post
# --filter shape: {id?: any, id_prefix?: any, labels?: any, exclude_id?: any, exclude_id_prefix?: any, occurred?: record, limit?: any, offset?: any, order?: "ASC"|"DESC", scope?: record, group_level?: any, direction?: "downstream"|"upstream", related_role?: any, exclude_related_role?: any}
export def "accounts-workspaces-resources-related-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record # shape: {id?: any, id_prefix?: any, labels?: any, exclude_id?: any, exclude_id_prefix?: any, occurred?: record, limit?: any, offset?: any, order?: "ASC"|"DESC", scope?: record, group_level?: any, direction?: "downstream"|"upstream", related_role?: any, exclude_related_role?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/related/count")
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Hidden Resources
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/resources/hidden-resources
# operationId: get_hidden_resources_api_accounts__account_id__workspaces__workspace_id__resources_hidden_resources_get
export def "accounts-workspaces-resources-hidden-resources get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<paths: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/hidden-resources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Hide Resource Path
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/resources/hidden-resources/add
# operationId: hide_resource_path_api_accounts__account_id__workspaces__workspace_id__resources_hidden_resources_add_post
export def "accounts-workspaces-resources-hidden-resources-add post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  paths: list # The paths of the resources to exclude
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/hidden-resources/add")
  let body = {paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Resource Exclusion
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/resources/hidden-resources/delete
# operationId: remove_resource_exclusion_api_accounts__account_id__workspaces__workspace_id__resources_hidden_resources_delete_post
export def "accounts-workspaces-resources-hidden-resources-delete post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  paths: list # The paths of the resources to exclude
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/resources/hidden-resources/delete")
  let body = {paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Automation
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/automations/
# operationId: create_automation_api_accounts__account_id__workspaces__workspace_id__automations__post
export def "accounts-workspaces-automations post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of this automation
  --description: string # A longer description of this automation (default: )
  --enabled: string@bool-completer # Whether this automation will be evaluated (default: true)
  trigger: any # The criteria for which events this Automation covers and how it will respond to the presence or absence of those events
  actions: list # The actions to perform when this Automation triggers
  --actions-on-trigger: list # The actions to perform when an Automation goes into a triggered state
  --actions-on-resolve: list # The actions to perform when an Automation goes into a resolving state
  --labels: any # Labels to apply to this automation
  --tags: list # A list of tags for the automation
  --owner-resource: any # The resource to which this automation belongs
]: any -> record<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/")
  let body = {name: $name, description: $description, enabled: $enabled, trigger: $trigger, actions: $actions, actions_on_trigger: $actions_on_trigger, actions_on_resolve: $actions_on_resolve, labels: $labels, tags: $tags, owner_resource: $owner_resource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Automation
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/automations/{id}
# operationId: update_automation_api_accounts__account_id__workspaces__workspace_id__automations__id__put
export def "accounts-workspaces-automations put" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of this automation
  --description: string # A longer description of this automation (default: )
  --enabled: string@bool-completer # Whether this automation will be evaluated (default: true)
  trigger: any # The criteria for which events this Automation covers and how it will respond to the presence or absence of those events
  actions: list # The actions to perform when this Automation triggers
  --actions-on-trigger: list # The actions to perform when an Automation goes into a triggered state
  --actions-on-resolve: list # The actions to perform when an Automation goes into a resolving state
  --labels: any # Labels to apply to this automation
  --tags: list # A list of tags for the automation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/($id)")
  let body = {name: $name, description: $description, enabled: $enabled, trigger: $trigger, actions: $actions, actions_on_trigger: $actions_on_trigger, actions_on_resolve: $actions_on_resolve, labels: $labels, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch Automation
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/automations/{id}
# operationId: patch_automation_api_accounts__account_id__workspaces__workspace_id__automations__id__patch
export def "accounts-workspaces-automations patch" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether this automation will be evaluated (default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/($id)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Automation
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/automations/{id}
# operationId: delete_automation_api_accounts__account_id__workspaces__workspace_id__automations__id__delete
export def "accounts-workspaces-automations delete" [
  workspace_id: string
  id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Automation
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/automations/{id}
# operationId: read_automation_api_accounts__account_id__workspaces__workspace_id__automations__id__get
export def "accounts-workspaces-automations get" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Automations
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/automations/filter
# operationId: read_automations_api_accounts__account_id__workspaces__workspace_id__automations_filter_post
export def "accounts-workspaces-automations-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-sort: string@sort-completer # Defines automations sorting options.
  --offset: int # default: 0
  --automations: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/filter")
  let body = {sort: $body_sort, offset: $offset, automations: $automations, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Automations
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/automations/count
# operationId: count_automations_api_accounts__account_id__workspaces__workspace_id__automations_count_post
export def "accounts-workspaces-automations-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Automations Related To Resource
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/automations/related-to/{resource_id}
# operationId: read_automations_related_to_resource_api_accounts__account_id__workspaces__workspace_id__automations_related_to__resource_id__get
export def "accounts-workspaces-automations-related-to get" [
  account_id: string
  workspace_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/related-to/($resource_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Automations Owned By Resource
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/automations/owned-by/{resource_id}
# operationId: delete_automations_owned_by_resource_api_accounts__account_id__workspaces__workspace_id__automations_owned_by__resource_id__delete
export def "accounts-workspaces-automations-owned-by delete" [
  account_id: string
  workspace_id: string
  resource_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/owned-by/($resource_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Managed Automations
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/automations/managed/
# operationId: list_managed_automations_api_accounts__account_id__workspaces__workspace_id__automations_managed__get
export def "accounts-workspaces-automations-managed get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<type: string, settings: record, enabled: bool, automation: record<name: string, description: string, enabled: bool, trigger: any, actions: list, actions_on_trigger: list, actions_on_resolve: list, labels: any, tags: list, id: string, created: any, updated: any, account: string, workspace: any, actor: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/managed/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Or Update Managed Automation
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/automations/managed/{automation_type}
# operationId: create_or_update_managed_automation_api_accounts__account_id__workspaces__workspace_id__automations_managed__automation_type__put
export def "accounts-workspaces-automations-managed put" [
  account_id: string
  workspace_id: string
  automation_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # default: true
  --settings: record
]: any -> record<type: string, settings: record, enabled: bool, automation: record<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, id: string, created: any, updated: any, account: string, workspace: any, actor: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/managed/($automation_type)")
  let body = {enabled: $enabled, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Managed Automation
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/automations/managed/{automation_type}
# operationId: delete_managed_automation_api_accounts__account_id__workspaces__workspace_id__automations_managed__automation_type__delete
export def "accounts-workspaces-automations-managed delete" [
  account_id: string
  workspace_id: string
  automation_type: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/managed/($automation_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Managed Automation Types
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/automations/managed/types
# operationId: list_managed_automation_types_api_accounts__account_id__workspaces__workspace_id__automations_managed_types_get
export def "accounts-workspaces-automations-managed-types get" [
  workspace_id: string
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<type: string, name: string, description: string, defaults: record, settings_schema: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/managed/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Managed Automations By Workspace
#
# GET /api/accounts/{account_id}/managed-automations/
# operationId: list_managed_automations_by_workspace_api_accounts__account_id__managed_automations__get
export def "accounts-managed-automations get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<workspace_id: string, workspace_name: string, workspace_handle: string, automations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/managed-automations/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete All Managed Automations
#
# DELETE /api/accounts/{account_id}/managed-automations
# operationId: delete_all_managed_automations_api_accounts__account_id__managed_automations_delete
export def "accounts-managed-automations delete" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/managed-automations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Quick Enable Managed Automations
#
# POST /api/accounts/{account_id}/managed-automations/quick-enable
# operationId: quick_enable_managed_automations_api_accounts__account_id__managed_automations_quick_enable_post
export def "accounts-managed-automations-quick-enable post" [
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/managed-automations/quick-enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Sla
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/slas/
# operationId: create_sla_api_accounts__account_id__workspaces__workspace_id__slas__post
export def "accounts-workspaces-slas post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of this SLA
  --severity: string@severity-completer # The severity of a SLA violation
  --enabled: any # Whether this SLA will be evaluated
  --owner-resource: any # The resource that owns this SLA
  --duration: int # The maximum flow run duration in seconds allowed before the SLA is violated.
  --stale-after: float # The amount of time after a flow run is considered stale.
  --within: float # The amount of time after a flow run is considered stale.
  --resource-match: record # The resource to match for this SLA
  --expected-event: string # The event that is expected to occur within the specified time window.
]: any -> record<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, severity: string, type: string, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/")
  let body = {name: $name, severity: $severity, enabled: $enabled, owner_resource: $owner_resource, duration: $duration, stale_after: $stale_after, within: $within, resource_match: $resource_match, expected_event: $expected_event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Apply Slas
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/slas/apply-resource-slas/{resource_id}
# operationId: apply_slas_api_accounts__account_id__workspaces__workspace_id__slas_apply_resource_slas__resource_id__post
export def "accounts-workspaces-slas-apply-resource-slas post" [
  workspace_id: string
  resource_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/apply-resource-slas/($resource_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Slas
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/slas/filter
# operationId: read_slas_api_accounts__account_id__workspaces__workspace_id__slas_filter_post
export def "accounts-workspaces-slas-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer
  --offset: int # default: 0
  --filter: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, severity: string, type: string, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/filter" $qp)
  let body = {offset: $offset, filter: $filter, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Slas By Owner Resource
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/slas/by-owner/{owner_resource}
# operationId: read_slas_by_owner_resource_api_accounts__account_id__workspaces__workspace_id__slas_by_owner__owner_resource__post
export def "accounts-workspaces-slas-by-owner post" [
  account_id: string
  workspace_id: string
  owner_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer
  --offset: int # default: 0
  --filter: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, severity: string, type: string, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/by-owner/($owner_resource)" $qp)
  let body = {offset: $offset, filter: $filter, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Sla
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/slas/{sla_id}
# operationId: read_sla_api_accounts__account_id__workspaces__workspace_id__slas__sla_id__get
export def "accounts-workspaces-slas get" [
  account_id: string
  workspace_id: string
  sla_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, severity: string, type: string, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/($sla_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Sla
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/slas/{sla_id}
# operationId: update_sla_api_accounts__account_id__workspaces__workspace_id__slas__sla_id__patch
export def "accounts-workspaces-slas patch" [
  workspace_id: string
  sla_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether this SLA will be evaluated
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/($sla_id)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Sla
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/slas/{sla_id}
# operationId: delete_sla_api_accounts__account_id__workspaces__workspace_id__slas__sla_id__delete
export def "accounts-workspaces-slas delete" [
  workspace_id: string
  sla_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/($sla_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Flow Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/slas/flow-runs
# operationId: read_flow_runs_api_accounts__account_id__workspaces__workspace_id__slas_flow_runs_post
export def "accounts-workspaces-slas-flow-runs post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sla_ids: list
  since: string # format: date-time
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/flow-runs")
  let body = {sla_ids: $sla_ids, since: $since} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Default Sla
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/slas/default
# operationId: create_default_sla_api_accounts__account_id__workspaces__workspace_id__slas_default_post
export def "accounts-workspaces-slas-default post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sla_severities: list
  block_id: string # format: uuid
]: any -> table<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/default")
  let body = {sla_severities: $sla_severities, block_id: $block_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Default Sla List
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/slas/default/list
# operationId: read_default_sla_list_api_accounts__account_id__workspaces__workspace_id__slas_default_list_get
export def "accounts-workspaces-slas-default-list get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/default/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Default Sla
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/slas/default/{sla_severity}
# operationId: read_default_sla_api_accounts__account_id__workspaces__workspace_id__slas_default__sla_severity__get
export def "accounts-workspaces-slas-default get" [
  sla_severity: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, enabled: bool, trigger: any, actions: list<any>, actions_on_trigger: list<any>, actions_on_resolve: list<any>, labels: any, tags: list<string>, id: string, created: any, updated: any, account: string, workspace: any, actor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/default/($sla_severity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Default Sla
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/slas/default/{sla_severity}
# operationId: delete_default_sla_api_accounts__account_id__workspaces__workspace_id__slas_default__sla_severity__delete
export def "accounts-workspaces-slas-default delete" [
  sla_severity: string
  workspace_id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/slas/default/($sla_severity)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Webhook
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/webhooks/
# operationId: create_webhook_api_accounts__account_id__workspaces__workspace_id__webhooks__post
export def "accounts-workspaces-webhooks post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the webhook
  --description: string # A longer description of the webhook (default: )
  --enabled: string@bool-completer # Whether the webhook is enabled (default: true)
  --service-account-id: any # The Service Account to which this webhook belongs
  template: string # The template which translates the incoming HTTP headers and body into a Prefect Event
]: any -> record<name: string, description: string, enabled: bool, service_account_id: any, template: string, id: string, created: any, updated: any, account: string, workspace: any, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/webhooks/")
  let body = {name: $name, description: $description, enabled: $enabled, service_account_id: $service_account_id, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Webhook
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/webhooks/{webhook_id}
# operationId: update_webhook_api_accounts__account_id__workspaces__workspace_id__webhooks__webhook_id__put
export def "accounts-workspaces-webhooks put" [
  account_id: string
  webhook_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the webhook
  --description: string # A longer description of the webhook (default: )
  --enabled: string@bool-completer # Whether the webhook is enabled (default: true)
  --service-account-id: any # The Service Account to which this webhook belongs
  template: string # The template which translates the incoming HTTP headers and body into a Prefect Event
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/webhooks/($webhook_id)")
  let body = {name: $name, description: $description, enabled: $enabled, service_account_id: $service_account_id, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partial Update Webhook
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/webhooks/{webhook_id}
# operationId: partial_update_webhook_api_accounts__account_id__workspaces__workspace_id__webhooks__webhook_id__patch
export def "accounts-workspaces-webhooks patch" [
  account_id: string
  webhook_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Whether the webhook is enabled (default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/webhooks/($webhook_id)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Webhook
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/webhooks/{webhook_id}
# operationId: delete_webhook_api_accounts__account_id__workspaces__workspace_id__webhooks__webhook_id__delete
export def "accounts-workspaces-webhooks delete" [
  webhook_id: string
  workspace_id: string
  account_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Webhook
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/webhooks/{webhook_id}
# operationId: read_webhook_api_accounts__account_id__workspaces__workspace_id__webhooks__webhook_id__get
export def "accounts-workspaces-webhooks get" [
  webhook_id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, enabled: bool, service_account_id: any, template: string, id: string, created: any, updated: any, account: string, workspace: any, slug: string, service_account: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Webhooks
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/webhooks/filter
# operationId: query_webhooks_api_accounts__account_id__workspaces__workspace_id__webhooks_filter_post
export def "accounts-workspaces-webhooks-filter post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-sort: string@sort-completer-1 # Defines webhook sorting options.
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<name: string, description: string, enabled: bool, service_account_id: any, template: string, id: string, created: any, updated: any, account: string, workspace: any, slug: string, service_account: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/webhooks/filter")
  let body = {sort: $body_sort, offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate Webhook Slug
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/webhooks/{webhook_id}/rotate
# operationId: rotate_webhook_slug_api_accounts__account_id__workspaces__workspace_id__webhooks__webhook_id__rotate_post
export def "accounts-workspaces-webhooks-rotate post" [
  webhook_id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, description: string, enabled: bool, service_account_id: any, template: string, id: string, created: any, updated: any, account: string, workspace: any, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/webhooks/($webhook_id)/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate Template
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/templates/validate
# operationId: validate_template_api_accounts__account_id__workspaces__workspace_id__templates_validate_post
export def "accounts-workspaces-templates-validate post" [
  account_id: any
  workspace_id: any
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/templates/validate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate Template
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/automations/templates/validate
# operationId: validate_template_api_accounts__account_id__workspaces__workspace_id__automations_templates_validate_post
export def "accounts-workspaces-automations-templates-validate post" [
  workspace_id: string
  account_id: any
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/automations/templates/validate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Prefect Metric Timeseries
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/metrics/prefect/{metric}/timeseries
# operationId: read_prefect_metric_timeseries_api_accounts__account_id__workspaces__workspace_id__ui_metrics_prefect__metric__timeseries_post
export def "accounts-workspaces-ui-metrics-prefect-timeseries post" [
  account_id: string
  workspace_id: string
  metric: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  after: string # The start of the time series (format: date-time)
  --before: string # The end of the time series, defaulting to now (format: date-time)
  --timezone: string # The timezone to use for the time series (default: Etc/UTC)
  --resource: record # A specification that may match zero, one, or many resources, used to target or select a set of resources in a query or automation.  A resource must match at least one value of all of the provided labels
  --related: any # Filter to only flow runs with a related resource matching these labels
  aggregates: list # The aggregate functions to apply.  The order they are specified here will determine the order of the returned data columns.
  resolution: int@resolution-completer # The resolution of the time series, in minutes
]: any -> record<metric: string, query: record<after: string, before: string, timezone: string, resource: record, related: any, aggregates: list<any>, resolution: int>, rollup: list<any>, series: list<list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/metrics/prefect/($metric)/timeseries")
  let body = {after: $after, before: $before, timezone: $timezone, resource: $resource, related: $related, aggregates: $aggregates, resolution: $resolution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Prefect Metric Timeseries
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/metrics/prefect/{metric}
# operationId: read_prefect_metric_timeseries_api_accounts__account_id__workspaces__workspace_id__ui_metrics_prefect__metric__post
export def "accounts-workspaces-ui-metrics-prefect post" [
  account_id: string
  workspace_id: string
  metric: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  after: string # The start of the time series (format: date-time)
  --before: string # The end of the time series, defaulting to now (format: date-time)
  --timezone: string # The timezone to use for the time series (default: Etc/UTC)
  --resource: record # A specification that may match zero, one, or many resources, used to target or select a set of resources in a query or automation.  A resource must match at least one value of all of the provided labels
  --related: any # Filter to only flow runs with a related resource matching these labels
  aggregates: list # The aggregate functions to apply.  The order they are specified here will determine the order of the returned data columns.
  resolution: int@resolution-completer # The resolution of the time series, in minutes
]: any -> record<metric: string, query: record<after: string, before: string, timezone: string, resource: record, related: any, aggregates: list<any>, resolution: int>, rollup: list<any>, series: list<list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/metrics/prefect/($metric)")
  let body = {after: $after, before: $before, timezone: $timezone, resource: $resource, related: $related, aggregates: $aggregates, resolution: $resolution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Prefect Metric Grouped
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/metrics/prefect/{metric}/grouped
# operationId: read_prefect_metric_grouped_api_accounts__account_id__workspaces__workspace_id__ui_metrics_prefect__metric__grouped_post
# --order_by item shape: {aggregate: int, direction?: "ASC"|"DESC"}
export def "accounts-workspaces-ui-metrics-prefect-grouped post" [
  account_id: string
  workspace_id: string
  metric: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  after: string # The start of the time series (format: date-time)
  --before: string # The end of the time series, defaulting to now (format: date-time)
  --timezone: string # The timezone to use for the time series (default: Etc/UTC)
  --resource: record # A specification that may match zero, one, or many resources, used to target or select a set of resources in a query or automation.  A resource must match at least one value of all of the provided labels
  --related: any # Filter to only flow runs with a related resource matching these labels
  aggregates: list # The aggregate functions to apply.  The order they are specified here will determine the order of the returned data columns.
  group_by: string@group-by-completer # The role of the related resource to group by.  There will be one result for each distinct related resource with that role in the time period, and optionally another null result for those that do not have the requested related resource.
  --order-by: list # The order to sort the groups by — item shape: {aggregate: int, direction?: "ASC"|"DESC"}
]: any -> record<metric: string, query: record<after: string, before: string, timezone: string, resource: record, related: any, aggregates: list<any>, group_by: string, order_by: list<record>>, results: list<list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/metrics/prefect/($metric)/grouped")
  let body = {after: $after, before: $before, timezone: $timezone, resource: $resource, related: $related, aggregates: $aggregates, group_by: $group_by, order_by: $order_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Tags
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/tags
# operationId: list_tags_api_accounts__account_id__workspaces__workspace_id__tags_get
export def "accounts-workspaces-tags get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # A string to search for in the tag names
  --page: int # The page number of tags to return. (default: 1)
  --qp-sort: string@sort-completer-2 # Sort tags by name (A→Z or Z→A) or recency (most/least recently seen first)
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: nothing -> record<results: table<name: string, first_seen: string, last_seen: string>, count: int, limit: int, pages: int, page: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Workspace Tag
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/tags
# operationId: delete_workspace_tag_api_accounts__account_id__workspaces__workspace_id__tags_delete
export def "accounts-workspaces-tags delete" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # The tag name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Assets
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/
# operationId: list_assets_api_accounts__account_id__workspaces__workspace_id__assets__get
export def "accounts-workspaces-assets get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prefix: string # Prefix to search assets keys for
  --search: string # Substring to search assets keys for
]: nothing -> table<key: string, properties: record<name: string, url: string, description: string, owners: list>, last_seen: string, latest_reference: record<event_id: any, occurred: any, flow_run_id: any, task_run_id: any, originating_workspace_id: any, metadata: record>, latest_materialization: record<event_id: any, occurred: any, flow_run_id: any, task_run_id: any, originating_workspace_id: any, metadata: record, by_tools: list, status: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefix" $prefix "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Asset
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/key
# operationId: read_asset_api_accounts__account_id__workspaces__workspace_id__assets_key_get
export def "accounts-workspaces-assets-key get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string
]: nothing -> record<key: string, properties: record<name: string, url: string, description: string, owners: list<string>>, last_seen: string, latest_reference: record<event_id: any, occurred: any, flow_run_id: any, task_run_id: any, originating_workspace_id: any, metadata: record>, latest_materialization: record<event_id: any, occurred: any, flow_run_id: any, task_run_id: any, originating_workspace_id: any, metadata: record, by_tools: list<string>, status: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/key" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Asset
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/assets/key
# operationId: delete_asset_api_accounts__account_id__workspaces__workspace_id__assets_key_delete
export def "accounts-workspaces-assets-key delete" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/key" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Latest Dependencies
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/latest-dependencies
# operationId: latest_dependencies_api_accounts__account_id__workspaces__workspace_id__assets_latest_dependencies_get
export def "accounts-workspaces-assets-latest-dependencies get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<upstream: string, downstream: string, occurred: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/latest-dependencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Asset Neighbors
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/neighbors
# operationId: get_asset_neighbors_api_accounts__account_id__workspaces__workspace_id__assets_neighbors_get
export def "accounts-workspaces-assets-neighbors get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # The asset key to get neighbors for
]: nothing -> record<assets: record, dependencies: table<upstream_asset_key: string, downstream_asset_key: string>, root_asset_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/neighbors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Filter Assets
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/assets/filter
# operationId: filter_assets_api_accounts__account_id__workspaces__workspace_id__assets_filter_post
export def "accounts-workspaces-assets-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of assets to return with each page (default: 50)
  --filter: any # Additional optional filter criteria to narrow down assets
]: any -> record<assets: table<key: string, properties: record, last_seen: string, latest_reference: record, latest_materialization: record>, dependencies: table<upstream: string, downstream: string, occurred: string, status: string>, total: int, next_page: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/filter")
  let body = {limit: $limit, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Filter Assets Page
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/filter/next
# operationId: filter_assets_page_api_accounts__account_id__workspaces__workspace_id__assets_filter_next_get
export def "accounts-workspaces-assets-filter-next get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-token: string
]: nothing -> record<assets: table<key: string, properties: record, last_seen: string, latest_reference: record, latest_materialization: record>, dependencies: table<upstream: string, downstream: string, occurred: string, status: string>, total: int, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page-token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/filter/next" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Asset Materializations
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/materializations
# operationId: list_asset_materializations_api_accounts__account_id__workspaces__workspace_id__assets_materializations_get
export def "accounts-workspaces-assets-materializations list" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # The asset key to get materializations for
  --since: string # Only return materializations on or after this timestamp
  --until: string # Only return materializations on or before this timestamp
  --qp-sort: string@sort-completer-3 # Sort order: 'asc' or 'desc' (default: desc)
]: nothing -> table<asset_key: string, occurred: string, status: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, upstream_assets: list<string>, by_tools: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/materializations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Asset References
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/references
# operationId: list_asset_references_api_accounts__account_id__workspaces__workspace_id__assets_references_get
export def "accounts-workspaces-assets-references list" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # The asset key to get references for
  --since: string # Only return references on or after this timestamp
  --until: string # Only return references on or before this timestamp
  --qp-sort: string@sort-completer-3 # Sort order: 'asc' or 'desc' (default: desc)
]: nothing -> table<asset_key: string, occurred: string, status: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, upstream_assets: list<string>, by_tools: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/references" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Asset Materialization
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/materializations/{event_id}
# operationId: read_asset_materialization_api_accounts__account_id__workspaces__workspace_id__assets_materializations__event_id__get
export def "accounts-workspaces-assets-materializations get" [
  account_id: string
  workspace_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # The asset key for validation
]: nothing -> record<asset_key: string, occurred: string, status: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, upstream_assets: list<string>, by_tools: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/materializations/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Upstream Materializations
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/materializations/{event_id}/upstream
# operationId: get_upstream_materializations_api_accounts__account_id__workspaces__workspace_id__assets_materializations__event_id__upstream_get
export def "accounts-workspaces-assets-materializations-upstream get" [
  account_id: string
  workspace_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # The asset key of the focal materialization
]: nothing -> table<asset_key: string, occurred: string, status: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, upstream_assets: list<string>, by_tools: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/materializations/($event_id)/upstream" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Asset Reference
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/assets/references/{event_id}
# operationId: read_asset_reference_api_accounts__account_id__workspaces__workspace_id__assets_references__event_id__get
export def "accounts-workspaces-assets-references get" [
  account_id: string
  workspace_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # The upstream asset key being referenced
]: nothing -> record<asset_key: string, occurred: string, status: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, upstream_assets: list<string>, by_tools: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/assets/references/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Available Assets Endpoint
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/available-assets/
# operationId: list_available_assets_endpoint_api_accounts__account_id__workspaces__workspace_id__available_assets__get
export def "accounts-workspaces-available-assets get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 50
  --cursor: string
]: nothing -> record<results: table<key: string, publication_id: string, publishing_workspace_id: string, publication_event: list, publication_enabled: bool, asset: any>, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/available-assets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Publication
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/event-publications/
# operationId: create_publication_api_accounts__account_id__workspaces__workspace_id__event_publications__post
export def "accounts-workspaces-event-publications post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event: list
  --resource: any
  --related: any
]: any -> record<id: string, account_id: string, workspace_id: string, enabled: bool, event: list<string>, resource: any, related: any, created: string, updated: string, subscriber_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-publications/")
  let body = {event: $event, resource: $resource, related: $related} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Publications
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/event-publications/
# operationId: list_publications_api_accounts__account_id__workspaces__workspace_id__event_publications__get
export def "accounts-workspaces-event-publications list" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resource-id: string
  --limit: int # default: 200
  --cursor: string
]: nothing -> record<results: table<id: string, account_id: string, workspace_id: string, enabled: bool, event: list, resource: any, related: any, created: string, updated: string, subscriber_count: int>, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-publications/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Publication
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/event-publications/{publication_id}
# operationId: read_publication_api_accounts__account_id__workspaces__workspace_id__event_publications__publication_id__get
export def "accounts-workspaces-event-publications get" [
  account_id: string
  workspace_id: string
  publication_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, account_id: string, workspace_id: string, enabled: bool, event: list<string>, resource: any, related: any, created: string, updated: string, subscriber_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-publications/($publication_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Publication
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/event-publications/{publication_id}
# operationId: update_publication_api_accounts__account_id__workspaces__workspace_id__event_publications__publication_id__patch
export def "accounts-workspaces-event-publications patch" [
  account_id: string
  workspace_id: string
  publication_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: any
  --event: any
  --resource: any
  --related: any
]: any -> record<id: string, account_id: string, workspace_id: string, enabled: bool, event: list<string>, resource: any, related: any, created: string, updated: string, subscriber_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-publications/($publication_id)")
  let body = {enabled: $enabled, event: $event, resource: $resource, related: $related} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Publication
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/event-publications/{publication_id}
# operationId: delete_publication_api_accounts__account_id__workspaces__workspace_id__event_publications__publication_id__delete
export def "accounts-workspaces-event-publications delete" [
  account_id: string
  workspace_id: string
  publication_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-publications/($publication_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Publication Subscribers
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/event-publications/{publication_id}/subscriptions
# operationId: list_publication_subscribers_api_accounts__account_id__workspaces__workspace_id__event_publications__publication_id__subscriptions_get
export def "accounts-workspaces-event-publications-subscriptions get" [
  account_id: string
  workspace_id: string
  publication_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 200
  --cursor: string
]: nothing -> record<results: table<workspace_id: string, subscription_id: string, enabled: bool>, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-publications/($publication_id)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Subscription
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/event-subscriptions/
# operationId: create_subscription_api_accounts__account_id__workspaces__workspace_id__event_subscriptions__post
export def "accounts-workspaces-event-subscriptions post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  publication_id: string # format: uuid
  event: list
  --resource: any
  --related: any
]: any -> record<id: string, account_id: string, workspace_id: string, publication_id: string, enabled: bool, event: list<string>, resource: any, related: any, created: string, updated: string, publication_enabled: any, publication_exists: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-subscriptions/")
  let body = {publication_id: $publication_id, event: $event, resource: $resource, related: $related} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Subscriptions
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/event-subscriptions/
# operationId: list_subscriptions_api_accounts__account_id__workspaces__workspace_id__event_subscriptions__get
export def "accounts-workspaces-event-subscriptions list" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resource-id: string
  --limit: int # default: 200
  --cursor: string
]: nothing -> record<results: table<id: string, account_id: string, workspace_id: string, publication_id: string, enabled: bool, event: list, resource: any, related: any, created: string, updated: string, publication_enabled: any, publication_exists: bool>, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-subscriptions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Subscription
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/event-subscriptions/{subscription_id}
# operationId: read_subscription_api_accounts__account_id__workspaces__workspace_id__event_subscriptions__subscription_id__get
export def "accounts-workspaces-event-subscriptions get" [
  account_id: string
  workspace_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, account_id: string, workspace_id: string, publication_id: string, enabled: bool, event: list<string>, resource: any, related: any, created: string, updated: string, publication_enabled: any, publication_exists: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-subscriptions/($subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Subscription
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/event-subscriptions/{subscription_id}
# operationId: update_subscription_api_accounts__account_id__workspaces__workspace_id__event_subscriptions__subscription_id__patch
export def "accounts-workspaces-event-subscriptions patch" [
  account_id: string
  workspace_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: any
  --event: any
  --resource: any
  --related: any
]: any -> record<id: string, account_id: string, workspace_id: string, publication_id: string, enabled: bool, event: list<string>, resource: any, related: any, created: string, updated: string, publication_enabled: any, publication_exists: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-subscriptions/($subscription_id)")
  let body = {enabled: $enabled, event: $event, resource: $resource, related: $related} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Subscription
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/event-subscriptions/{subscription_id}
# operationId: delete_subscription_api_accounts__account_id__workspaces__workspace_id__event_subscriptions__subscription_id__delete
export def "accounts-workspaces-event-subscriptions delete" [
  account_id: string
  workspace_id: string
  subscription_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/event-subscriptions/($subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Asset Publication
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/asset-publications/
# operationId: create_asset_publication_api_accounts__account_id__workspaces__workspace_id__asset_publications__post
export def "accounts-workspaces-asset-publications post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resource_ids: list
]: any -> record<id: string, account_id: string, workspace_id: string, enabled: bool, event: list<string>, resource: any, related: any, created: string, updated: string, subscriber_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/asset-publications/")
  let body = {resource_ids: $resource_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Asset Subscription
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/asset-subscriptions/
# operationId: create_asset_subscription_api_accounts__account_id__workspaces__workspace_id__asset_subscriptions__post
export def "accounts-workspaces-asset-subscriptions post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  publication_id: string # format: uuid
]: any -> record<id: string, account_id: string, workspace_id: string, publication_id: string, enabled: bool, event: list<string>, resource: any, related: any, created: string, updated: string, publication_enabled: any, publication_exists: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/asset-subscriptions/")
  let body = {publication_id: $publication_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Logs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/logs/
# operationId: create_logs_api_accounts__account_id__workspaces__workspace_id__logs__post
export def "accounts-workspaces-logs post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/logs/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Logs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/logs/filter
# operationId: read_logs_api_accounts__account_id__workspaces__workspace_id__logs_filter_post
export def "accounts-workspaces-logs-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --offset: int # default: 0
  --logs: any
  --body-sort: string@sort-completer-4 # Defines log sorting options.
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, level: int, message: string, timestamp: string, flow_run_id: any, task_run_id: any, worker_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/logs/filter")
  let body = {offset: $offset, logs: $logs, sort: $body_sort, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Summarize Flow Run Logs
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/logs/ai/flow_run_logs/{flow_run_id}
# operationId: summarize_flow_run_logs_api_accounts__account_id__workspaces__workspace_id__logs_ai_flow_run_logs__flow_run_id__get
export def "accounts-workspaces-logs-ai-flow-run-logs get" [
  account_id: string
  workspace_id: string
  flow_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: any, detail: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/logs/ai/flow_run_logs/($flow_run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flow Run Logs
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/logs
# operationId: get_flow_run_logs_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__logs_get
export def "accounts-workspaces-flow-runs-logs get" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --level-ge: string
  --level-le: string
  --offset: int # default: 0
  --qp-sort: string@sort-completer-4
  --since: string # Only include logs with a timestamp at or after this time
  --until: string # Only include logs with a timestamp at or before this time
  --task-runs: string # Comma-separated list of task run IDs to filter by
  --task-runs-is-null: string # If true, only include logs without a task run ID
  --loggers: string # Comma-separated list of logger names to filter by
  --text-query: string # Text search query string
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
  --if-none-match: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level_ge" $level_ge "scalar") (serialize-qp "level_le" $level_le "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "task_runs" $task_runs "scalar") (serialize-qp "task_runs_is_null" $task_runs_is_null "scalar") (serialize-qp "loggers" $loggers "scalar") (serialize-qp "text_query" $text_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/logs" $qp)
  let extra_headers = {"if-none-match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Flow Run Logs
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/download-logs-csv
# DEPRECATED
# operationId: download_flow_run_logs_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__download_logs_csv_get
@deprecated
export def "accounts-workspaces-flow-runs-download-logs-csv get" [
  account_id: string
  workspace_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/download-logs-csv")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Flow Run Logs
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/logs/download
# operationId: download_flow_run_logs_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__logs_download_get
export def "accounts-workspaces-flow-runs-logs-download get" [
  account_id: string
  workspace_id: string
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/logs/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Trace Observed Loggers
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/traces/{trace_id}/observed-loggers
# operationId: read_trace_observed_loggers_api_accounts__account_id__workspaces__workspace_id__traces__trace_id__observed_loggers_get
export def "accounts-workspaces-traces-observed-loggers get" [
  account_id: string
  workspace_id: string
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Prefix search query for logger names
  --order-by: string@order-by-completer # Order results by name (alphabetically) or recency (most recently seen first)
  --limit: int # Maximum number of results to return (default: 100)
]: nothing -> table<logger_name: string, count: int, first_seen: string, last_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/traces/($trace_id)/observed-loggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Workspace Observed Loggers
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/observed-loggers
# operationId: read_workspace_observed_loggers_api_accounts__account_id__workspaces__workspace_id__observed_loggers_get
export def "accounts-workspaces-observed-loggers get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Prefix search query for logger names
  --order-by: string@order-by-completer # Order results by name (alphabetically) or recency (most recently seen first)
  --limit: int # Maximum number of results to return (default: 200)
]: nothing -> table<logger_name: string, count: int, first_seen: string, last_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/observed-loggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Artifact
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/
# operationId: create_artifact_api_accounts__account_id__workspaces__workspace_id__artifacts__post
export def "accounts-workspaces-artifacts post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --key: any # An optional unique reference key for this artifact.
  --type: any # An identifier that describes the shape of the data field. e.g. 'result', 'table', 'markdown'
  --description: any # A markdown-enabled description of the artifact.
  --data: any # Data associated with the artifact, e.g. a result.; structure depends on the artifact type.
  --metadata: any # User-defined artifact metadata. Content must be string key and value pairs.
  --flow-run-id: any # The flow run associated with the artifact.
  --task-run-id: any # The task run associated with the artifact.
]: any -> record<id: string, created: any, updated: any, key: any, type: any, description: any, data: any, metadata_: any, flow_run_id: any, task_run_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/")
  let body = {key: $key, type: $type, description: $description, data: $data, metadata_: $metadata, flow_run_id: $flow_run_id, task_run_id: $task_run_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Artifact
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/{id}
# operationId: read_artifact_api_accounts__account_id__workspaces__workspace_id__artifacts__id__get
export def "accounts-workspaces-artifacts get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, key: any, type: any, description: any, data: any, metadata_: any, flow_run_id: any, task_run_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Artifact
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/{id}
# operationId: update_artifact_api_accounts__account_id__workspaces__workspace_id__artifacts__id__patch
export def "accounts-workspaces-artifacts patch" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --data: any
  --description: any
  --metadata: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/($id)")
  let body = {data: $data, description: $description, metadata_: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Artifact
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/{id}
# operationId: delete_artifact_api_accounts__account_id__workspaces__workspace_id__artifacts__id__delete
export def "accounts-workspaces-artifacts delete" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Latest Artifact
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/{key}/latest
# operationId: read_latest_artifact_api_accounts__account_id__workspaces__workspace_id__artifacts__key__latest_get
export def "accounts-workspaces-artifacts-latest get" [
  key: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, key: any, type: any, description: any, data: any, metadata_: any, flow_run_id: any, task_run_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/($key)/latest")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Artifacts
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/filter
# operationId: read_artifacts_api_accounts__account_id__workspaces__workspace_id__artifacts_filter_post
export def "accounts-workspaces-artifacts-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-5 # Defines artifact sorting options.
  --offset: int # default: 0
  --artifacts: any
  --flow-runs: any
  --task-runs: any
  --flows: any
  --deployments: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, key: any, type: any, description: any, data: any, metadata_: any, flow_run_id: any, task_run_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/filter")
  let body = {sort: $body_sort, offset: $offset, artifacts: $artifacts, flow_runs: $flow_runs, task_runs: $task_runs, flows: $flows, deployments: $deployments, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Latest Artifacts
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/latest/filter
# operationId: read_latest_artifacts_api_accounts__account_id__workspaces__workspace_id__artifacts_latest_filter_post
export def "accounts-workspaces-artifacts-latest-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-5 # Defines artifact collection sorting options.
  --offset: int # default: 0
  --artifacts: any
  --flow-runs: any
  --task-runs: any
  --flows: any
  --deployments: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, key: string, latest_id: string, type: any, description: any, data: any, metadata_: any, flow_run_id: any, task_run_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/latest/filter")
  let body = {sort: $body_sort, offset: $offset, artifacts: $artifacts, flow_runs: $flow_runs, task_runs: $task_runs, flows: $flows, deployments: $deployments, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Artifacts
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/count
# operationId: count_artifacts_api_accounts__account_id__workspaces__workspace_id__artifacts_count_post
export def "accounts-workspaces-artifacts-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --artifacts: any
  --flow-runs: any
  --task-runs: any
  --flows: any
  --deployments: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/count")
  let body = {artifacts: $artifacts, flow_runs: $flow_runs, task_runs: $task_runs, flows: $flows, deployments: $deployments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Latest Artifacts
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/artifacts/latest/count
# operationId: count_latest_artifacts_api_accounts__account_id__workspaces__workspace_id__artifacts_latest_count_post
export def "accounts-workspaces-artifacts-latest-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --artifacts: any
  --flow-runs: any
  --task-runs: any
  --flows: any
  --deployments: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/artifacts/latest/count")
  let body = {artifacts: $artifacts, flow_runs: $flow_runs, task_runs: $task_runs, flows: $flows, deployments: $deployments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Available Work Pool Types
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/collections/work_pool_types
# operationId: read_available_work_pool_types_api_accounts__account_id__workspaces__workspace_id__collections_work_pool_types_get
export def "accounts-workspaces-collections-work-pool-types get" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/collections/work_pool_types")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Flow
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flows/
# operationId: create_flow_api_accounts__account_id__workspaces__workspace_id__flows__post
export def "accounts-workspaces-flows post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  name: string # The name of the flow
  --tags: list # A list of flow tags
  --labels: any # A dictionary of key-value labels. Values can be strings, numbers, or booleans.
]: any -> record<id: string, created: any, updated: any, name: string, tags: list<string>, labels: any, created_by: any, updated_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/")
  let body = {name: $name, tags: $tags, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Flow
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/flows/{id}
# operationId: update_flow_api_accounts__account_id__workspaces__workspace_id__flows__id__patch
export def "accounts-workspaces-flows patch" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --tags: list # A list of flow tags
  --labels: any # A dictionary of key-value labels. Values can be strings, numbers, or booleans.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/($id)")
  let body = {tags: $tags, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flows/{id}
# operationId: read_flow_api_accounts__account_id__workspaces__workspace_id__flows__id__get
export def "accounts-workspaces-flows get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, tags: list<string>, labels: any, created_by: any, updated_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Flow
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/flows/{id}
# operationId: delete_flow_api_accounts__account_id__workspaces__workspace_id__flows__id__delete
export def "accounts-workspaces-flows delete" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Flows
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flows/count
# operationId: count_flows_api_accounts__account_id__workspaces__workspace_id__flows_count_post
export def "accounts-workspaces-flows-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/count")
  let body = {flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow By Name
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flows/name/{name}
# operationId: read_flow_by_name_api_accounts__account_id__workspaces__workspace_id__flows_name__name__get
export def "accounts-workspaces-flows-name get" [
  workspace_id: string
  name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, tags: list<string>, labels: any, created_by: any, updated_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/name/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Flows
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flows/filter
# operationId: read_flows_api_accounts__account_id__workspaces__workspace_id__flows_filter_post
export def "accounts-workspaces-flows-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --offset: int # default: 0
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --body-sort: string@sort-completer-6 # Defines flow sorting options.
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, tags: list<string>, labels: any, created_by: any, updated_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/filter")
  let body = {offset: $offset, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, sort: $body_sort, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete Flows
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flows/bulk_delete
# operationId: bulk_delete_flows_api_accounts__account_id__workspaces__workspace_id__flows_bulk_delete_post
# --flows shape: {operator?: "and_"|"or_", id?: any, deployment?: any, name?: any, tags?: any, created_by?: any, updated_by?: any}
export def "accounts-workspaces-flows-bulk-delete post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  flows: record # Filter for flows. Only flows matching all criteria will be returned. — shape: {operator?: "and_"|"or_", id?: any, deployment?: any, name?: any, tags?: any, created_by?: any, updated_by?: any}
  --limit: int # Maximum number of flows to delete (default: 50)
]: any -> record<deleted: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/bulk_delete")
  let body = {flows: $flows, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Paginate Flows
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flows/paginate
# operationId: paginate_flows_api_accounts__account_id__workspaces__workspace_id__flows_paginate_post
export def "accounts-workspaces-flows-paginate post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --page: int # default: 1
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --body-sort: string@sort-completer-6 # Defines flow sorting options.
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, name: string, tags: list, labels: any, created_by: any, updated_by: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flows/paginate")
  let body = {page: $page, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, sort: $body_sort, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Flow Run
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/
# operationId: create_flow_run_api_accounts__account_id__workspaces__workspace_id__flow_runs__post
# --empirical_policy shape: {max_retries?: int, retry_delay_seconds?: float, retries?: any, retry_delay?: any, pause_keys?: any, resuming?: any, retry_type?: any}
@deprecated --flag deployment-id
export def "accounts-workspaces-flow-runs post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --state: any # The state of the flow run to create
  --name: string # The name of the flow run. Defaults to a random slug if not specified.
  flow_id: string # The id of the flow being run. (format: uuid)
  --flow-version: any # The version of the flow being run.
  --parameters: record
  --context: record # The context of the flow run.
  --parent-task-run-id: any
  --infrastructure-document-id: any
  --empirical-policy: record # Defines of how a flow run should retry. — shape: {max_retries?: int, retry_delay_seconds?: float, retries?: any, retry_delay?: any, pause_keys?: any, resuming?: any, retry_type?: any}
  --tags: list # A list of tags for the flow run.
  --labels: any # A dictionary of key-value labels. Values can be strings, numbers, or booleans.
  --idempotency-key: any # An optional idempotency key. If a flow run with the same idempotency key has already been created, the existing flow run will be returned.
  --work-pool-name: any # The name of the work pool to run the flow run in.
  --work-queue-name: any # The name of the work queue to place the flow run in.
  --job-variables: any # The job variables to use when setting up flow run infrastructure.
  --deployment-id: any # DEPRECATED: The id of the deployment associated with this flow run, if available. (DEPRECATED)
]: any -> record<id: string, created: any, updated: any, name: string, flow_id: string, flow_name: any, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_id: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, pause_keys: any, resuming: any, retry_type: any>, tags: list<string>, labels: any, parent_task_run_id: any, state_type: any, state_name: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, work_pool_id: any, work_pool_name: any, state: any, job_variables: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/")
  let body = {state: $state, name: $name, flow_id: $flow_id, flow_version: $flow_version, parameters: $parameters, context: $context, parent_task_run_id: $parent_task_run_id, infrastructure_document_id: $infrastructure_document_id, empirical_policy: $empirical_policy, tags: $tags, labels: $labels, idempotency_key: $idempotency_key, work_pool_name: $work_pool_name, work_queue_name: $work_queue_name, job_variables: $job_variables, deployment_id: $deployment_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/filter
# operationId: read_flow_runs_api_accounts__account_id__workspaces__workspace_id__flow_runs_filter_post
export def "accounts-workspaces-flow-runs-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-7 # Defines flow run sorting options.
  --offset: int # default: 0
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, flow_id: string, flow_name: any, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_id: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, pause_keys: any, resuming: any, retry_type: any>, tags: list<string>, labels: any, parent_task_run_id: any, state_type: any, state_name: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, work_pool_id: any, work_pool_name: any, state: any, job_variables: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/filter")
  let body = {sort: $body_sort, offset: $offset, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow Runs Minimal
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/filter-minimal
# operationId: read_flow_runs_minimal_api_accounts__account_id__workspaces__workspace_id__flow_runs_filter_minimal_post
export def "accounts-workspaces-flow-runs-filter-minimal post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-7 # Defines flow run sorting options.
  --offset: int # default: 0
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, flow_id: string, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, pause_keys: any, resuming: any, retry_type: any>, tags: list<string>, labels: any, parent_task_run_id: any, state_type: any, state_name: any, state_timestamp: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, cancelled_by: any, work_queue_id: any, work_queue: any, flow: any, job_variables: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/filter-minimal")
  let body = {sort: $body_sort, offset: $offset, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Flow Run
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}
# operationId: update_flow_run_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__patch
# --empirical_policy shape: {max_retries?: int, retry_delay_seconds?: float, retries?: any, retry_delay?: any, pause_keys?: any, resuming?: any, retry_type?: any}
export def "accounts-workspaces-flow-runs patch" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --name: any
  --flow-version: any
  --parameters: record
  --empirical-policy: record # Defines of how a flow run should retry. — shape: {max_retries?: int, retry_delay_seconds?: float, retries?: any, retry_delay?: any, pause_keys?: any, resuming?: any, retry_type?: any}
  --tags: list
  --infrastructure-pid: any
  --job-variables: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)")
  let body = {name: $name, flow_version: $flow_version, parameters: $parameters, empirical_policy: $empirical_policy, tags: $tags, infrastructure_pid: $infrastructure_pid, job_variables: $job_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow Run
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}
# operationId: read_flow_run_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__get
export def "accounts-workspaces-flow-runs get" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, flow_id: string, flow_name: any, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_id: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, pause_keys: any, resuming: any, retry_type: any>, tags: list<string>, labels: any, parent_task_run_id: any, state_type: any, state_name: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, work_pool_id: any, work_pool_name: any, state: any, job_variables: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Flow Run
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}
# operationId: delete_flow_run_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__delete
export def "accounts-workspaces-flow-runs delete" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Flow Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/count
# operationId: count_flow_runs_api_accounts__account_id__workspaces__workspace_id__flow_runs_count_post
export def "accounts-workspaces-flow-runs-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/count")
  let body = {flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Average Flow Run Lateness
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/lateness
# operationId: average_flow_run_lateness_api_accounts__account_id__workspaces__workspace_id__flow_runs_lateness_post
export def "accounts-workspaces-flow-runs-lateness post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/lateness")
  let body = {flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Flow Run History
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/history
# operationId: flow_run_history_api_accounts__account_id__workspaces__workspace_id__flow_runs_history_post
export def "accounts-workspaces-flow-runs-history post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  history_start: string # The history's start time. (format: date-time)
  history_end: string # The history's end time. (format: date-time)
  history_interval_seconds: float # The size of each history interval, in seconds. Must be at least 1 second. (format: time-delta)
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-queues: any
]: any -> table<interval_start: string, interval_end: string, states: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/history")
  let body = {history_start: $history_start, history_end: $history_end, history_interval_seconds: $history_interval_seconds, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_queues: $work_queues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow Run Graph V1
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/graph
# operationId: read_flow_run_graph_v1_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__graph_get
export def "accounts-workspaces-flow-runs-graph get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> table<id: string, name: string, upstream_dependencies: list<record>, state: record<id: string, type: string, name: any, timestamp: string, message: any, data: any, state_details: record>, expected_start_time: any, start_time: any, end_time: any, total_run_time: any, estimated_run_time: any, untrackable_result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/graph")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Flow Run Graph V2
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/graph-v2
# operationId: read_flow_run_graph_v2_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__graph_v2_get
export def "accounts-workspaces-flow-runs-graph-v2 get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Only include runs that start or end after this time. (format: date-time, default: 0001-01-01T00:00:00)
  --x-prefect-api-version: string
]: nothing -> record<start_time: string, end_time: any, root_node_ids: list<string>, nodes: list<list<any>>, artifacts: table<id: string, created: string, key: any, type: string, is_latest: bool, data: any>, states: table<id: string, timestamp: string, type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/graph-v2" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flow Run Artifacts
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/artifacts
# operationId: get_flow_run_artifacts_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__artifacts_get
export def "accounts-workspaces-flow-runs-artifacts get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --depth: string # Optional depth limit for recursion (0 = flow run only)
  --since: string # Only return artifacts created on or after this timestamp
  --until: string # Only return artifacts created on or before this timestamp
  --qp-sort: string@sort-completer-3 # Sort order by creation time (asc or desc) (default: desc)
  --x-prefect-api-version: string
]: nothing -> table<id: string, created: any, updated: any, key: any, type: any, description: any, data: any, metadata_: any, flow_run_id: any, task_run_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth" $depth "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/artifacts" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume Flow Run
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/resume
# operationId: resume_flow_run_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__resume_post
export def "accounts-workspaces-flow-runs-resume post" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --run-input: any
]: any -> record<state: any, status: string, details: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/resume")
  let body = {run_input: $run_input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete Flow Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/bulk_delete
# operationId: bulk_delete_flow_runs_api_accounts__account_id__workspaces__workspace_id__flow_runs_bulk_delete_post
# --flow_runs shape: {operator?: "and_"|"or_", id?: any, name?: any, tags?: any, flow_id?: any, deployment_id?: any, deployment_version_id?: any, deployment_version_info?: any, work_queue_id?: any, work_queue_name?: any, state?: any, flow_version?: any, start_time?: any, expected_start_time?: any, next_scheduled_start_time?: any, end_time?: any, parent_flow_run_id?: any, parent_task_run_id?: any, idempotency_key?: any, created_by?: any}
export def "accounts-workspaces-flow-runs-bulk-delete post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  flow_runs: record # Filter flow runs. Only flow runs matching all criteria will be returned — shape: {operator?: "and_"|"or_", id?: any, name?: any, tags?: any, flow_id?: any, deployment_id?: any, deployment_version_id?: any, deployment_version_info?: any, work_queue_id?: any, work_queue_name?: any, state?: any, flow_version?: any, start_time?: any, expected_start_time?: any, next_scheduled_start_time?: any, end_time?: any, parent_flow_run_id?: any, parent_task_run_id?: any, idempotency_key?: any, created_by?: any}
  --limit: int # Maximum number of flow runs to delete (default: 50)
]: any -> record<deleted: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/bulk_delete")
  let body = {flow_runs: $flow_runs, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Set Flow Run State
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/bulk_set_state
# operationId: bulk_set_flow_run_state_api_accounts__account_id__workspaces__workspace_id__flow_runs_bulk_set_state_post
# --flow_runs shape: {operator?: "and_"|"or_", id?: any, name?: any, tags?: any, flow_id?: any, deployment_id?: any, deployment_version_id?: any, deployment_version_info?: any, work_queue_id?: any, work_queue_name?: any, state?: any, flow_version?: any, start_time?: any, expected_start_time?: any, next_scheduled_start_time?: any, end_time?: any, parent_flow_run_id?: any, parent_task_run_id?: any, idempotency_key?: any, created_by?: any}
# --state shape: {type: "SCHEDULED"|"PENDING"|"RUNNING"|"COMPLETED"|"FAILED"|"CANCELLED"|"CRASHED"|"PAUSED"|"CANCELLING", name?: any, message?: any, data?: any, state_details?: record}
export def "accounts-workspaces-flow-runs-bulk-set-state post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  flow_runs: record # Filter flow runs. Only flow runs matching all criteria will be returned — shape: {operator?: "and_"|"or_", id?: any, name?: any, tags?: any, flow_id?: any, deployment_id?: any, deployment_version_id?: any, deployment_version_info?: any, work_queue_id?: any, work_queue_name?: any, state?: any, flow_version?: any, start_time?: any, expected_start_time?: any, next_scheduled_start_time?: any, end_time?: any, parent_flow_run_id?: any, parent_task_run_id?: any, idempotency_key?: any, created_by?: any}
  state: record # Data used by the Orion API to create a new state. — shape: {type: "SCHEDULED"|"PENDING"|"RUNNING"|"COMPLETED"|"FAILED"|"CANCELLED"|"CRASHED"|"PAUSED"|"CANCELLING", name?: any, message?: any, data?: any, state_details?: record}
  --force: string@bool-completer # If false, orchestration rules will be applied that may alter or prevent the state transition. If True, orchestration rules are not applied. (default: false)
  --limit: int # Maximum number of flow runs to update (default: 50)
  --emit-event: string@bool-completer # If False, state changes will not be emitted as events server side, which may disable automations that fire when state changes occur. (default: true)
]: any -> record<results: table<flow_run_id: string, status: string, state: any, details: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/bulk_set_state")
  let body = {flow_runs: $flow_runs, state: $state, force: $force, limit: $limit, emit_event: $emit_event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Flow Run State
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/set_state
# operationId: set_flow_run_state_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__set_state_post
# --state shape: {type: "SCHEDULED"|"PENDING"|"RUNNING"|"COMPLETED"|"FAILED"|"CANCELLED"|"CRASHED"|"PAUSED"|"CANCELLING", name?: any, message?: any, data?: any, state_details?: record}
export def "accounts-workspaces-flow-runs-set-state post" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  state: record # Data used by the Orion API to create a new state. — shape: {type: "SCHEDULED"|"PENDING"|"RUNNING"|"COMPLETED"|"FAILED"|"CANCELLED"|"CRASHED"|"PAUSED"|"CANCELLING", name?: any, message?: any, data?: any, state_details?: record}
  --force: string@bool-completer # If false, orchestration rules will be applied that may alter or prevent the state transition. If True, orchestration rules are not applied. (default: false)
  --emit-event: string@bool-completer # If False, the state change will not be emitted as an event server side, expecting the client to do so instead. If True, the state change will be emitted as an event. (default: true)
]: any -> record<state: any, status: string, details: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/set_state")
  let body = {state: $state, force: $force, emit_event: $emit_event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Flow Run Input
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/input
# operationId: create_flow_run_input_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__input_post
export def "accounts-workspaces-flow-runs-input post" [
  account_id: string
  id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  key: string # The input key
  value: string # The value of the input
  --sender: any # The sender of the input
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/input")
  let body = {key: $key, value: $value, sender: $sender} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Filter Flow Run Input
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/input/filter
# operationId: filter_flow_run_input_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__input_filter_post
export def "accounts-workspaces-flow-runs-input-filter post" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  prefix: string # The input key prefix
  --limit: int # The maximum number of results to return (default: 1)
  --exclude-keys: list # Exclude inputs with these keys (default: [])
]: any -> table<id: string, created: any, updated: any, flow_run_id: string, key: string, value: string, sender: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/input/filter")
  let body = {prefix: $prefix, limit: $limit, exclude_keys: $exclude_keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow Run Input
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/input/{key}
# operationId: read_flow_run_input_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__input__key__get
export def "accounts-workspaces-flow-runs-input get" [
  id: string
  key: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/input/($key)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Flow Run Input
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/input/{key}
# operationId: delete_flow_run_input_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__input__key__delete
export def "accounts-workspaces-flow-runs-input delete" [
  id: string
  key: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/input/($key)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Paginate Flow Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/paginate
# operationId: paginate_flow_runs_api_accounts__account_id__workspaces__workspace_id__flow_runs_paginate_post
export def "accounts-workspaces-flow-runs-paginate post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-7 # Defines flow run sorting options.
  --page: int # default: 1
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, name: string, flow_id: string, flow_name: any, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_id: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record, tags: list, labels: any, parent_task_run_id: any, state_type: any, state_name: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, work_pool_id: any, work_pool_name: any, state: any, job_variables: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/paginate")
  let body = {sort: $body_sort, page: $page, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Flow Run Labels
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/labels
# operationId: update_flow_run_labels_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__labels_patch
export def "accounts-workspaces-flow-runs-labels patch" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/labels")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Flow Run Materializations
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/assets/materializations
# operationId: get_flow_run_materializations_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__assets_materializations_get
export def "accounts-workspaces-flow-runs-assets-materializations get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --depth: string # Optional depth limit based on execution hierarchy. depth=0: only the root flow run. depth=1: root + direct children (tasks and subflows). None: unlimited depth (default).
  --since: string # Only return materializations on or after this timestamp
  --until: string # Only return materializations on or before this timestamp
  --qp-sort: string@sort-completer-3 # Sort order by occurred time (asc or desc) (default: desc)
  --x-prefect-api-version: string
]: nothing -> table<asset_key: string, occurred: string, status: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, upstream_assets: list<string>, by_tools: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth" $depth "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/assets/materializations" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flow Run References
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_runs/{id}/assets/references
# operationId: get_flow_run_references_api_accounts__account_id__workspaces__workspace_id__flow_runs__id__assets_references_get
export def "accounts-workspaces-flow-runs-assets-references get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --depth: string # Optional depth limit based on execution hierarchy. depth=0: only the root flow run. depth=1: root + direct children (tasks and subflows). None: unlimited depth (default).
  --since: string # Only return references on or after this timestamp
  --until: string # Only return references on or before this timestamp
  --qp-sort: string@sort-completer-3 # Sort order by occurred time (asc or desc) (default: desc)
  --x-prefect-api-version: string
]: nothing -> table<asset_key: string, occurred: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth" $depth "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_runs/($id)/assets/references" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Task Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/filter
# operationId: read_task_runs_api_accounts__account_id__workspaces__workspace_id__task_runs_filter_post
export def "accounts-workspaces-task-runs-filter post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-8 # Defines task run sorting options.
  --offset: int # default: 0
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, flow_run_id: any, task_key: string, dynamic_key: string, cache_key: any, cache_expiration: any, task_version: any, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, retry_jitter_factor: any>, tags: list<string>, labels: any, state_id: any, task_inputs: record, state_type: any, state_name: any, run_count: int, flow_run_run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, state: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/filter")
  let body = {sort: $body_sort, offset: $offset, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Task Run
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/{id}
# operationId: delete_task_run_api_accounts__account_id__workspaces__workspace_id__task_runs__id__delete
export def "accounts-workspaces-task-runs delete" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Task Run
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/{id}
# operationId: update_task_run_api_accounts__account_id__workspaces__workspace_id__task_runs__id__patch
export def "accounts-workspaces-task-runs patch" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Task Run
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/{id}
# operationId: read_task_run_api_accounts__account_id__workspaces__workspace_id__task_runs__id__get
export def "accounts-workspaces-task-runs get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, flow_run_id: any, task_key: string, dynamic_key: string, cache_key: any, cache_expiration: any, task_version: any, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, retry_jitter_factor: any>, tags: list<string>, labels: any, state_id: any, task_inputs: record, state_type: any, state_name: any, run_count: int, flow_run_run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, state: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Task Run
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/
# operationId: create_task_run_api_accounts__account_id__workspaces__workspace_id__task_runs__post
# --empirical_policy shape: {max_retries?: int, retry_delay_seconds?: float, retries?: any, retry_delay?: any, retry_jitter_factor?: any}
export def "accounts-workspaces-task-runs post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --id: any # The ID to use for the task run. If not provided, a random UUID will be generated.
  --state: any # The state of the task run to create
  --name: string
  --flow-run-id: any # The flow run id of the task run.
  task_key: string # A unique identifier for the task being run.
  dynamic_key: string # A dynamic key used to differentiate between multiple runs of the same task within the same flow run.
  --cache-key: any # An optional cache key. If a COMPLETED state associated with this cache key is found, the cached COMPLETED state will be used instead of executing the task run.
  --cache-expiration: any # Specifies when the cached state should expire.
  --task-version: any # The version of the task being run.
  --empirical-policy: record # Defines of how a task run should retry. — shape: {max_retries?: int, retry_delay_seconds?: float, retries?: any, retry_delay?: any, retry_jitter_factor?: any}
  --tags: list # A list of tags for the task run.
  --labels: any # A dictionary of key-value labels. Values can be strings, numbers, or booleans.
  --task-inputs: record # The inputs to the task run.
]: any -> record<id: string, created: any, updated: any, name: string, flow_run_id: any, task_key: string, dynamic_key: string, cache_key: any, cache_expiration: any, task_version: any, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, retry_jitter_factor: any>, tags: list<string>, labels: any, state_id: any, task_inputs: record, state_type: any, state_name: any, run_count: int, flow_run_run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, state: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/")
  let body = {id: $id, state: $state, name: $name, flow_run_id: $flow_run_id, task_key: $task_key, dynamic_key: $dynamic_key, cache_key: $cache_key, cache_expiration: $cache_expiration, task_version: $task_version, empirical_policy: $empirical_policy, tags: $tags, labels: $labels, task_inputs: $task_inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Task Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/count
# operationId: count_task_runs_api_accounts__account_id__workspaces__workspace_id__task_runs_count_post
export def "accounts-workspaces-task-runs-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/count")
  let body = {flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Task Run History
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/history
# operationId: task_run_history_api_accounts__account_id__workspaces__workspace_id__task_runs_history_post
export def "accounts-workspaces-task-runs-history post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  history_start: string # The history's start time. (format: date-time)
  history_end: string # The history's end time. (format: date-time)
  history_interval_seconds: float # The size of each history interval, in seconds. Must be at least 1 second. (format: time-delta)
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
]: any -> table<interval_start: string, interval_end: string, states: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/history")
  let body = {history_start: $history_start, history_end: $history_end, history_interval_seconds: $history_interval_seconds, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Task Run Artifacts
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/{id}/artifacts
# operationId: get_task_run_artifacts_api_accounts__account_id__workspaces__workspace_id__task_runs__id__artifacts_get
export def "accounts-workspaces-task-runs-artifacts get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --depth: string # Optional depth limit for recursion (0 = task run only)
  --since: string # Only return artifacts created on or after this timestamp
  --until: string # Only return artifacts created on or before this timestamp
  --qp-sort: string@sort-completer-3 # Sort order by creation time (asc or desc) (default: desc)
  --x-prefect-api-version: string
]: nothing -> table<id: string, created: any, updated: any, key: any, type: any, description: any, data: any, metadata_: any, flow_run_id: any, task_run_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth" $depth "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/($id)/artifacts" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Task Run Materializations
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/{id}/assets/materializations
# operationId: get_task_run_materializations_api_accounts__account_id__workspaces__workspace_id__task_runs__id__assets_materializations_get
export def "accounts-workspaces-task-runs-assets-materializations get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --depth: string # Optional depth limit based on execution hierarchy. depth=0: only the task run. depth=1: task run + its descendants. None: unlimited depth (default).
  --since: string # Only return materializations on or after this timestamp
  --until: string # Only return materializations on or before this timestamp
  --qp-sort: string@sort-completer-3 # Sort order by occurred time (asc or desc) (default: desc)
  --x-prefect-api-version: string
]: nothing -> table<asset_key: string, occurred: string, status: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, upstream_assets: list<string>, by_tools: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth" $depth "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/($id)/assets/materializations" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Task Run References
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/{id}/assets/references
# operationId: get_task_run_references_api_accounts__account_id__workspaces__workspace_id__task_runs__id__assets_references_get
export def "accounts-workspaces-task-runs-assets-references get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --depth: string # Optional depth limit based on execution hierarchy. depth=0: only the task run. depth=1: task run + its descendants. None: unlimited depth (default).
  --since: string # Only return references on or after this timestamp
  --until: string # Only return references on or before this timestamp
  --qp-sort: string@sort-completer-3 # Sort order by occurred time (asc or desc) (default: desc)
  --x-prefect-api-version: string
]: nothing -> table<asset_key: string, occurred: string, task_run_id: string, flow_run_id: any, event_id: string, metadata: record, name: string, url: string, description: string, owners: list<string>, originating_workspace_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth" $depth "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/($id)/assets/references" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Task Run State
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/{id}/set_state
# operationId: set_task_run_state_api_accounts__account_id__workspaces__workspace_id__task_runs__id__set_state_post
# --state shape: {type: "SCHEDULED"|"PENDING"|"RUNNING"|"COMPLETED"|"FAILED"|"CANCELLED"|"CRASHED"|"PAUSED"|"CANCELLING", name?: any, message?: any, data?: any, state_details?: record}
export def "accounts-workspaces-task-runs-set-state post" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  state: record # Data used by the Orion API to create a new state. — shape: {type: "SCHEDULED"|"PENDING"|"RUNNING"|"COMPLETED"|"FAILED"|"CANCELLED"|"CRASHED"|"PAUSED"|"CANCELLING", name?: any, message?: any, data?: any, state_details?: record}
  --force: string@bool-completer # If false, orchestration rules will be applied that may alter or prevent the state transition. If True, orchestration rules are not applied. (default: false)
]: any -> record<state: any, status: string, details: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/($id)/set_state")
  let body = {state: $state, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Paginate Task Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/task_runs/paginate
# operationId: paginate_task_runs_api_accounts__account_id__workspaces__workspace_id__task_runs_paginate_post
export def "accounts-workspaces-task-runs-paginate post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-8 # Defines task run sorting options.
  --page: int # default: 1
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, name: string, flow_run_id: any, task_key: string, dynamic_key: string, cache_key: any, cache_expiration: any, task_version: any, empirical_policy: record, tags: list, labels: any, state_id: any, task_inputs: record, state_type: any, state_name: any, run_count: int, flow_run_run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, state: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_runs/paginate")
  let body = {sort: $body_sort, page: $page, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Task Workers
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/task_workers/filter
# operationId: read_task_workers_api_accounts__account_id__workspaces__workspace_id__task_workers_filter_post
export def "accounts-workspaces-task-workers-filter post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --task-worker-filter: any # The task worker filter
]: any -> table<identifier: string, task_keys: list<string>, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_workers/filter")
  let body = {task_worker_filter: $task_worker_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow Run State
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_run_states/{id}
# operationId: read_flow_run_state_api_accounts__account_id__workspaces__workspace_id__flow_run_states__id__get
export def "accounts-workspaces-flow-run-states get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, type: string, name: any, timestamp: string, message: any, data: any, state_details: record<flow_run_id: any, task_run_id: any, child_flow_run_id: any, scheduled_time: any, cache_key: any, cache_expiration: any, deferred: any, untrackable_result: bool, pause_timeout: any, pause_reschedule: bool, pause_key: any, run_input_keyset: any, refresh_cache: any, retriable: any, transition_id: any, task_parameters_id: any, traceparent: any, deployment_concurrency_lease_id: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_run_states/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Flow Run States
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/flow_run_states/
# operationId: read_flow_run_states_api_accounts__account_id__workspaces__workspace_id__flow_run_states__get
export def "accounts-workspaces-flow-run-states list" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flow-run-id: string # format: uuid
  --x-prefect-api-version: string
]: nothing -> table<id: string, type: string, name: any, timestamp: string, message: any, data: any, state_details: record<flow_run_id: any, task_run_id: any, child_flow_run_id: any, scheduled_time: any, cache_key: any, cache_expiration: any, deferred: any, untrackable_result: bool, pause_timeout: any, pause_reschedule: bool, pause_key: any, run_input_keyset: any, refresh_cache: any, retriable: any, transition_id: any, task_parameters_id: any, traceparent: any, deployment_concurrency_lease_id: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flow_run_id" $flow_run_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/flow_run_states/" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Task Run State
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/task_run_states/{id}
# operationId: read_task_run_state_api_accounts__account_id__workspaces__workspace_id__task_run_states__id__get
export def "accounts-workspaces-task-run-states get" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_run_states/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Task Run States
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/task_run_states/
# operationId: read_task_run_states_api_accounts__account_id__workspaces__workspace_id__task_run_states__get
export def "accounts-workspaces-task-run-states list" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --task-run-id: string # format: uuid
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "task_run_id" $task_run_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/task_run_states/" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/
# operationId: create_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__post
# --schedules item shape: {active?: bool, max_active_runs?: any, max_scheduled_runs?: any, catchup?: bool, schedule: any, parameters?: record, slug?: any, replaces?: any}
export def "accounts-workspaces-deployments post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --infra-overrides: any # Deprecated field. Use `job_variables` instead.
  name: string # The name of the deployment.
  --branch: any
  --body-base: any
  --root: any
  --version: any
  --version-info: any
  flow_id: string # The ID of the flow associated with the deployment. (format: uuid)
  --is-schedule-active: string@bool-completer # Whether the schedule is active. (default: true)
  --paused: string@bool-completer # Whether or not the deployment is paused. (default: false)
  --disabled: string@bool-completer # Whether or not the deployment is disabled. (default: false)
  --schedules: list # A list of schedules for the deployment. — item shape: {active?: bool, max_active_runs?: any, max_scheduled_runs?: any, catchup?: bool, schedule: any, parameters?: record, slug?: any, replaces?: any}
  --concurrency-limit: any # The deployment's concurrency limit.
  --concurrency-options: any # Options for configuring deployment concurrency.
  --global-concurrency-limit-id: any # The ID of the global concurrency limit to apply to the deployment.
  --enforce-parameter-schema: string@bool-completer # Whether or not the deployment should enforce the parameter schema. (default: false)
  --parameter-openapi-schema: any # The parameter schema of the flow, including defaults.
  --parameters: record # Parameters for flow runs scheduled by the deployment.
  --tags: list # A list of deployment tags.
  --labels: any # A dictionary of key-value labels. Values can be strings, numbers, or booleans.
  --pull-steps: any
  --manifest-path: any
  --work-queue-name: any
  --work-pool-name: any # The name of the deployment's work pool.
  --storage-document-id: any
  --infrastructure-document-id: any
  --schedule: any # The schedule for the deployment.
  --description: any
  --path: any
  --entrypoint: any
  --job-variables: record # Overrides for the flow's infrastructure configuration.
]: any -> record<id: string, created: any, updated: any, infra_overrides: any, name: string, version_id: any, version: any, version_info: any, branch: any, root: any, base: any, description: any, flow_id: string, schedule: any, is_schedule_active: bool, paused: bool, disabled: bool, schedules: table<id: string, created: any, updated: any, deployment_id: any, schedule: any, active: bool, last_scheduled_at: any, soonest_scheduled_run: any, latest_scheduled_run: any, max_active_runs: any, max_scheduled_runs: any, catchup: bool, parameters: record, slug: any>, concurrency_limit: any, global_concurrency_limit: any, concurrency_options: any, job_variables: record, parameters: record, tags: list<string>, labels: any, work_queue_name: any, work_queue_id: any, last_polled: any, parameter_openapi_schema: any, path: any, pull_steps: any, entrypoint: any, manifest_path: any, storage_document_id: any, infrastructure_document_id: any, created_by: any, updated_by: any, work_pool_name: any, status: any, enforce_parameter_schema: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/")
  let body = {infra_overrides: $infra_overrides, name: $name, branch: $branch, base: $body_base, root: $root, version: $version, version_info: $version_info, flow_id: $flow_id, is_schedule_active: $is_schedule_active, paused: $paused, disabled: $disabled, schedules: $schedules, concurrency_limit: $concurrency_limit, concurrency_options: $concurrency_options, global_concurrency_limit_id: $global_concurrency_limit_id, enforce_parameter_schema: $enforce_parameter_schema, parameter_openapi_schema: $parameter_openapi_schema, parameters: $parameters, tags: $tags, labels: $labels, pull_steps: $pull_steps, manifest_path: $manifest_path, work_queue_name: $work_queue_name, work_pool_name: $work_pool_name, storage_document_id: $storage_document_id, infrastructure_document_id: $infrastructure_document_id, schedule: $schedule, description: $description, path: $path, entrypoint: $entrypoint, job_variables: $job_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Branch From Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/branch
# operationId: branch_from_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__branch_post
# --options shape: {schedule_handling?: "keep"|"remove"|"inactive"}
export def "accounts-workspaces-deployments-branch post" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  branch: string # Name of the branch to create
  --options: record # shape: {schedule_handling?: "keep"|"remove"|"inactive"}
  --overrides: any # Optional values to override in the branched deployment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/branch")
  let body = {branch: $branch, options: $options, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Deployment
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}
# operationId: update_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__patch
# --schedules item shape: {active?: any, schedule?: any, max_active_runs?: any, max_scheduled_runs?: any, catchup?: any, parameters?: any, slug?: any, replaces?: any}
export def "accounts-workspaces-deployments patch" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --infra-overrides: any # Deprecated field. Use `job_variables` instead.
  --version: any
  --version-info: any
  --schedule: any # The schedule for the deployment.
  --description: any
  --is-schedule-active: string@bool-completer # Whether the schedule is active. (default: true)
  --paused: string@bool-completer # Whether or not the deployment is paused. (default: false)
  --schedules: list # A list of schedule updates for the deployment. — item shape: {active?: any, schedule?: any, max_active_runs?: any, max_scheduled_runs?: any, catchup?: any, parameters?: any, slug?: any, replaces?: any}
  --concurrency-limit: any # The deployment's concurrency limit.
  --concurrency-options: any # Options for configuring deployment concurrency.
  --global-concurrency-limit-id: any # The ID of the global concurrency limit to apply to the deployment.
  --parameters: any # Parameters for flow runs scheduled by the deployment.
  --parameter-openapi-schema: any # The parameter schema of the flow, including defaults.
  --tags: list # A list of deployment tags.
  --labels: any # A dictionary of key-value labels. Values can be strings, numbers, or booleans.
  --pull-steps: any
  --work-queue-name: any
  --work-pool-name: any # The name of the deployment's work pool.
  --path: any
  --job-variables: any
  --entrypoint: any
  --manifest-path: any
  --storage-document-id: any
  --infrastructure-document-id: any
  --enforce-parameter-schema: any # Whether or not the deployment should enforce the parameter schema.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)")
  let body = {infra_overrides: $infra_overrides, version: $version, version_info: $version_info, schedule: $schedule, description: $description, is_schedule_active: $is_schedule_active, paused: $paused, schedules: $schedules, concurrency_limit: $concurrency_limit, concurrency_options: $concurrency_options, global_concurrency_limit_id: $global_concurrency_limit_id, parameters: $parameters, parameter_openapi_schema: $parameter_openapi_schema, tags: $tags, labels: $labels, pull_steps: $pull_steps, work_queue_name: $work_queue_name, work_pool_name: $work_pool_name, path: $path, job_variables: $job_variables, entrypoint: $entrypoint, manifest_path: $manifest_path, storage_document_id: $storage_document_id, infrastructure_document_id: $infrastructure_document_id, enforce_parameter_schema: $enforce_parameter_schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Deployment
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}
# operationId: read_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__get
export def "accounts-workspaces-deployments get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, infra_overrides: any, name: string, version_id: any, version: any, version_info: any, branch: any, root: any, base: any, description: any, flow_id: string, schedule: any, is_schedule_active: bool, paused: bool, disabled: bool, schedules: table<id: string, created: any, updated: any, deployment_id: any, schedule: any, active: bool, last_scheduled_at: any, soonest_scheduled_run: any, latest_scheduled_run: any, max_active_runs: any, max_scheduled_runs: any, catchup: bool, parameters: record, slug: any>, concurrency_limit: any, global_concurrency_limit: any, concurrency_options: any, job_variables: record, parameters: record, tags: list<string>, labels: any, work_queue_name: any, work_queue_id: any, last_polled: any, parameter_openapi_schema: any, path: any, pull_steps: any, entrypoint: any, manifest_path: any, storage_document_id: any, infrastructure_document_id: any, created_by: any, updated_by: any, work_pool_name: any, status: any, enforce_parameter_schema: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Deployment
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}
# operationId: delete_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__delete
export def "accounts-workspaces-deployments delete" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Deployment By Name
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/name/{flow_name}/{deployment_name}
# operationId: read_deployment_by_name_api_accounts__account_id__workspaces__workspace_id__deployments_name__flow_name___deployment_name__get
export def "accounts-workspaces-deployments-name get" [
  workspace_id: string
  account_id: string
  flow_name: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, infra_overrides: any, name: string, version_id: any, version: any, version_info: any, branch: any, root: any, base: any, description: any, flow_id: string, schedule: any, is_schedule_active: bool, paused: bool, disabled: bool, schedules: table<id: string, created: any, updated: any, deployment_id: any, schedule: any, active: bool, last_scheduled_at: any, soonest_scheduled_run: any, latest_scheduled_run: any, max_active_runs: any, max_scheduled_runs: any, catchup: bool, parameters: record, slug: any>, concurrency_limit: any, global_concurrency_limit: any, concurrency_options: any, job_variables: record, parameters: record, tags: list<string>, labels: any, work_queue_name: any, work_queue_id: any, last_polled: any, parameter_openapi_schema: any, path: any, pull_steps: any, entrypoint: any, manifest_path: any, storage_document_id: any, infrastructure_document_id: any, created_by: any, updated_by: any, work_pool_name: any, status: any, enforce_parameter_schema: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/name/($flow_name)/($deployment_name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Deployments
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/filter
# operationId: read_deployments_api_accounts__account_id__workspaces__workspace_id__deployments_filter_post
export def "accounts-workspaces-deployments-filter post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --offset: int # default: 0
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
  --body-sort: string@sort-completer-6 # Defines deployment sorting options.
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, infra_overrides: any, name: string, version_id: any, version: any, version_info: any, branch: any, root: any, base: any, description: any, flow_id: string, schedule: any, is_schedule_active: bool, paused: bool, disabled: bool, schedules: list<record>, concurrency_limit: any, global_concurrency_limit: any, concurrency_options: any, job_variables: record, parameters: record, tags: list<string>, labels: any, work_queue_name: any, work_queue_id: any, last_polled: any, parameter_openapi_schema: any, path: any, pull_steps: any, entrypoint: any, manifest_path: any, storage_document_id: any, infrastructure_document_id: any, created_by: any, updated_by: any, work_pool_name: any, status: any, enforce_parameter_schema: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/filter")
  let body = {offset: $offset, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues, sort: $body_sort, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Paginate Deployments
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/paginate
# operationId: paginate_deployments_api_accounts__account_id__workspaces__workspace_id__deployments_paginate_post
export def "accounts-workspaces-deployments-paginate post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --page: int # default: 1
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
  --body-sort: string@sort-completer-6 # Defines deployment sorting options.
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, infra_overrides: any, name: string, version_id: any, version: any, version_info: any, branch: any, root: any, base: any, description: any, flow_id: string, schedule: any, is_schedule_active: bool, paused: bool, disabled: bool, schedules: list, concurrency_limit: any, global_concurrency_limit: any, concurrency_options: any, job_variables: record, parameters: record, tags: list, labels: any, work_queue_name: any, work_queue_id: any, last_polled: any, parameter_openapi_schema: any, path: any, pull_steps: any, entrypoint: any, manifest_path: any, storage_document_id: any, infrastructure_document_id: any, created_by: any, updated_by: any, work_pool_name: any, status: any, enforce_parameter_schema: bool>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/paginate")
  let body = {page: $page, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues, sort: $body_sort, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Scheduled Flow Runs For Deployments
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/get_scheduled_flow_runs
# operationId: get_scheduled_flow_runs_for_deployments_api_accounts__account_id__workspaces__workspace_id__deployments_get_scheduled_flow_runs_post
export def "accounts-workspaces-deployments-get-scheduled-flow-runs post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  deployment_ids: list # The deployment IDs to get scheduled runs for
  --scheduled-before: string # The maximum time to look for scheduled flow runs (format: date-time)
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, flow_id: string, flow_name: any, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_id: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, pause_keys: any, resuming: any, retry_type: any>, tags: list<string>, labels: any, parent_task_run_id: any, state_type: any, state_name: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, work_pool_id: any, work_pool_name: any, state: any, job_variables: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/get_scheduled_flow_runs")
  let body = {deployment_ids: $deployment_ids, scheduled_before: $scheduled_before, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Deployments
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/count
# operationId: count_deployments_api_accounts__account_id__workspaces__workspace_id__deployments_count_post
export def "accounts-workspaces-deployments-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/count")
  let body = {flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Delete Deployments
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/bulk_delete
# operationId: bulk_delete_deployments_api_accounts__account_id__workspaces__workspace_id__deployments_bulk_delete_post
# --deployments shape: {operator?: "and_"|"or_", id?: any, branch?: any, base?: any, root?: any, name?: any, is_schedule_active?: any, paused?: any, tags?: any, work_queue_name?: any, concurrency_limit?: any, work_queue_id?: any, status?: any, flow_or_deployment_name?: any, flow_id?: any, created_by?: any, updated_by?: any}
export def "accounts-workspaces-deployments-bulk-delete post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  deployments: record # Filter for deployments. Only deployments matching all criteria will be returned. — shape: {operator?: "and_"|"or_", id?: any, branch?: any, base?: any, root?: any, name?: any, is_schedule_active?: any, paused?: any, tags?: any, work_queue_name?: any, concurrency_limit?: any, work_queue_id?: any, status?: any, flow_or_deployment_name?: any, flow_id?: any, created_by?: any, updated_by?: any}
  --limit: int # Maximum number of deployments to delete (default: 50)
]: any -> record<deleted: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/bulk_delete")
  let body = {deployments: $deployments, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/schedule
# operationId: schedule_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__schedule_post
export def "accounts-workspaces-deployments-schedule post" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --start-time: string # The earliest date to schedule (format: date-time)
  --end-time: string # The latest date to schedule (format: date-time)
  --min-time: float # Runs will be scheduled until at least this long after the `start_time` (format: time-delta)
  --min-runs: int # The minimum number of runs to schedule
  --max-runs: int # The maximum number of runs to schedule
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/schedule")
  let body = {start_time: $start_time, end_time: $end_time, min_time: $min_time, min_runs: $min_runs, max_runs: $max_runs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resume Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/resume_deployment
# operationId: resume_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__resume_deployment_post
export def "accounts-workspaces-deployments-resume-deployment post" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/resume_deployment")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/set_schedule_active
# operationId: resume_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__set_schedule_active_post
export def "accounts-workspaces-deployments-set-schedule-active post" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/set_schedule_active")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/pause_deployment
# operationId: pause_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__pause_deployment_post
export def "accounts-workspaces-deployments-pause-deployment post" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/pause_deployment")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/set_schedule_inactive
# operationId: pause_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__set_schedule_inactive_post
export def "accounts-workspaces-deployments-set-schedule-inactive post" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/set_schedule_inactive")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Flow Run From Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/create_flow_run
# operationId: create_flow_run_from_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__create_flow_run_post
# --empirical_policy shape: {max_retries?: int, retry_delay_seconds?: float, retries?: any, retry_delay?: any, pause_keys?: any, resuming?: any, retry_type?: any}
export def "accounts-workspaces-deployments-create-flow-run post" [
  workspace_id: string
  account_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --state: any # The state of the flow run to create
  --name: string # The name of the flow run. Defaults to a random slug if not specified.
  --parameters: record
  --enforce-parameter-schema: any # Whether or not to enforce the parameter schema on this run.
  --context: record
  --infrastructure-document-id: any
  --empirical-policy: record # Defines of how a flow run should retry. — shape: {max_retries?: int, retry_delay_seconds?: float, retries?: any, retry_delay?: any, pause_keys?: any, resuming?: any, retry_type?: any}
  --tags: list # A list of tags for the flow run.
  --labels: any # A dictionary of key-value labels. Values can be strings, numbers, or booleans.
  --idempotency-key: any # An optional idempotency key. If a flow run with the same idempotency key has already been created, the existing flow run will be returned.
  --parent-task-run-id: any
  --work-queue-name: any
  --job-variables: any
]: any -> record<id: string, created: any, updated: any, name: string, flow_id: string, flow_name: any, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_id: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, pause_keys: any, resuming: any, retry_type: any>, tags: list<string>, labels: any, parent_task_run_id: any, state_type: any, state_name: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, work_pool_id: any, work_pool_name: any, state: any, job_variables: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/create_flow_run")
  let body = {state: $state, name: $name, parameters: $parameters, enforce_parameter_schema: $enforce_parameter_schema, context: $context, infrastructure_document_id: $infrastructure_document_id, empirical_policy: $empirical_policy, tags: $tags, labels: $labels, idempotency_key: $idempotency_key, parent_task_run_id: $parent_task_run_id, work_queue_name: $work_queue_name, job_variables: $job_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Create Flow Runs From Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/create_flow_run/bulk
# operationId: bulk_create_flow_runs_from_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__create_flow_run_bulk_post
export def "accounts-workspaces-deployments-create-flow-run-bulk post" [
  workspace_id: string
  account_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body: record
]: any -> record<results: table<flow_run_id: any, status: string, flow_run: any, error: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/create_flow_run/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Deployment Access
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/access
# operationId: read_deployment_access_api_accounts__account_id__workspaces__workspace_id__deployments__id__access_get
export def "accounts-workspaces-deployments-access get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<manage_actors: table<id: any, name: string, email: any, type: string>, run_actors: table<id: any, name: string, email: any, type: string>, view_actors: table<id: any, name: string, email: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/access")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Deployment Access
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/access
# operationId: set_deployment_access_api_accounts__account_id__workspaces__workspace_id__deployments__id__access_put
# --access_control shape: {manage_actor_ids: list, run_actor_ids: list, view_actor_ids: list, manage_team_ids?: list, run_team_ids?: list, view_team_ids?: list}
export def "accounts-workspaces-deployments-access put" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  access_control: record # Data used to replace the existing deployment access. — shape: {manage_actor_ids: list, run_actor_ids: list, view_actor_ids: list, manage_team_ids?: list, run_team_ids?: list, view_team_ids?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/access")
  let body = {access_control: $access_control} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Actors Deployment Access
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/my-access
# operationId: read_actors_deployment_access_api_accounts__account_id__workspaces__workspace_id__deployments_my_access_post
export def "accounts-workspaces-deployments-my-access post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  deployment_ids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/my-access")
  let body = {deployment_ids: $deployment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Work Queue Check For Deployment
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/work_queue_check
# DEPRECATED
# operationId: work_queue_check_for_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__work_queue_check_get
@deprecated
export def "accounts-workspaces-deployments-work-queue-check get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> table<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/work_queue_check")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Deployment Schedules
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/schedules
# operationId: read_deployment_schedules_api_accounts__account_id__workspaces__workspace_id__deployments__id__schedules_get
export def "accounts-workspaces-deployments-schedules get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> table<id: string, created: any, updated: any, deployment_id: any, schedule: any, active: bool, max_active_runs: any, catchup: bool, slug: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/schedules")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Deployment Schedules
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/schedules
# operationId: create_deployment_schedules_api_accounts__account_id__workspaces__workspace_id__deployments__id__schedules_post
export def "accounts-workspaces-deployments-schedules post" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body: record
]: any -> table<id: string, created: any, updated: any, deployment_id: any, schedule: any, active: bool, max_active_runs: any, catchup: bool, slug: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/schedules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Deployment Schedule
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/schedules/{schedule_id}
# operationId: update_deployment_schedule_api_accounts__account_id__workspaces__workspace_id__deployments__id__schedules__schedule_id__patch
export def "accounts-workspaces-deployments-schedules patch" [
  account_id: string
  workspace_id: string
  id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --active: any # Whether or not the schedule is active.
  --schedule: any # The schedule for the deployment.
  --max-active-runs: any # The maximum number of active runs for the schedule.
  --max-scheduled-runs: any # The maximum number of scheduled runs for the schedule.
  --catchup: any # Whether or not a worker should catch up on Late runs for the schedule.
  --parameters: any # Parameters for the schedule.
  --slug: any # A unique slug for the schedule.
  --replaces: any # The slug of an existing schedule that this schedule replaces. Used for renaming slugs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/schedules/($schedule_id)")
  let body = {active: $active, schedule: $schedule, max_active_runs: $max_active_runs, max_scheduled_runs: $max_scheduled_runs, catchup: $catchup, parameters: $parameters, slug: $slug, replaces: $replaces} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Deployment Schedule
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/schedules/{schedule_id}
# operationId: delete_deployment_schedule_api_accounts__account_id__workspaces__workspace_id__deployments__id__schedules__schedule_id__delete
export def "accounts-workspaces-deployments-schedules delete" [
  workspace_id: string
  id: string
  schedule_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/schedules/($schedule_id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/disable
# operationId: disable_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__disable_post
export def "accounts-workspaces-deployments-disable post" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/disable")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Deployment
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/enable
# operationId: enable_deployment_api_accounts__account_id__workspaces__workspace_id__deployments__id__enable_post
export def "accounts-workspaces-deployments-enable post" [
  workspace_id: string
  account_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/enable")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Paginate Deployment Versions
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/versions/paginate
# operationId: paginate_deployment_versions_api_accounts__account_id__workspaces__workspace_id__deployments__id__versions_paginate_post
export def "accounts-workspaces-deployments-versions-paginate post" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --page: int # default: 1
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, infra_overrides: any, description: any, tags: list, labels: any, entrypoint: any, pull_steps: any, parameters: record, parameter_openapi_schema: any, enforce_parameter_schema: bool, work_queue_id: any, work_queue_name: any, job_variables: record, created_by: any, updated_by: any, deployment_id: string, version_info: record, last_active: any, work_pool_name: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/versions/paginate")
  let body = {page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Deployment Version
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/versions/{version_id}
# operationId: read_deployment_version_api_accounts__account_id__workspaces__workspace_id__deployments__id__versions__version_id__get
export def "accounts-workspaces-deployments-versions get" [
  id: string
  version_id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, infra_overrides: any, description: any, tags: list<string>, labels: any, entrypoint: any, pull_steps: any, parameters: record, parameter_openapi_schema: any, enforce_parameter_schema: bool, work_queue_id: any, work_queue_name: any, job_variables: record, created_by: any, updated_by: any, deployment_id: string, version_info: record<type: string, version: string>, last_active: any, work_pool_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/versions/($version_id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Deployment Version
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/versions/{version_id}
# operationId: delete_deployment_version_api_accounts__account_id__workspaces__workspace_id__deployments__id__versions__version_id__delete
export def "accounts-workspaces-deployments-versions delete" [
  id: string
  version_id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/versions/($version_id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Promote Deployment Version
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/deployments/{id}/versions/{version_id}/promote
# operationId: promote_deployment_version_api_accounts__account_id__workspaces__workspace_id__deployments__id__versions__version_id__promote_post
export def "accounts-workspaces-deployments-versions-promote post" [
  id: string
  version_id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --reason: any
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/deployments/($id)/versions/($version_id)/promote")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Saved Search
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/saved_searches/
# operationId: create_saved_search_api_accounts__account_id__workspaces__workspace_id__saved_searches__put
# --filters item shape: {object: string, property: string, type: string, operation: string, value: any}
export def "accounts-workspaces-saved-searches put" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  name: string # The name of the saved search.
  --filters: list # The filter set for the saved search. — item shape: {object: string, property: string, type: string, operation: string, value: any}
]: any -> record<id: string, created: any, updated: any, name: string, filters: table<object: string, property: string, type: string, operation: string, value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/saved_searches/")
  let body = {name: $name, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Saved Search
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/saved_searches/{id}
# operationId: read_saved_search_api_accounts__account_id__workspaces__workspace_id__saved_searches__id__get
export def "accounts-workspaces-saved-searches get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, filters: table<object: string, property: string, type: string, operation: string, value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/saved_searches/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Saved Search
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/saved_searches/{id}
# operationId: delete_saved_search_api_accounts__account_id__workspaces__workspace_id__saved_searches__id__delete
export def "accounts-workspaces-saved-searches delete" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/saved_searches/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Saved Searches
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/saved_searches/filter
# operationId: read_saved_searches_api_accounts__account_id__workspaces__workspace_id__saved_searches_filter_post
export def "accounts-workspaces-saved-searches-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, filters: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/saved_searches/filter")
  let body = {offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create User Pin
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/pins/
# operationId: create_user_pin_api_accounts__account_id__workspaces__workspace_id__pins__post
export def "accounts-workspaces-pins post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  resource_type: string@resource-type-completer # Resource types that can be pinned by users.
  resource_id: string # The ID of the resource to pin. (format: uuid)
]: any -> record<id: string, created: any, updated: any, actor_id: string, resource_type: string, resource_id: string, resource_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/pins/")
  let body = {resource_type: $resource_type, resource_id: $resource_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read User Pins
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/pins/filter
# operationId: read_user_pins_api_accounts__account_id__workspaces__workspace_id__pins_filter_post
export def "accounts-workspaces-pins-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --resource-type: any
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, actor_id: string, resource_type: string, resource_id: string, resource_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/pins/filter")
  let body = {resource_type: $resource_type, offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User Pin
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/pins/{id}
# operationId: delete_user_pin_api_accounts__account_id__workspaces__workspace_id__pins__id__delete
export def "accounts-workspaces-pins delete" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/pins/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Concurrency Limit
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/
# operationId: create_concurrency_limit_api_accounts__account_id__workspaces__workspace_id__concurrency_limits__post
export def "accounts-workspaces-concurrency-limits post-by-account_id-workspace_id" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  tag: string # A tag the concurrency limit is applied to.
  concurrency_limit: int # The concurrency limit.
]: any -> record<id: string, created: any, updated: any, tag: string, concurrency_limit: int, active_slots: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/")
  let body = {tag: $tag, concurrency_limit: $concurrency_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Concurrency Limit
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/{id}
# operationId: read_concurrency_limit_api_accounts__account_id__workspaces__workspace_id__concurrency_limits__id__get
export def "accounts-workspaces-concurrency-limits get-by-id-account_id-workspace_id" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, tag: string, concurrency_limit: int, active_slots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Concurrency Limit
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/{id}
# operationId: delete_concurrency_limit_api_accounts__account_id__workspaces__workspace_id__concurrency_limits__id__delete
export def "accounts-workspaces-concurrency-limits delete-by-id-account_id-workspace_id" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Concurrency Limit By Tag
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/tag/{tag}
# operationId: read_concurrency_limit_by_tag_api_accounts__account_id__workspaces__workspace_id__concurrency_limits_tag__tag__get
export def "accounts-workspaces-concurrency-limits-tag get" [
  tag: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, tag: string, concurrency_limit: int, active_slots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/tag/($tag)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Concurrency Limit By Tag
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/tag/{tag}
# operationId: delete_concurrency_limit_by_tag_api_accounts__account_id__workspaces__workspace_id__concurrency_limits_tag__tag__delete
export def "accounts-workspaces-concurrency-limits-tag delete" [
  tag: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/tag/($tag)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Concurrency Limits
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/filter
# operationId: read_concurrency_limits_api_accounts__account_id__workspaces__workspace_id__concurrency_limits_filter_post
export def "accounts-workspaces-concurrency-limits-filter post-by-account_id-workspace_id" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, tag: string, concurrency_limit: int, active_slots: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/filter")
  let body = {offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset Concurrency Limit By Tag
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/tag/{tag}/reset
# operationId: reset_concurrency_limit_by_tag_api_accounts__account_id__workspaces__workspace_id__concurrency_limits_tag__tag__reset_post
export def "accounts-workspaces-concurrency-limits-tag-reset post" [
  tag: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --slot-override: any # Manual override for active concurrency limit slots.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/tag/($tag)/reset")
  let body = {slot_override: $slot_override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Increment Concurrency Limits V1
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/increment
# operationId: increment_concurrency_limits_v1_api_accounts__account_id__workspaces__workspace_id__concurrency_limits_increment_post
export def "accounts-workspaces-concurrency-limits-increment post-by-account_id-workspace_id" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  names: list # The tags to acquire a slot for
  task_run_id: string # The ID of the task run acquiring the slot (format: uuid)
]: any -> table<id: string, name: string, limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/increment")
  let body = {names: $names, task_run_id: $task_run_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Decrement Concurrency Limits V1
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/concurrency_limits/decrement
# operationId: decrement_concurrency_limits_v1_api_accounts__account_id__workspaces__workspace_id__concurrency_limits_decrement_post
export def "accounts-workspaces-concurrency-limits-decrement post-by-workspace_id-account_id" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  names: list # The tags to release a slot for
  task_run_id: string # The ID of the task run releasing the slot (format: uuid)
]: any -> table<id: string, name: string, limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/concurrency_limits/decrement")
  let body = {names: $names, task_run_id: $task_run_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Concurrency Limit V2
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/
# operationId: create_concurrency_limit_v2_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits__post
export def "accounts-workspaces-concurrency-limits post-by-account_id-workspace_id-1" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --active: string@bool-completer # Whether the concurrency limit is active. (default: true)
  name: string # The name of the concurrency limit.
  limit: int # The concurrency limit.
  --active-slots: int # The number of active slots. (default: 0)
  --denied-slots: int # The number of denied slots. (default: 0)
  --slot-decay-per-second: float # The decay rate for active slots when used as a rate limit. (default: 0)
]: any -> record<id: string, created: any, updated: any, active: bool, name: string, limit: int, active_slots: int, denied_slots: int, slot_decay_per_second: float, avg_slot_occupancy_seconds: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/")
  let body = {active: $active, name: $name, limit: $limit, active_slots: $active_slots, denied_slots: $denied_slots, slot_decay_per_second: $slot_decay_per_second} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Concurrency Limit V2
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/{id_or_name}
# operationId: read_concurrency_limit_v2_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits__id_or_name__get
export def "accounts-workspaces-concurrency-limits get-by-id_or_name-account_id-workspace_id" [
  id_or_name: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, active: bool, name: string, limit: int, active_slots: int, slot_decay_per_second: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/($id_or_name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Concurrency Limit V2
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/{id_or_name}
# operationId: update_concurrency_limit_v2_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits__id_or_name__patch
export def "accounts-workspaces-concurrency-limits patch" [
  id_or_name: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --active: any
  --name: any
  --limit: any
  --active-slots: any
  --denied-slots: any
  --slot-decay-per-second: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/($id_or_name)")
  let body = {active: $active, name: $name, limit: $limit, active_slots: $active_slots, denied_slots: $denied_slots, slot_decay_per_second: $slot_decay_per_second} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Concurrency Limit V2
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/{id_or_name}
# operationId: delete_concurrency_limit_v2_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits__id_or_name__delete
export def "accounts-workspaces-concurrency-limits delete-by-id_or_name-account_id-workspace_id" [
  id_or_name: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/($id_or_name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read All Concurrency Limits V2
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/filter
# operationId: read_all_concurrency_limits_v2_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits_filter_post
export def "accounts-workspaces-concurrency-limits-filter post-by-account_id-workspace_id-1" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, active: bool, name: string, limit: int, active_slots: int, slot_decay_per_second: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/filter")
  let body = {offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Paginate Concurrency Limits V2
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/paginate
# operationId: paginate_concurrency_limits_v2_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits_paginate_post
export def "accounts-workspaces-concurrency-limits-paginate post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --page: int # default: 1
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, active: bool, name: string, limit: int, active_slots: int, slot_decay_per_second: float>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/paginate")
  let body = {page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Increment Active Slots
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/increment
# operationId: bulk_increment_active_slots_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits_increment_post
@deprecated --flag create-if-missing
export def "accounts-workspaces-concurrency-limits-increment post-by-account_id-workspace_id-1" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  slots: int
  names: list
  --mode: string@mode-completer # default: concurrency
  --create-if-missing: any # DEPRECATED
]: any -> table<id: string, name: string, limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/increment")
  let body = {slots: $slots, names: $names, mode: $mode, create_if_missing: $create_if_missing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Increment Active Slots With Lease
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/increment-with-lease
# operationId: bulk_increment_active_slots_with_lease_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits_increment_with_lease_post
export def "accounts-workspaces-concurrency-limits-increment-with-lease post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  slots: int
  names: list
  --mode: string@mode-completer # default: concurrency
  --lease-duration: float # The duration of the lease in seconds. (default: 300)
  --holder: any # The holder of the lease with type (flow_run, task_run, or deployment) and id.
]: any -> record<lease_id: string, limits: table<id: string, name: string, limit: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/increment-with-lease")
  let body = {slots: $slots, names: $names, mode: $mode, lease_duration: $lease_duration, holder: $holder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Decrement Active Slots
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/decrement
# operationId: bulk_decrement_active_slots_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits_decrement_post
@deprecated --flag create-if-missing
export def "accounts-workspaces-concurrency-limits-decrement post-by-account_id-workspace_id" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  slots: int
  names: list
  --occupancy-seconds: any
  --create-if-missing: any # DEPRECATED
]: any -> table<id: string, name: string, limit: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/decrement")
  let body = {slots: $slots, names: $names, occupancy_seconds: $occupancy_seconds, create_if_missing: $create_if_missing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Decrement Active Slots With Lease
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/decrement-with-lease
# operationId: bulk_decrement_active_slots_with_lease_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits_decrement_with_lease_post
export def "accounts-workspaces-concurrency-limits-decrement-with-lease post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  lease_id: string # The ID of the lease to use for decrementing active slots. (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/decrement-with-lease")
  let body = {lease_id: $lease_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Renew Concurrency Lease
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/v2/concurrency_limits/leases/{lease_id}/renew
# operationId: renew_concurrency_lease_api_accounts__account_id__workspaces__workspace_id__v2_concurrency_limits_leases__lease_id__renew_post
export def "accounts-workspaces-concurrency-limits-leases-renew post" [
  lease_id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --lease-duration: float # The duration of the lease in seconds. (default: 300)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/v2/concurrency_limits/leases/($lease_id)/renew")
  let body = {lease_duration: $lease_duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Block Type
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/
# operationId: create_block_type_api_accounts__account_id__workspaces__workspace_id__block_types__post
export def "accounts-workspaces-block-types post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  name: string # A block type's name
  slug: string # A block type's slug
  --logo-url: any # Web URL for the block type's logo
  --documentation-url: any # Web URL for the block type's documentation
  --description: any # A short blurb about the corresponding block's intended use
  --code-example: any # A code snippet demonstrating use of the corresponding block
]: any -> record<id: string, created: any, updated: any, name: string, slug: string, logo_url: any, documentation_url: any, description: any, code_example: any, is_protected: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/")
  let body = {name: $name, slug: $slug, logo_url: $logo_url, documentation_url: $documentation_url, description: $description, code_example: $code_example} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Block Type By Id
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/{id}
# operationId: read_block_type_by_id_api_accounts__account_id__workspaces__workspace_id__block_types__id__get
export def "accounts-workspaces-block-types get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, slug: string, logo_url: any, documentation_url: any, description: any, code_example: any, is_protected: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Block Type
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/{id}
# operationId: update_block_type_api_accounts__account_id__workspaces__workspace_id__block_types__id__patch
export def "accounts-workspaces-block-types patch" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --logo-url: any
  --documentation-url: any
  --description: any
  --code-example: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/($id)")
  let body = {logo_url: $logo_url, documentation_url: $documentation_url, description: $description, code_example: $code_example} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Block Type
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/{id}
# operationId: delete_block_type_api_accounts__account_id__workspaces__workspace_id__block_types__id__delete
export def "accounts-workspaces-block-types delete" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Block Type By Slug
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/slug/{slug}
# operationId: read_block_type_by_slug_api_accounts__account_id__workspaces__workspace_id__block_types_slug__slug__get
export def "accounts-workspaces-block-types-slug get" [
  slug: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, slug: string, logo_url: any, documentation_url: any, description: any, code_example: any, is_protected: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/slug/($slug)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Block Types
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/filter
# operationId: read_block_types_api_accounts__account_id__workspaces__workspace_id__block_types_filter_post
export def "accounts-workspaces-block-types-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --block-types: any
  --block-schemas: any
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, slug: string, logo_url: any, documentation_url: any, description: any, code_example: any, is_protected: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/filter")
  let body = {block_types: $block_types, block_schemas: $block_schemas, offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Block Documents For Block Type
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/slug/{slug}/block_documents
# operationId: read_block_documents_for_block_type_api_accounts__account_id__workspaces__workspace_id__block_types_slug__slug__block_documents_get
export def "accounts-workspaces-block-types-slug-block-documents get" [
  workspace_id: string
  slug: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-secrets: string@bool-completer # Whether to include sensitive values in the block document. (default: false)
  --x-prefect-api-version: string
]: nothing -> table<id: string, created: any, updated: any, name: any, data: record, block_schema_id: string, block_schema: any, block_type_id: string, block_type_name: any, block_type: any, block_document_references: record, is_anonymous: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_secrets" $include_secrets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/slug/($slug)/block_documents" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Block Document By Name For Block Type
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/slug/{slug}/block_documents/name/{block_document_name}
# operationId: read_block_document_by_name_for_block_type_api_accounts__account_id__workspaces__workspace_id__block_types_slug__slug__block_documents_name__block_document_name__get
export def "accounts-workspaces-block-types-slug-block-documents-name get" [
  workspace_id: string
  slug: string
  block_document_name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-secrets: string@bool-completer # Whether to include sensitive values in the block document. (default: false)
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: any, data: record, block_schema_id: string, block_schema: any, block_type_id: string, block_type_name: any, block_type: any, block_document_references: record, is_anonymous: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_secrets" $include_secrets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/slug/($slug)/block_documents/name/($block_document_name)" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install System Block Types
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_types/install_system_block_types
# operationId: install_system_block_types_api_accounts__account_id__workspaces__workspace_id__block_types_install_system_block_types_post
export def "accounts-workspaces-block-types-install-system-block-types post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_types/install_system_block_types")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Block Document
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/
# operationId: create_block_document_api_accounts__account_id__workspaces__workspace_id__block_documents__post
export def "accounts-workspaces-block-documents post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --name: any # The block document's name. Not required for anonymous block documents.
  --data: record # The block document's data
  block_schema_id: string # A block schema ID (format: uuid)
  block_type_id: string # A block type ID (format: uuid)
  --is-anonymous: string@bool-completer # Whether the block is anonymous (anonymous blocks are usually created by Prefect automatically) (default: false)
]: any -> record<id: string, created: any, updated: any, name: any, data: record, block_schema_id: string, block_schema: any, block_type_id: string, block_type_name: any, block_type: any, block_document_references: record, is_anonymous: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/")
  let body = {name: $name, data: $data, block_schema_id: $block_schema_id, block_type_id: $block_type_id, is_anonymous: $is_anonymous} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Or Update Block Document
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/
# operationId: create_or_update_block_document_api_accounts__account_id__workspaces__workspace_id__block_documents__put
export def "accounts-workspaces-block-documents put" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --name: any # The block document's name. Not required for anonymous block documents.
  --data: record # The block document's data
  block_schema_id: string # A block schema ID (format: uuid)
  block_type_id: string # A block type ID (format: uuid)
  --is-anonymous: string@bool-completer # Whether the block is anonymous (anonymous blocks are usually created by Prefect automatically) (default: false)
]: any -> record<id: string, created: any, updated: any, name: any, data: record, block_schema_id: string, block_schema: any, block_type_id: string, block_type_name: any, block_type: any, block_document_references: record, is_anonymous: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/")
  let body = {name: $name, data: $data, block_schema_id: $block_schema_id, block_type_id: $block_type_id, is_anonymous: $is_anonymous} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Block Documents
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/filter
# operationId: read_block_documents_api_accounts__account_id__workspaces__workspace_id__block_documents_filter_post
export def "accounts-workspaces-block-documents-filter post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --block-documents: any
  --block-types: any
  --block-schemas: any
  --include-secrets: string@bool-completer # Whether to include sensitive values in the block document. (default: false)
  --body-sort: any # default: NAME_ASC
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: any, data: record, block_schema_id: string, block_schema: any, block_type_id: string, block_type_name: any, block_type: any, block_document_references: record, is_anonymous: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/filter")
  let body = {block_documents: $block_documents, block_types: $block_types, block_schemas: $block_schemas, include_secrets: $include_secrets, sort: $body_sort, offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Block Documents
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/count
# operationId: count_block_documents_api_accounts__account_id__workspaces__workspace_id__block_documents_count_post
export def "accounts-workspaces-block-documents-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --block-documents: any
  --block-types: any
  --block-schemas: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/count")
  let body = {block_documents: $block_documents, block_types: $block_types, block_schemas: $block_schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Block Document By Id
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/{id}
# operationId: read_block_document_by_id_api_accounts__account_id__workspaces__workspace_id__block_documents__id__get
export def "accounts-workspaces-block-documents get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-secrets: string@bool-completer # Whether to include sensitive values in the block document. (default: false)
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: any, data: record, block_schema_id: string, block_schema: any, block_type_id: string, block_type_name: any, block_type: any, block_document_references: record, is_anonymous: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_secrets" $include_secrets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/($id)" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Block Document
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/{id}
# operationId: delete_block_document_api_accounts__account_id__workspaces__workspace_id__block_documents__id__delete
export def "accounts-workspaces-block-documents delete" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Block Document Data
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/{id}
# operationId: update_block_document_data_api_accounts__account_id__workspaces__workspace_id__block_documents__id__patch
export def "accounts-workspaces-block-documents patch" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --block-schema-id: any # A block schema ID
  --data: record # The block document's data
  --merge-existing-data: string@bool-completer # default: true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/($id)")
  let body = {block_schema_id: $block_schema_id, data: $data, merge_existing_data: $merge_existing_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Block Document Access
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/{id}/access
# operationId: read_block_document_access_api_accounts__account_id__workspaces__workspace_id__block_documents__id__access_get
export def "accounts-workspaces-block-documents-access get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<manage_actors: table<id: any, name: string, email: any, type: string>, view_actors: table<id: any, name: string, email: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/($id)/access")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Block Document Access
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/{id}/access
# operationId: set_block_document_access_api_accounts__account_id__workspaces__workspace_id__block_documents__id__access_put
# --access_control shape: {manage_actor_ids: list, view_actor_ids: list, manage_team_ids?: list, view_team_ids?: list}
export def "accounts-workspaces-block-documents-access put" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  access_control: record # Data used to replace the existing deployment access. — shape: {manage_actor_ids: list, view_actor_ids: list, manage_team_ids?: list, view_team_ids?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/($id)/access")
  let body = {access_control: $access_control} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Actors Block Document Access
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_documents/my-access
# operationId: read_actors_block_document_access_api_accounts__account_id__workspaces__workspace_id__block_documents_my_access_post
export def "accounts-workspaces-block-documents-my-access post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  block_document_ids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_documents/my-access")
  let body = {block_document_ids: $block_document_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Variable
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/variables/
# operationId: create_variable_api_accounts__account_id__workspaces__workspace_id__variables__post
export def "accounts-workspaces-variables post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  name: string # The name of the variable
  value: any # The value of the variable
  --tags: any # A list of variable tags
]: any -> record<id: string, created: any, updated: any, name: string, value: any, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/")
  let body = {name: $name, value: $value, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Variable
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/variables/{id}
# operationId: read_variable_api_accounts__account_id__workspaces__workspace_id__variables__id__get
export def "accounts-workspaces-variables get" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, value: any, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Variable
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/variables/{id}
# operationId: update_variable_api_accounts__account_id__workspaces__workspace_id__variables__id__patch
export def "accounts-workspaces-variables patch" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --name: any # The name of the variable
  --value: any # The value of the variable
  --tags: any # A list of variable tags
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/($id)")
  let body = {name: $name, value: $value, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Variable
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/variables/{id}
# operationId: delete_variable_api_accounts__account_id__workspaces__workspace_id__variables__id__delete
export def "accounts-workspaces-variables delete" [
  id: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Variable By Name
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/variables/name/{name}
# operationId: read_variable_by_name_api_accounts__account_id__workspaces__workspace_id__variables_name__name__get
export def "accounts-workspaces-variables-name get" [
  name: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, value: any, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/name/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Variable By Name
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/variables/name/{name}
# operationId: update_variable_by_name_api_accounts__account_id__workspaces__workspace_id__variables_name__name__patch
export def "accounts-workspaces-variables-name patch" [
  name: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-name: any # The name of the variable
  --value: any # The value of the variable
  --tags: any # A list of variable tags
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/name/($name)")
  let body = {name: $body_name, value: $value, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Variable By Name
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/variables/name/{name}
# operationId: delete_variable_by_name_api_accounts__account_id__workspaces__workspace_id__variables_name__name__delete
export def "accounts-workspaces-variables-name delete" [
  name: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/name/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Variables
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/variables/filter
# operationId: read_variables_api_accounts__account_id__workspaces__workspace_id__variables_filter_post
export def "accounts-workspaces-variables-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --offset: int # default: 0
  --body-variables: any
  --body-sort: string@sort-completer # Defines variables sorting options.
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, value: any, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/filter")
  let body = {offset: $offset, variables: $body_variables, sort: $body_sort, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Variables
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/variables/count
# operationId: count_variables_api_accounts__account_id__workspaces__workspace_id__variables_count_post
export def "accounts-workspaces-variables-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-variables: any
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/variables/count")
  let body = {variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Preview Work Pool Configuration
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/configuration/preview
# operationId: preview_work_pool_configuration_api_accounts__account_id__workspaces__workspace_id__work_pools_configuration_preview_post
export def "accounts-workspaces-work-pools-configuration-preview post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  base_job_template: any
  type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/configuration/preview")
  let body = {base_job_template: $base_job_template, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Work Pool
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/
# operationId: create_work_pool_api_accounts__account_id__workspaces__workspace_id__work_pools__post
# --storage_configuration shape: {bundle_upload_step?: any, bundle_execution_step?: any, default_result_storage_block_id?: any}
export def "accounts-workspaces-work-pools post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  name: string # The name of the work pool.
  --description: any # The work pool description.
  --type: string # The work pool type. (default: prefect-agent)
  --base-job-template: record # The work pool's base job template.
  --is-paused: string@bool-completer # Pausing the work pool stops the delivery of all work. (default: false)
  --concurrency-limit: any # A concurrency limit for the work pool.
  --storage-configuration: record # A representation of a work pool's storage configuration — shape: {bundle_upload_step?: any, bundle_execution_step?: any, default_result_storage_block_id?: any}
]: any -> record<id: string, created: any, updated: any, name: string, description: any, type: string, base_job_template: record, is_paused: bool, concurrency_limit: any, is_push_pool: bool, is_mex_pool: bool, status: any, default_queue_id: string, storage_configuration: record<bundle_upload_step: any, bundle_execution_step: any, default_result_storage_block_id: any>, last_polled: any, created_by: any, updated_by: any, active_slots: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/")
  let body = {name: $name, description: $description, type: $type, base_job_template: $base_job_template, is_paused: $is_paused, concurrency_limit: $concurrency_limit, storage_configuration: $storage_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Work Pool
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{name}
# operationId: read_work_pool_api_accounts__account_id__workspaces__workspace_id__work_pools__name__get
export def "accounts-workspaces-work-pools get" [
  workspace_id: string
  name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, description: any, type: string, base_job_template: record, is_paused: bool, concurrency_limit: any, is_push_pool: bool, is_mex_pool: bool, status: any, default_queue_id: string, storage_configuration: record<bundle_upload_step: any, bundle_execution_step: any, default_result_storage_block_id: any>, last_polled: any, created_by: any, updated_by: any, active_slots: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Work Pool
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{name}
# operationId: update_work_pool_api_accounts__account_id__workspaces__workspace_id__work_pools__name__patch
# --storage_configuration shape: {bundle_upload_step?: any, bundle_execution_step?: any, default_result_storage_block_id?: any}
export def "accounts-workspaces-work-pools patch" [
  name: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --description: any
  --is-paused: any
  --base-job-template: record
  --concurrency-limit: any
  --storage-configuration: record # A representation of a work pool's storage configuration — shape: {bundle_upload_step?: any, bundle_execution_step?: any, default_result_storage_block_id?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($name)")
  let body = {description: $description, is_paused: $is_paused, base_job_template: $base_job_template, concurrency_limit: $concurrency_limit, storage_configuration: $storage_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Work Pool
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{name}
# operationId: delete_work_pool_api_accounts__account_id__workspaces__workspace_id__work_pools__name__delete
export def "accounts-workspaces-work-pools delete" [
  account_id: string
  workspace_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Work Pools
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/filter
# operationId: read_work_pools_api_accounts__account_id__workspaces__workspace_id__work_pools_filter_post
export def "accounts-workspaces-work-pools-filter post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --work-pools: any
  --offset: int # default: 0
  --body-sort: string@sort-completer-9 # Defines work pool sorting options.
  --exclude-base-job-template: string@bool-completer # If True, exclude base_job_template from responses to reduce payload size. Use when listing work pools and the full template is not needed. (default: false)
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, description: any, type: string, base_job_template: record, is_paused: bool, concurrency_limit: any, is_push_pool: bool, is_mex_pool: bool, status: any, default_queue_id: string, storage_configuration: record<bundle_upload_step: any, bundle_execution_step: any, default_result_storage_block_id: any>, last_polled: any, created_by: any, updated_by: any, active_slots: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/filter")
  let body = {work_pools: $work_pools, offset: $offset, sort: $body_sort, exclude_base_job_template: $exclude_base_job_template, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Paginate Work Pools
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/paginate
# operationId: paginate_work_pools_api_accounts__account_id__workspaces__workspace_id__work_pools_paginate_post
export def "accounts-workspaces-work-pools-paginate post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --work-pools: any
  --page: int # default: 1
  --body-sort: string@sort-completer-9 # Defines work pool sorting options.
  --include-base-job-template: string@bool-completer # If True, include base_job_template in responses. Defaults to False to reduce payload size when the full template is not needed. (default: false)
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, name: string, description: any, type: string, base_job_template: record, is_paused: bool, concurrency_limit: any, is_push_pool: bool, is_mex_pool: bool, status: any, default_queue_id: string, storage_configuration: record, last_polled: any, created_by: any, updated_by: any, active_slots: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/paginate")
  let body = {work_pools: $work_pools, page: $page, sort: $body_sort, include_base_job_template: $include_base_job_template, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Work Pools
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/count
# operationId: count_work_pools_api_accounts__account_id__workspaces__workspace_id__work_pools_count_post
# --work_pools shape: {operator?: "and_"|"or_", id?: any, name?: any, type?: any, paused?: any, status?: any, created_by?: any, updated_by?: any}
export def "accounts-workspaces-work-pools-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --work-pools: record # shape: {operator?: "and_"|"or_", id?: any, name?: any, type?: any, paused?: any, status?: any, created_by?: any, updated_by?: any}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/count")
  let body = {work_pools: $work_pools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Scheduled Flow Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{name}/get_scheduled_flow_runs
# operationId: get_scheduled_flow_runs_api_accounts__account_id__workspaces__workspace_id__work_pools__name__get_scheduled_flow_runs_post
export def "accounts-workspaces-work-pools-get-scheduled-flow-runs post" [
  account_id: string
  workspace_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --work-queue-names: list # The names of work pool queues
  --scheduled-before: string # The maximum time to look for scheduled flow runs (format: date-time)
  --scheduled-after: string # The minimum time to look for scheduled flow runs (format: date-time)
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<work_pool_id: string, work_queue_id: string, flow_run: record<id: string, created: any, updated: any, name: string, flow_id: string, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record, tags: list, labels: any, parent_task_run_id: any, state_type: any, state_name: any, state_timestamp: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, cancelled_by: any, work_queue_id: any, work_queue: any, flow: any, state: any, job_variables: any, estimated_run_time: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($name)/get_scheduled_flow_runs")
  let body = {work_queue_names: $work_queue_names, scheduled_before: $scheduled_before, scheduled_after: $scheduled_after, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Work Pool Access
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{name}/access
# operationId: read_work_pool_access_api_accounts__account_id__workspaces__workspace_id__work_pools__name__access_get
export def "accounts-workspaces-work-pools-access get" [
  name: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<manage_actors: table<id: any, name: string, email: any, type: string>, run_actors: table<id: any, name: string, email: any, type: string>, view_actors: table<id: any, name: string, email: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($name)/access")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Work Pool Access
#
# PUT /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{name}/access
# operationId: set_work_pool_access_api_accounts__account_id__workspaces__workspace_id__work_pools__name__access_put
# --access_control shape: {manage_actor_ids: list, run_actor_ids: list, view_actor_ids: list, manage_team_ids?: list, run_team_ids?: list, view_team_ids?: list}
export def "accounts-workspaces-work-pools-access put" [
  account_id: string
  workspace_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  access_control: record # Data used to replace the existing work pool access. — shape: {manage_actor_ids: list, run_actor_ids: list, view_actor_ids: list, manage_team_ids?: list, run_team_ids?: list, view_team_ids?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($name)/access")
  let body = {access_control: $access_control} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Actors Work Pool Access
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/my-access
# operationId: read_actors_work_pool_access_api_accounts__account_id__workspaces__workspace_id__work_pools_my_access_post
export def "accounts-workspaces-work-pools-my-access post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --work-pool-ids: list # default: []
  --work-pool-names: list # default: []
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/my-access")
  let body = {work_pool_ids: $work_pool_ids, work_pool_names: $work_pool_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Work Queue
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/queues
# operationId: create_work_queue_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__queues_post
@deprecated --flag filter
export def "accounts-workspaces-work-pools-queues post" [
  workspace_id: string
  work_pool_name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  name: string # The name of the work queue.
  --description: any # An optional description for the work queue. (default: )
  --is-paused: string@bool-completer # Whether or not the work queue is paused. (default: false)
  --concurrency-limit: any # The work queue's concurrency limit.
  --priority: any # The queue's priority. Lower values are higher priority (1 is the highest).
  --filter: any # DEPRECATED: Filter criteria for the work queue. (DEPRECATED)
]: any -> record<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/queues")
  let body = {name: $name, description: $description, is_paused: $is_paused, concurrency_limit: $concurrency_limit, priority: $priority, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Work Queue
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/queues/{name}
# operationId: read_work_queue_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__queues__name__get
export def "accounts-workspaces-work-pools-queues get" [
  workspace_id: string
  work_pool_name: string
  name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/queues/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Work Queue
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/queues/{name}
# operationId: update_work_queue_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__queues__name__patch
@deprecated --flag filter
export def "accounts-workspaces-work-pools-queues patch" [
  work_pool_name: string
  name: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-name: any
  --description: any
  --is-paused: string@bool-completer # Whether or not the work queue is paused. (default: false)
  --concurrency-limit: any
  --priority: any
  --last-polled: any
  --filter: any # DEPRECATED: Filter criteria for the work queue. (DEPRECATED)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/queues/($name)")
  let body = {name: $body_name, description: $description, is_paused: $is_paused, concurrency_limit: $concurrency_limit, priority: $priority, last_polled: $last_polled, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Work Queue
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/queues/{name}
# operationId: delete_work_queue_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__queues__name__delete
export def "accounts-workspaces-work-pools-queues delete" [
  workspace_id: string
  work_pool_name: string
  name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/queues/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Work Queues
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/queues/filter
# operationId: read_work_queues_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__queues_filter_post
export def "accounts-workspaces-work-pools-queues-filter post" [
  workspace_id: string
  work_pool_name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --work-queues: any
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/queues/filter")
  let body = {work_queues: $work_queues, offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Paginate Work Queues
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/queues/paginate
# operationId: paginate_work_queues_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__queues_paginate_post
export def "accounts-workspaces-work-pools-queues-paginate post" [
  workspace_id: string
  work_pool_name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --work-queues: any
  --page: int # default: 1
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/queues/paginate")
  let body = {work_queues: $work_queues, page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Worker Heartbeat
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/workers/heartbeat
# operationId: worker_heartbeat_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__workers_heartbeat_post
export def "accounts-workspaces-work-pools-workers-heartbeat post" [
  work_pool_name: string
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  name: string # The worker process name
  --heartbeat-interval-seconds: any # The worker's heartbeat interval in seconds
  --return-id: string@bool-completer # Whether to return the worker ID. If False, returns 204. (default: false)
  --metadata: any # The worker's metadata
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/workers/heartbeat")
  let body = {name: $name, heartbeat_interval_seconds: $heartbeat_interval_seconds, return_id: $return_id, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Workers
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/workers/filter
# operationId: read_workers_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__workers_filter_post
export def "accounts-workspaces-work-pools-workers-filter post" [
  workspace_id: string
  work_pool_name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --workers: any
  --body-sort: string@sort-completer-10 # Defines flow sorting options.
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, work_pool_id: string, last_heartbeat_time: any, status: string, heartbeat_interval_seconds: any, client_version: any, metadata_: any, created_by: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/workers/filter")
  let body = {workers: $workers, sort: $body_sort, offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Paginate Workers
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/workers/paginate
# operationId: paginate_workers_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__workers_paginate_post
export def "accounts-workspaces-work-pools-workers-paginate post" [
  workspace_id: string
  work_pool_name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --workers: any
  --body-sort: string@sort-completer-10 # Defines flow sorting options.
  --page: int # default: 1
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, name: string, work_pool_id: string, last_heartbeat_time: any, status: string, heartbeat_interval_seconds: any, client_version: any, metadata_: any, created_by: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/workers/paginate")
  let body = {workers: $workers, sort: $body_sort, page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Worker
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/workers/{worker_id}
# operationId: read_worker_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__workers__worker_id__get
export def "accounts-workspaces-work-pools-workers get" [
  workspace_id: string
  work_pool_name: string
  worker_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, work_pool_id: string, last_heartbeat_time: any, status: string, heartbeat_interval_seconds: any, client_version: any, metadata_: any, created_by: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/workers/($worker_id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Worker
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{work_pool_name}/workers/{name}
# operationId: delete_worker_api_accounts__account_id__workspaces__workspace_id__work_pools__work_pool_name__workers__name__delete
export def "accounts-workspaces-work-pools-workers delete" [
  workspace_id: string
  work_pool_name: string
  name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($work_pool_name)/workers/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Work Pool Concurrency Status
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_pools/{name}/concurrency_status
# operationId: read_work_pool_concurrency_status_api_accounts__account_id__workspaces__workspace_id__work_pools__name__concurrency_status_post
export def "accounts-workspaces-work-pools-concurrency-status post" [
  workspace_id: string
  name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --page: int # default: 1
  --flow-run-limit: int # default: 10
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<active_slots: any, concurrency_limit: any, queues: table<queue_id: string, queue_name: string, active_slots: any, concurrency_limit: any, flow_runs: list, flow_run_count: any>, pool_slots: table<id: string, name: string, state_type: any, state_name: any, start_time: any, state_timestamp: any, time_in_current_state: any>, count: any, limit: int, pages: any, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_pools/($name)/concurrency_status")
  let body = {page: $page, flow_run_limit: $flow_run_limit, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Work Queue
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/
# operationId: create_work_queue_api_accounts__account_id__workspaces__workspace_id__work_queues__post
@deprecated --flag filter
export def "accounts-workspaces-work-queues post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  name: string # The name of the work queue.
  --description: any # An optional description for the work queue. (default: )
  --is-paused: string@bool-completer # Whether or not the work queue is paused. (default: false)
  --concurrency-limit: any # The work queue's concurrency limit.
  --priority: any # The queue's priority. Lower values are higher priority (1 is the highest).
  --filter: any # DEPRECATED: Filter criteria for the work queue. (DEPRECATED)
]: any -> record<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/")
  let body = {name: $name, description: $description, is_paused: $is_paused, concurrency_limit: $concurrency_limit, priority: $priority, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Work Queue
#
# PATCH /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/{id}
# operationId: update_work_queue_api_accounts__account_id__workspaces__workspace_id__work_queues__id__patch
@deprecated --flag filter
export def "accounts-workspaces-work-queues patch" [
  id: string
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --name: any
  --description: any
  --is-paused: string@bool-completer # Whether or not the work queue is paused. (default: false)
  --concurrency-limit: any
  --priority: any
  --last-polled: any
  --filter: any # DEPRECATED: Filter criteria for the work queue. (DEPRECATED)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/($id)")
  let body = {name: $name, description: $description, is_paused: $is_paused, concurrency_limit: $concurrency_limit, priority: $priority, last_polled: $last_polled, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Work Queue
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/{id}
# operationId: read_work_queue_api_accounts__account_id__workspaces__workspace_id__work_queues__id__get
export def "accounts-workspaces-work-queues get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Work Queue
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/{id}
# operationId: delete_work_queue_api_accounts__account_id__workspaces__workspace_id__work_queues__id__delete
export def "accounts-workspaces-work-queues delete" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Work Queue By Name
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/name/{name}
# operationId: read_work_queue_by_name_api_accounts__account_id__workspaces__workspace_id__work_queues_name__name__get
export def "accounts-workspaces-work-queues-name get" [
  workspace_id: string
  name: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/name/($name)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Work Queue Runs
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/{id}/get_runs
# operationId: read_work_queue_runs_api_accounts__account_id__workspaces__workspace_id__work_queues__id__get_runs_post
export def "accounts-workspaces-work-queues-get-runs post" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-ui: string # A header to indicate this request came from the Prefect UI.
  --x-prefect-api-version: string
  --scheduled-before: string # Only flow runs scheduled to start before this time will be returned. (format: date-time)
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, flow_id: string, flow_name: any, flow_version: any, state_id: any, deployment_id: any, deployment_version_id: any, deployment_version_info: any, deployment_version: any, work_queue_id: any, work_queue_name: any, parameters: record, idempotency_key: any, context: record, empirical_policy: record<max_retries: int, retry_delay_seconds: float, retries: any, retry_delay: any, pause_keys: any, resuming: any, retry_type: any>, tags: list<string>, labels: any, parent_task_run_id: any, state_type: any, state_name: any, run_count: int, expected_start_time: any, next_scheduled_start_time: any, start_time: any, end_time: any, total_run_time: float, estimated_run_time: float, estimated_start_time_delta: float, auto_scheduled: bool, infrastructure_document_id: any, infrastructure_pid: any, created_by: any, work_pool_id: any, work_pool_name: any, state: any, job_variables: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/($id)/get_runs")
  let body = {scheduled_before: $scheduled_before, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-ui": $x_prefect_ui, "x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Work Queues
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/filter
# operationId: read_work_queues_api_accounts__account_id__workspaces__workspace_id__work_queues_filter_post
export def "accounts-workspaces-work-queues-filter post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --offset: int # default: 0
  --work-queues: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/filter")
  let body = {offset: $offset, work_queues: $work_queues, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Paginate Work Queues
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/paginate
# operationId: paginate_work_queues_api_accounts__account_id__workspaces__workspace_id__work_queues_paginate_post
export def "accounts-workspaces-work-queues-paginate post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --page: int # default: 1
  --work-queues: any
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<results: table<id: string, created: any, updated: any, name: string, description: any, is_paused: bool, concurrency_limit: any, priority: int, work_pool_id: any, filter: any, last_polled: any, status: any, work_pool: any, created_by: any, updated_by: any, active_slots: any, work_pool_name: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/paginate")
  let body = {page: $page, work_queues: $work_queues, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Work Queue Status
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/{id}/status
# operationId: read_work_queue_status_api_accounts__account_id__workspaces__workspace_id__work_queues__id__status_get
export def "accounts-workspaces-work-queues-status get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<healthy: bool, late_runs_count: int, last_polled: any, health_check_policy: record<maximum_late_runs: any, maximum_seconds_since_last_polled: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/($id)/status")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Work Queue Concurrency Status
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/work_queues/{id}/concurrency_status
# operationId: read_work_queue_concurrency_status_api_accounts__account_id__workspaces__workspace_id__work_queues__id__concurrency_status_post
export def "accounts-workspaces-work-queues-concurrency-status post" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --page: int # default: 1
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> record<active_slots: any, concurrency_limit: any, flow_runs: table<id: string, name: string, state_type: any, state_name: any, start_time: any, state_timestamp: any, time_in_current_state: any>, count: any, limit: int, pages: any, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/work_queues/($id)/concurrency_status")
  let body = {page: $page, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Block Schema
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_schemas/
# operationId: create_block_schema_api_accounts__account_id__workspaces__workspace_id__block_schemas__post
export def "accounts-workspaces-block-schemas post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-fields: record # The block schema's field schema
  block_type_id: string # A block type ID (format: uuid)
  --capabilities: list # A list of Block capabilities
  --version: string # Human readable identifier for the block schema (default: non-versioned)
]: any -> record<id: string, created: any, updated: any, checksum: string, fields: record, block_type_id: any, block_type: any, capabilities: list<string>, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_schemas/")
  let body = {fields: $body_fields, block_type_id: $block_type_id, capabilities: $capabilities, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Block Schema
#
# DELETE /api/accounts/{account_id}/workspaces/{workspace_id}/block_schemas/{id}
# operationId: delete_block_schema_api_accounts__account_id__workspaces__workspace_id__block_schemas__id__delete
export def "accounts-workspaces-block-schemas delete" [
  account_id: string
  workspace_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_schemas/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Block Schema By Id
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_schemas/{id}
# operationId: read_block_schema_by_id_api_accounts__account_id__workspaces__workspace_id__block_schemas__id__get
export def "accounts-workspaces-block-schemas get" [
  workspace_id: string
  id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, checksum: string, fields: record, block_type_id: any, block_type: any, capabilities: list<string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_schemas/($id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Block Schemas
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/block_schemas/filter
# operationId: read_block_schemas_api_accounts__account_id__workspaces__workspace_id__block_schemas_filter_post
export def "accounts-workspaces-block-schemas-filter post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --block-schemas: any
  --offset: int # default: 0
  --limit: int # Defaults to PREFECT_ORION_API_DEFAULT_LIMIT if not provided.
]: any -> table<id: string, created: any, updated: any, checksum: string, fields: record, block_type_id: any, block_type: any, capabilities: list<string>, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_schemas/filter")
  let body = {block_schemas: $block_schemas, offset: $offset, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Block Schema By Checksum
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_schemas/checksum/{checksum}
# operationId: read_block_schema_by_checksum_api_accounts__account_id__workspaces__workspace_id__block_schemas_checksum__checksum__get
export def "accounts-workspaces-block-schemas-checksum get" [
  workspace_id: string
  checksum: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # Version of block schema. If not provided the most recently created block schema with the matching checksum will be returned.
  --x-prefect-api-version: string
]: nothing -> record<id: string, created: any, updated: any, checksum: string, fields: record, block_type_id: any, block_type: any, capabilities: list<string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_schemas/checksum/($checksum)" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Available Block Capabilities
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/block_capabilities/
# operationId: read_available_block_capabilities_api_accounts__account_id__workspaces__workspace_id__block_capabilities__get
export def "accounts-workspaces-block-capabilities get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/block_capabilities/")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Flow Run Resource Metrics
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/metrics/flow-runs/{flow_run_id}
# operationId: read_flow_run_resource_metrics_api_accounts__account_id__workspaces__workspace_id__metrics_flow_runs__flow_run_id__get
export def "accounts-workspaces-metrics-flow-runs get" [
  workspace_id: string
  account_id: string
  flow_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric-names: string # Filter to specific metric names
  --start-time: string # Start of time range filter
  --end-time: string # End of time range filter
  --x-prefect-api-version: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metric_names" $metric_names "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/metrics/flow-runs/($flow_run_id)" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Deployment Resource Peaks Endpoint
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/metrics/deployments/{deployment_id}/resource-peaks
# operationId: read_deployment_resource_peaks_endpoint_api_accounts__account_id__workspaces__workspace_id__metrics_deployments__deployment_id__resource_peaks_get
export def "accounts-workspaces-metrics-deployments-resource-peaks get" [
  workspace_id: string
  account_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: string # Start of time range filter
  --end-time: string # End of time range filter
  --x-prefect-api-version: string
]: nothing -> record<peaks: table<metric_name: string, unit: string, max_value: float, flow_run_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/metrics/deployments/($deployment_id)/resource-peaks" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Available Flow Run Metrics
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/metrics/flow-runs/{flow_run_id}/names
# operationId: list_available_flow_run_metrics_api_accounts__account_id__workspaces__workspace_id__metrics_flow_runs__flow_run_id__names_get
export def "accounts-workspaces-metrics-flow-runs-names get" [
  workspace_id: string
  account_id: string
  flow_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/metrics/flow-runs/($flow_run_id)/names")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Spans
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/traces/{trace_id}
# operationId: read_spans_api_accounts__account_id__workspaces__workspace_id__traces__trace_id__get
export def "accounts-workspaces-traces get" [
  workspace_id: string
  trace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-span-id: string # Filter by parent span ID (None = all spans)
  --depth: string # Filter by depth level (None = all depths)
  --entities: string # Filter by entity types (e.g., 'flow-run', 'task-run', 'artifact')
  --state-types: string # Filter by state types (e.g., 'COMPLETED', 'RUNNING', 'FAILED')
  --state-names: string # Filter by state names (e.g., 'Completed', 'Running', 'Failed')
  --tags: string # Filter by tags (OR logic - span matches if it has ANY of the specified tags)
  --qp-query: string # Text search query across span content (space=OR, -/!=NOT, quotes=phrases)
  --limit: int # Number of results to return (default: 100)
  --cursor: string # Pagination cursor from previous response
  --direction: string@direction-completer # Pagination direction (default: asc)
  --x-prefect-api-version: string
]: nothing -> record<spans: table<span_id: any, trace_id: any, parent_span_id: any, path: list, start_time: any, end_time: any, running_time: any, published: any, name: string, span_type: string, state_type: any, state_name: any, version: int, attributes: record, tags: list, has_children: bool, child_count: int, child_state_counts: record>, next_cursor: any, prev_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_span_id" $parent_span_id "scalar") (serialize-qp "depth" $depth "scalar") (serialize-qp "entities" $entities "scalar") (serialize-qp "state_types" $state_types "scalar") (serialize-qp "state_names" $state_names "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/traces/($trace_id)" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Span Context
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/traces/{trace_id}/context/{span_id}
# operationId: read_span_context_api_accounts__account_id__workspaces__workspace_id__traces__trace_id__context__span_id__get
export def "accounts-workspaces-traces-context get" [
  workspace_id: string
  trace_id: string
  span_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --context-size: int # Number of siblings before/after to include (default: 10)
  --x-prefect-api-version: string
]: nothing -> record<spans: table<span_id: any, trace_id: any, parent_span_id: any, path: list, start_time: any, end_time: any, running_time: any, published: any, name: string, span_type: string, state_type: any, state_name: any, version: int, attributes: record, tags: list, has_children: bool, child_count: int, child_state_counts: record>, next_cursor: any, prev_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context_size" $context_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/traces/($trace_id)/context/($span_id)" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Trace Observed States
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/traces/{trace_id}/observed-states
# operationId: read_trace_observed_states_api_accounts__account_id__workspaces__workspace_id__traces__trace_id__observed_states_get
export def "accounts-workspaces-traces-observed-states get" [
  account_id: string
  workspace_id: string
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Prefix search query for state type or name
  --order-by: string@order-by-completer # Order results by name (alphabetically) or recency (most recently seen first)
  --limit: int # Maximum number of results to return (default: 100)
  --x-prefect-api-version: string
]: nothing -> table<state_type: string, state_name: string, first_seen: string, last_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/traces/($trace_id)/observed-states" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Trace Observed Tags
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/traces/{trace_id}/observed-tags
# operationId: read_trace_observed_tags_api_accounts__account_id__workspaces__workspace_id__traces__trace_id__observed_tags_get
export def "accounts-workspaces-traces-observed-tags get" [
  workspace_id: string
  trace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Prefix search query for tag names
  --x-prefect-api-version: string
]: nothing -> table<tag: string, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/traces/($trace_id)/observed-tags" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Single Span
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/traces/{trace_id}/spans/{span_id}
# operationId: read_single_span_api_accounts__account_id__workspaces__workspace_id__traces__trace_id__spans__span_id__get
export def "accounts-workspaces-traces-spans get" [
  workspace_id: string
  trace_id: string
  span_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<span_id: any, trace_id: any, parent_span_id: any, path: list<string>, start_time: any, end_time: any, running_time: any, published: any, name: string, span_type: string, state_type: any, state_name: any, version: int, attributes: record, tags: list<string>, has_children: bool, child_count: int, child_state_counts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/traces/($trace_id)/spans/($span_id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Spans By Ids
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/traces/{trace_id}/spans
# operationId: read_spans_by_ids_api_accounts__account_id__workspaces__workspace_id__traces__trace_id__spans_get
export def "accounts-workspaces-traces-spans list" [
  workspace_id: string
  trace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # List of span IDs to retrieve. Only returns spans that exist and belong to the specified trace. (default: [])
  --x-prefect-api-version: string
]: nothing -> table<span_id: any, trace_id: any, parent_span_id: any, path: list<string>, start_time: any, end_time: any, running_time: any, published: any, name: string, span_type: string, state_type: any, state_name: any, version: int, attributes: record, tags: list<string>, has_children: bool, child_count: int, child_state_counts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/traces/($trace_id)/spans" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lookup Span By Run Id
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/spans/lookup/{run_id}
# operationId: lookup_span_by_run_id_api_accounts__account_id__workspaces__workspace_id__spans_lookup__run_id__get
export def "accounts-workspaces-spans-lookup get" [
  workspace_id: string
  run_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> record<trace_id: string, span_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/spans/lookup/($run_id)")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Span Observed Tags
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/spans/{span_id}/observed-tags
# operationId: read_span_observed_tags_api_accounts__account_id__workspaces__workspace_id__spans__span_id__observed_tags_get
export def "accounts-workspaces-spans-observed-tags get" [
  workspace_id: string
  span_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Prefix search query for tag names
  --x-prefect-api-version: string
]: nothing -> table<tag: string, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/spans/($span_id)/observed-tags" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read Workspace Observed States
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/observed-states
# operationId: read_workspace_observed_states_api_accounts__account_id__workspaces__workspace_id__observed_states_get
export def "accounts-workspaces-observed-states get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Prefix search query for state type or name
  --order-by: string@order-by-completer # Order results by name (alphabetically) or recency (most recently seen first)
  --limit: int # Maximum number of results to return (default: 200)
  --x-prefect-api-version: string
]: nothing -> table<state_type: string, state_name: string, first_seen: string, last_seen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/observed-states" $qp)
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count Deployments By Flow
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/flows/count-deployments
# operationId: count_deployments_by_flow_api_accounts__account_id__workspaces__workspace_id__ui_flows_count_deployments_post
export def "accounts-workspaces-ui-flows-count-deployments post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  flow_ids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/flows/count-deployments")
  let body = {flow_ids: $flow_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Next Runs By Flow
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/flows/next-runs
# operationId: next_runs_by_flow_api_accounts__account_id__workspaces__workspace_id__ui_flows_next_runs_post
export def "accounts-workspaces-ui-flows-next-runs post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  flow_ids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/flows/next-runs")
  let body = {flow_ids: $flow_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow Run History
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/flow_runs/history
# operationId: read_flow_run_history_api_accounts__account_id__workspaces__workspace_id__ui_flow_runs_history_post
export def "accounts-workspaces-ui-flow-runs-history post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-7 # Defines flow run sorting options.
  --limit: int # default: 1000
  --offset: int # default: 0
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
]: any -> table<id: string, state_type: string, timestamp: string, duration: float, lateness: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/flow_runs/history")
  let body = {sort: $body_sort, limit: $limit, offset: $offset, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Flow Run History V2
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/flow_runs/history-v2
# operationId: read_flow_run_history_v2_api_accounts__account_id__workspaces__workspace_id__ui_flow_runs_history_v2_post
export def "accounts-workspaces-ui-flow-runs-history-v2 post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body-sort: string@sort-completer-7 # Defines flow run sorting options.
  --limit: int # default: 5000
  --page: int # default: 1
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
  --work-pools: any
  --work-pool-queues: any
]: any -> record<results: table<id: string, state: string, timestamp: int, duration: float, deployment: any>, count: int, limit: int, pages: int, page: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/flow_runs/history-v2")
  let body = {sort: $body_sort, limit: $limit, page: $page, flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments, work_pools: $work_pools, work_pool_queues: $work_pool_queues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Task Runs By Flow Run
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/flow_runs/count-task-runs
# operationId: count_task_runs_by_flow_run_api_accounts__account_id__workspaces__workspace_id__ui_flow_runs_count_task_runs_post
export def "accounts-workspaces-ui-flow-runs-count-task-runs post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  flow_run_ids: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/flow_runs/count-task-runs")
  let body = {flow_run_ids: $flow_run_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Dashboard Task Run Counts
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/task_runs/dashboard/counts
# operationId: read_dashboard_task_run_counts_api_accounts__account_id__workspaces__workspace_id__ui_task_runs_dashboard_counts_post
# --task_runs shape: {operator?: "and_"|"or_", id?: any, name?: any, tags?: any, state?: any, start_time?: any, end_time?: any, expected_start_time?: any, subflow_runs?: any, flow_run_id?: any}
export def "accounts-workspaces-ui-task-runs-dashboard-counts post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  task_runs: record # Filter task runs. Only task runs matching all criteria will be returned — shape: {operator?: "and_"|"or_", id?: any, name?: any, tags?: any, state?: any, start_time?: any, end_time?: any, expected_start_time?: any, subflow_runs?: any, flow_run_id?: any}
  --flows: any
  --flow-runs: any
  --deployments: any
  --work-pools: any
  --work-queues: any
]: any -> table<completed: int, failed: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/task_runs/dashboard/counts")
  let body = {task_runs: $task_runs, flows: $flows, flow_runs: $flow_runs, deployments: $deployments, work_pools: $work_pools, work_queues: $work_queues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read Task Run Counts By State
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/task_runs/count
# operationId: read_task_run_counts_by_state_api_accounts__account_id__workspaces__workspace_id__ui_task_runs_count_post
export def "accounts-workspaces-ui-task-runs-count post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --flows: any
  --flow-runs: any
  --task-runs: any
  --deployments: any
]: any -> record<COMPLETED: int, PENDING: int, RUNNING: int, FAILED: int, CANCELLED: int, CRASHED: int, PAUSED: int, CANCELLING: int, SCHEDULED: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/task_runs/count")
  let body = {flows: $flows, flow_runs: $flow_runs, task_runs: $task_runs, deployments: $deployments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate Obj
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/schemas/validate
# operationId: validate_obj_api_accounts__account_id__workspaces__workspace_id__ui_schemas_validate_post
export def "accounts-workspaces-ui-schemas-validate post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  schema: record
  values: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/schemas/validate")
  let body = {schema: $schema, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate Schema
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/schemas/validate_schema
# operationId: validate_schema_api_accounts__account_id__workspaces__workspace_id__ui_schemas_validate_schema_post
export def "accounts-workspaces-ui-schemas-validate-schema post" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/schemas/validate_schema")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count Flow Runs By Work Pool
#
# POST /api/accounts/{account_id}/workspaces/{workspace_id}/ui/work_pools/count-flow-runs
# operationId: count_flow_runs_by_work_pool_api_accounts__account_id__workspaces__workspace_id__ui_work_pools_count_flow_runs_post
export def "accounts-workspaces-ui-work-pools-count-flow-runs post" [
  workspace_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
  work_pool_ids: list
  --flow-runs: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/ui/work_pools/count-flow-runs")
  let body = {work_pool_ids: $work_pool_ids, flow_runs: $flow_runs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hello
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/hello
# operationId: hello_api_accounts__account_id__workspaces__workspace_id__hello_get
export def "accounts-workspaces-hello get" [
  account_id: string
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-prefect-api-version: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/hello")
  let extra_headers = {"x-prefect-api-version": $x_prefect_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Health Check
#
# GET /api/accounts/{account_id}/workspaces/{workspace_id}/health
# operationId: health_check_api_accounts__account_id__workspaces__workspace_id__health_get
export def "accounts-workspaces-health get" [
  account_id: any
  workspace_id: any
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
  let full_url = (build-url $base $"/api/accounts/($account_id)/workspaces/($workspace_id)/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
