# Auto-generated client for PlanetScale API vv1
# Source: https://api.planetscale.com/v1/openapi-spec
# Auth: --token flag or $env.PLANETSCALE_API_TOKEN

const BASE_URL = "https://api.planetscale.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PLANETSCALE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.planetscale.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def engine-completer [] { ["mysql" "postgresql"] }
def kind-completer [] { ["mysql" "postgresql"] }
def target-completer [] { ["development" "production"] }
def retention-unit-completer [] { ["day" "hour" "month" "week" "year"] }
def frequency-unit-completer [] { ["day" "hour" "month" "week"] }
def order-completer [] { ["asc" "desc"] }
def seed-data-completer [] { ["last_successful_backup"] }
def state-completer [] { ["canceled" "failed" "ignored" "pending" "running" "success"] }
def role-completer [] { ["admin" "reader" "readwriter" "writer"] }
def mode-completer [] { ["enforce" "off" "warn"] }
def kind-completer-1 [] { ["each" "match"] }
def state-completer-1 [] { ["closed"] }
def state-completer-2 [] { ["approved" "commented"] }
def state-completer-3 [] { ["closed" "open"] }
def on-ddl-completer [] { ["EXEC" "EXEC_IGNORE" "IGNORE" "STOP"] }
def grant-type-completer [] { ["authorization_code" "refresh_token"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "organizations organizations" } } | get name | first)
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

# List organizations
#
# GET /organizations
# operationId: list_organizations
export def "organizations organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, billing_email: string, created_at: string, updated_at: string, plan: string, valid_billing_info: bool, sso: bool, sso_directory: bool, single_tenancy: bool, managed_tenancy: bool, has_past_due_invoices: bool, database_count: int, sso_portal_url: string, features: record, idp_managed_roles: bool, invoice_budget_amount: string, keyspace_shard_limit: int, has_card: bool, payment_info_required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an organization
#
# GET /organizations/{organization}
# operationId: get_organization
export def "organizations organization-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, billing_email: string, created_at: string, updated_at: string, plan: string, valid_billing_info: bool, sso: bool, sso_directory: bool, single_tenancy: bool, managed_tenancy: bool, has_past_due_invoices: bool, database_count: int, sso_portal_url: string, features: record, idp_managed_roles: bool, invoice_budget_amount: string, keyspace_shard_limit: int, has_card: bool, payment_info_required: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization
#
# PATCH /organizations/{organization}
# operationId: update_organization
export def "organizations organization-by-organization-1" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-email: string # The billing email for the organization
  --idp-managed-roles: oneof<nothing, bool> # Whether or not the IdP provider is be responsible for managing roles in PlanetScale
  --invoice-budget-amount: int # The expected monthly budget for the organization
]: any -> record<id: string, name: string, billing_email: string, created_at: string, updated_at: string, plan: string, valid_billing_info: bool, sso: bool, sso_directory: bool, single_tenancy: bool, managed_tenancy: bool, has_past_due_invoices: bool, database_count: int, sso_portal_url: string, features: record, idp_managed_roles: bool, invoice_budget_amount: string, keyspace_shard_limit: int, has_card: bool, payment_info_required: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)")
  let body = {billing_email: $billing_email, idp_managed_roles: $idp_managed_roles, invoice_budget_amount: $invoice_budget_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List audit logs
#
# GET /organizations/{organization}/audit-log
# operationId: list_audit_logs
export def "organizations-audit-log logs" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --starting-after: string # If provided, returns results after the specified cursor
  --ending-before: string # If provided, returns results before the specified cursor
  --limit: int # If provided, specifies the number of returned results (max 100) (default: 25)
]: nothing -> record<type: string, has_next: bool, has_prev: bool, cursor_start: string, cursor_end: string, data: table<id: string, actor_id: string, actor_type: string, auditable_id: string, auditable_type: string, target_id: string, target_type: string, location: string, target_display_name: string, audit_action: string, action: string, actor_display_name: string, auditable_display_name: string, remote_ip: string, created_at: string, updated_at: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/audit-log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available cluster sizes
#
# GET /organizations/{organization}/cluster-size-skus
# operationId: list_cluster_size_skus
export def "organizations-cluster-size-skus skus" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine: string@engine-completer # The database engine to filter by. Defaults to 'mysql'.
  --rates: oneof<nothing, bool> # Whether to include pricing rates in the response. Defaults to false.
  --region: string # The region slug to get rates for. If not specified, uses the organization's default region.
]: nothing -> table<name: string, display_name: string, cpu: string, storage: int, ram: int, metal: bool, enabled: bool, provider: string, default_vtgate: string, default_vtgate_rate: float, replica_rate: float, rate: float, sort_order: int, architecture: string, development: bool, production: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "engine" $engine "scalar") (serialize-qp "rates" $rates "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/cluster-size-skus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List databases
#
# GET /organizations/{organization}/databases
# operationId: list_databases
export def "organizations-databases databases" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term to filter databases by name
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, url: string, branches_url: string, branches_count: int, open_schema_recommendations_count: int, development_branches_count: int, production_branches_count: int, issues_count: int, multiple_admins_required_for_deletion: bool, ready: bool, at_backup_restore_branches_limit: bool, at_development_branch_usage_limit: bool, data_import: record, region: record, html_url: string, name: string, state: string, sharded: bool, default_branch_shard_count: int, default_branch_read_only_regions_count: int, default_branch_table_count: int, default_branch: string, require_approval_for_deploy: bool, resizing: bool, resize_queued: bool, config_changing: bool, config_change_queued: bool, allow_data_branching: bool, foreign_keys_enabled: bool, automatic_migrations: bool, restrict_branch_region: bool, insights_raw_queries: bool, plan: string, insights_enabled: bool, production_branch_web_console: bool, migration_table_name: string, migration_framework: string, created_at: string, updated_at: string, schema_last_updated_at: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a database
#
# POST /organizations/{organization}/databases
# operationId: create_database
# --storage shape: {minimum_storage_bytes?: int, maximum_storage_bytes?: int}
export def "organizations-databases database-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the database
  --region: string # The region the database will be deployed in. If left blank, defaults to the organization's default region.
  cluster_size: string # The database cluster size name (e.g., 'PS_10', 'PS_80'). Use the 'List available cluster sizes' endpoint to get available options for your organization. /v1/organizations/:organization/cluster-size-skus
  --replicas: int # The number of replicas for the database. 0 for non-HA, 2+ for HA.
  --kind: string@kind-completer # The kind of database to create.
  --major-version: string # For PostgreSQL databases, the PostgreSQL major version to use for the database. Defaults to the latest available major version.
  --storage: record # shape: {minimum_storage_bytes?: int, maximum_storage_bytes?: int}
]: any -> record<id: string, url: string, branches_url: string, branches_count: int, open_schema_recommendations_count: int, development_branches_count: int, production_branches_count: int, issues_count: int, multiple_admins_required_for_deletion: bool, ready: bool, at_backup_restore_branches_limit: bool, at_development_branch_usage_limit: bool, data_import: record<state: string, import_check_errors: string, started_at: string, finished_at: string, data_source: record<hostname: string, port: int, database: string>>, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, html_url: string, name: string, state: string, sharded: bool, default_branch_shard_count: int, default_branch_read_only_regions_count: int, default_branch_table_count: int, default_branch: string, require_approval_for_deploy: bool, resizing: bool, resize_queued: bool, config_changing: bool, config_change_queued: bool, allow_data_branching: bool, foreign_keys_enabled: bool, automatic_migrations: bool, restrict_branch_region: bool, insights_raw_queries: bool, plan: string, insights_enabled: bool, production_branch_web_console: bool, migration_table_name: string, migration_framework: string, created_at: string, updated_at: string, schema_last_updated_at: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases")
  let body = {name: $name, region: $region, cluster_size: $cluster_size, replicas: $replicas, kind: $kind, major_version: $major_version, storage: $storage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a database
#
# GET /organizations/{organization}/databases/{database}
# operationId: get_database
export def "organizations-databases database-by-organization-database" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, url: string, branches_url: string, branches_count: int, open_schema_recommendations_count: int, development_branches_count: int, production_branches_count: int, issues_count: int, multiple_admins_required_for_deletion: bool, ready: bool, at_backup_restore_branches_limit: bool, at_development_branch_usage_limit: bool, data_import: record<state: string, import_check_errors: string, started_at: string, finished_at: string, data_source: record<hostname: string, port: int, database: string>>, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, html_url: string, name: string, state: string, sharded: bool, default_branch_shard_count: int, default_branch_read_only_regions_count: int, default_branch_table_count: int, default_branch: string, require_approval_for_deploy: bool, resizing: bool, resize_queued: bool, config_changing: bool, config_change_queued: bool, allow_data_branching: bool, foreign_keys_enabled: bool, automatic_migrations: bool, restrict_branch_region: bool, insights_raw_queries: bool, plan: string, insights_enabled: bool, production_branch_web_console: bool, migration_table_name: string, migration_framework: string, created_at: string, updated_at: string, schema_last_updated_at: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update database settings
#
# PATCH /organizations/{organization}/databases/{database}
# operationId: update_database_settings
export def "organizations-databases settings" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-name: string # The name to update the database to
  --automatic-migrations: oneof<nothing, bool> # Whether or not to copy migration data to new branches and in deploy requests. (Vitess only)
  --migration-framework: string # A migration framework to use on the database. (Vitess only)
  --migration-table-name: string # Name of table to use as migration table for the database. (Vitess only)
  --require-approval-for-deploy: oneof<nothing, bool> # Whether or not deploy requests must be approved by a database administrator other than the request creator
  --restrict-branch-region: oneof<nothing, bool> # Whether or not to limit branch creation to the same region as the one selected during database creation.
  --allow-data-branching: oneof<nothing, bool> # Whether or not data branching is allowed on the database. (Vitess only)
  --allow-foreign-key-constraints: oneof<nothing, bool> # Whether or not foreign key constraints are allowed on the database. (Vitess only)
  --insights-raw-queries: oneof<nothing, bool> # Whether or not full queries should be collected from the database
  --production-branch-web-console: oneof<nothing, bool> # Whether or not the web console can be used on the production branch of the database
  --default-branch: string # The default branch of the database
]: any -> record<id: string, url: string, branches_url: string, branches_count: int, open_schema_recommendations_count: int, development_branches_count: int, production_branches_count: int, issues_count: int, multiple_admins_required_for_deletion: bool, ready: bool, at_backup_restore_branches_limit: bool, at_development_branch_usage_limit: bool, data_import: record<state: string, import_check_errors: string, started_at: string, finished_at: string, data_source: record<hostname: string, port: int, database: string>>, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, html_url: string, name: string, state: string, sharded: bool, default_branch_shard_count: int, default_branch_read_only_regions_count: int, default_branch_table_count: int, default_branch: string, require_approval_for_deploy: bool, resizing: bool, resize_queued: bool, config_changing: bool, config_change_queued: bool, allow_data_branching: bool, foreign_keys_enabled: bool, automatic_migrations: bool, restrict_branch_region: bool, insights_raw_queries: bool, plan: string, insights_enabled: bool, production_branch_web_console: bool, migration_table_name: string, migration_framework: string, created_at: string, updated_at: string, schema_last_updated_at: string, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)")
  let body = {new_name: $new_name, automatic_migrations: $automatic_migrations, migration_framework: $migration_framework, migration_table_name: $migration_table_name, require_approval_for_deploy: $require_approval_for_deploy, restrict_branch_region: $restrict_branch_region, allow_data_branching: $allow_data_branching, allow_foreign_key_constraints: $allow_foreign_key_constraints, insights_raw_queries: $insights_raw_queries, production_branch_web_console: $production_branch_web_console, default_branch: $default_branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a database
#
# DELETE /organizations/{organization}/databases/{database}
# operationId: delete_database
export def "organizations-databases database-by-organization-database-1" [
  organization: string
  database: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List backup policies
#
# GET /organizations/{organization}/databases/{database}/backup-policies
# operationId: list_backup_policies
export def "organizations-databases-backup-policies policies" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, display_name: string, name: string, target: string, retention_value: int, retention_unit: string, frequency_value: int, frequency_unit: string, schedule_time: string, schedule_day: int, schedule_week: int, created_at: string, updated_at: string, last_ran_at: string, next_run_at: string, required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/backup-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a backup policy
#
# POST /organizations/{organization}/databases/{database}/backup-policies
# operationId: create_backup_policy
export def "organizations-databases-backup-policies policy-by-organization-database" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the backup policy
  --target: string@target-completer # Whether the policy is for production or development branches
  --retention-value: int # A number value for the retention period of the backup policy
  --retention-unit: string@retention-unit-completer # The unit for the retention period of the backup policy
  --frequency-value: int # A number value for the frequency of the backup policy
  --frequency-unit: string@frequency-unit-completer # The unit for the frequency of the backup policy
  --schedule-time: string # The time of day that the backup is scheduled, in HH:MM format
  --schedule-day: int # Day of the week that the backup is scheduled. 0 is Sunday, 6 is Saturday
  --schedule-week: int # Week of the month that the backup is scheduled. 0 is the first week, 3 is the fourth week
]: any -> record<id: string, display_name: string, name: string, target: string, retention_value: int, retention_unit: string, frequency_value: int, frequency_unit: string, schedule_time: string, schedule_day: int, schedule_week: int, created_at: string, updated_at: string, last_ran_at: string, next_run_at: string, required: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/backup-policies")
  let body = {name: $name, target: $target, retention_value: $retention_value, retention_unit: $retention_unit, frequency_value: $frequency_value, frequency_unit: $frequency_unit, schedule_time: $schedule_time, schedule_day: $schedule_day, schedule_week: $schedule_week} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a backup policy
#
# GET /organizations/{organization}/databases/{database}/backup-policies/{id}
# operationId: get_backup_policy
export def "organizations-databases-backup-policies policy-by-id-organization-database" [
  id: string
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, display_name: string, name: string, target: string, retention_value: int, retention_unit: string, frequency_value: int, frequency_unit: string, schedule_time: string, schedule_day: int, schedule_week: int, created_at: string, updated_at: string, last_ran_at: string, next_run_at: string, required: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/backup-policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a backup policy
#
# PATCH /organizations/{organization}/databases/{database}/backup-policies/{id}
# operationId: update_backup_policy
export def "organizations-databases-backup-policies policy-by-id-organization-database-1" [
  id: string
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the backup policy
  --target: string@target-completer # Whether the policy is for production or development branches
  --retention-value: int # A number value for the retention period of the backup policy
  --retention-unit: string@retention-unit-completer # The unit for the retention period of the backup policy
  --frequency-value: int # A number value for the frequency of the backup policy
  --frequency-unit: string@frequency-unit-completer # The unit for the frequency of the backup policy
  --schedule-time: string # The time of day that the backup is scheduled, in HH:MM format
  --schedule-day: int # Day of the week that the backup is scheduled. 0 is Sunday, 6 is Saturday
  --schedule-week: int # Week of the month that the backup is scheduled. 0 is the first week, 3 is the fourth week
]: any -> record<id: string, display_name: string, name: string, target: string, retention_value: int, retention_unit: string, frequency_value: int, frequency_unit: string, schedule_time: string, schedule_day: int, schedule_week: int, created_at: string, updated_at: string, last_ran_at: string, next_run_at: string, required: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/backup-policies/($id)")
  let body = {name: $name, target: $target, retention_value: $retention_value, retention_unit: $retention_unit, frequency_value: $frequency_value, frequency_unit: $frequency_unit, schedule_time: $schedule_time, schedule_day: $schedule_day, schedule_week: $schedule_week} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a backup policy
#
# DELETE /organizations/{organization}/databases/{database}/backup-policies/{id}
# operationId: delete_backup_policy
export def "organizations-databases-backup-policies policy-by-id-organization-database-2" [
  id: string
  organization: string
  database: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/backup-policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List branches
#
# GET /organizations/{organization}/databases/{database}/branches
# operationId: list_branches
export def "organizations-databases-branches branches" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search branches by name
  --production: oneof<nothing, bool> # Filter branches by production status
  --safe-migrations: oneof<nothing, bool> # Filter branches by safe migrations (DDL protection)
  --order: string@order-completer # Order branches by created_at time
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, created_at: string, updated_at: string, deleted_at: string, restore_checklist_completed_at: string, schema_last_updated_at: string, kind: string, mysql_address: string, mysql_edge_address: string, state: string, direct_vtgate: bool, vtgate_size: string, vtgate_count: int, cluster_name: string, cluster_iops: int, ready: bool, schema_ready: bool, metal: bool, production: bool, safe_migrations: bool, sharded: bool, shard_count: int, keyspace_count: int, stale_schema: bool, actor: record, restored_from_branch: record, private_edge_connectivity: bool, has_replicas: bool, has_read_only_replicas: bool, html_url: string, url: string, region: record, parent_branch: string, vtgate_options: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "safe_migrations" $safe_migrations "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a branch
#
# POST /organizations/{organization}/databases/{database}/branches
# operationId: create_branch
# --storage shape: {minimum_storage_bytes?: int, maximum_storage_bytes?: int}
export def "organizations-databases-branches branch-by-organization-database" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the branch to create
  --parent-branch: string # The name of the parent branch. Defaults to the database's default branch if not provided.
  --backup-id: string # If provided, restores the backup's schema and data to the new branch. Must have `restore_production_branch_backup(s)` or `restore_backup(s)` access to do this.
  --region: string # The region to create the branch in. If not provided, the branch will be created in the default region for its database.
  --restore-point: string # Restore from a point-in-time recovery timestamp (e.g. 2023-01-01T00:00:00Z). Available only for PostgreSQL databases.
  --seed-data: string@seed-data-completer # If provided, restores the last successful backup's schema and data to the new branch. Must have `restore_production_branch_backup(s)` or `restore_backup(s)` access to do this, in addition to Data Branching™ being enabled for the branch.
  --cluster-size: string # The database cluster size. Required if a backup_id is provided, optional otherwise. Options: PS_10, PS_20, PS_40, ..., PS_2800
  --storage: record # shape: {minimum_storage_bytes?: int, maximum_storage_bytes?: int}
  --major-version: string # For PostgreSQL databases, the PostgreSQL major version to use for the branch. Defaults to the major version of the parent branch if it exists or the database's default branch major version. Ignored for branches restored from backups.
  --create-database-if-missing: oneof<nothing, bool> # Create a new database for the branch if the database does not exist. Defaults to false.
  --kind: string@kind-completer # The kind of branch to create. Required when create_database_if_missing is set.
]: any -> record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string, restore_checklist_completed_at: string, schema_last_updated_at: string, kind: string, mysql_address: string, mysql_edge_address: string, state: string, direct_vtgate: bool, vtgate_size: string, vtgate_count: int, cluster_name: string, cluster_iops: int, ready: bool, schema_ready: bool, metal: bool, production: bool, safe_migrations: bool, sharded: bool, shard_count: int, keyspace_count: int, stale_schema: bool, actor: record<id: string, display_name: string, avatar_url: string>, restored_from_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, private_edge_connectivity: bool, has_replicas: bool, has_read_only_replicas: bool, html_url: string, url: string, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, parent_branch: string, vtgate_options: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches")
  let body = {name: $name, parent_branch: $parent_branch, backup_id: $backup_id, region: $region, restore_point: $restore_point, seed_data: $seed_data, cluster_size: $cluster_size, storage: $storage, major_version: $major_version, create_database_if_missing: $create_database_if_missing, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a branch
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}
# operationId: get_branch
export def "organizations-databases-branches branch-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string, restore_checklist_completed_at: string, schema_last_updated_at: string, kind: string, mysql_address: string, mysql_edge_address: string, state: string, direct_vtgate: bool, vtgate_size: string, vtgate_count: int, cluster_name: string, cluster_iops: int, ready: bool, schema_ready: bool, metal: bool, production: bool, safe_migrations: bool, sharded: bool, shard_count: int, keyspace_count: int, stale_schema: bool, actor: record<id: string, display_name: string, avatar_url: string>, restored_from_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, private_edge_connectivity: bool, has_replicas: bool, has_read_only_replicas: bool, html_url: string, url: string, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, parent_branch: string, vtgate_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a branch
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}
# operationId: update_branch
export def "organizations-databases-branches branch-by-organization-database-branch-1" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_name: string # The name to update the branch
]: any -> record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string, restore_checklist_completed_at: string, schema_last_updated_at: string, kind: string, mysql_address: string, mysql_edge_address: string, state: string, direct_vtgate: bool, vtgate_size: string, vtgate_count: int, cluster_name: string, cluster_iops: int, ready: bool, schema_ready: bool, metal: bool, production: bool, safe_migrations: bool, sharded: bool, shard_count: int, keyspace_count: int, stale_schema: bool, actor: record<id: string, display_name: string, avatar_url: string>, restored_from_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, private_edge_connectivity: bool, has_replicas: bool, has_read_only_replicas: bool, html_url: string, url: string, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, parent_branch: string, vtgate_options: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)")
  let body = {new_name: $new_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a branch
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}
# operationId: delete_branch
export def "organizations-databases-branches branch-by-organization-database-branch-2" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-descendants: oneof<nothing, bool> # If true, recursively delete all descendant branches along with this branch
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_descendants" $delete_descendants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List backups
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/backups
# operationId: list_backups
export def "organizations-databases-branches-backups backups" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Whether to include all backups, including deleted ones
  --state: string@state-completer # Filter backups by state
  --policy: string # Filter backups by backup policy ID
  --qp-from: string # Filter backups started after this date (e.g. 2023-01-01T00:00:00Z)
  --qp-to: string # Filter backups started before this date (e.g. 2023-01-31T23:59:59Z)
  --running-at: string # Filter backups that are running during a specific time (e.g. 2023-01-01T00:00:00Z..2023-01-01T23:59:59Z)
  --production: oneof<nothing, bool> # Filter backups by production branch
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, state: string, size: int, estimated_storage_cost: float, created_at: string, updated_at: string, started_at: string, expires_at: string, completed_at: string, deleted_at: string, pvc_size: int, protected: bool, required: bool, restored_branches: list, actor: record, backup_policy: record, schema_snapshot: record, database_branch: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "policy" $policy "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "running_at" $running_at "scalar") (serialize-qp "production" $production "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/backups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a backup
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/backups
# operationId: create_backup
export def "organizations-databases-branches-backups backup-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name for the backup
  --retention-unit: string@retention-unit-completer # Unit for the retention period of the backup
  --retention-value: int # Value between `1` and `1000` for the retention period of the backup (i.e retention_value `6` and retention_unit `hour` means 6 hours)
  --emergency: oneof<nothing, bool> # Whether the backup is an immediate backup that may affect database performance. Emergency backups are only supported for PostgreSQL databases.
]: any -> record<id: string, name: string, state: string, size: int, estimated_storage_cost: float, created_at: string, updated_at: string, started_at: string, expires_at: string, completed_at: string, deleted_at: string, pvc_size: int, protected: bool, required: bool, restored_branches: table<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, backup_policy: record<id: string, display_name: string, name: string, target: string, retention_value: int, retention_unit: string, frequency_value: int, frequency_unit: string, schedule_time: string, schedule_day: int, schedule_week: int, created_at: string, updated_at: string, last_ran_at: string, next_run_at: string, required: bool>, schema_snapshot: record<id: string, name: string, created_at: string, updated_at: string, linted_at: string, url: string>, database_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/backups")
  let body = {name: $name, retention_unit: $retention_unit, retention_value: $retention_value, emergency: $emergency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a backup
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/backups/{id}
# operationId: get_backup
export def "organizations-databases-branches-backups backup-by-id-organization-database-branch" [
  id: string
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, state: string, size: int, estimated_storage_cost: float, created_at: string, updated_at: string, started_at: string, expires_at: string, completed_at: string, deleted_at: string, pvc_size: int, protected: bool, required: bool, restored_branches: table<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, backup_policy: record<id: string, display_name: string, name: string, target: string, retention_value: int, retention_unit: string, frequency_value: int, frequency_unit: string, schedule_time: string, schedule_day: int, schedule_week: int, created_at: string, updated_at: string, last_ran_at: string, next_run_at: string, required: bool>, schema_snapshot: record<id: string, name: string, created_at: string, updated_at: string, linted_at: string, url: string>, database_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/backups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a backup
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/backups/{id}
# operationId: update_backup
export def "organizations-databases-branches-backups backup-by-id-organization-database-branch-1" [
  id: string
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --protected: oneof<nothing, bool> # Whether the backup is protected from deletion or not
]: any -> record<id: string, name: string, state: string, size: int, estimated_storage_cost: float, created_at: string, updated_at: string, started_at: string, expires_at: string, completed_at: string, deleted_at: string, pvc_size: int, protected: bool, required: bool, restored_branches: table<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, backup_policy: record<id: string, display_name: string, name: string, target: string, retention_value: int, retention_unit: string, frequency_value: int, frequency_unit: string, schedule_time: string, schedule_day: int, schedule_week: int, created_at: string, updated_at: string, last_ran_at: string, next_run_at: string, required: bool>, schema_snapshot: record<id: string, name: string, created_at: string, updated_at: string, linted_at: string, url: string>, database_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/backups/($id)")
  let body = {protected: $protected} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a backup
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/backups/{id}
# operationId: delete_backup
export def "organizations-databases-branches-backups backup-by-id-organization-database-branch-2" [
  id: string
  organization: string
  database: string
  branch: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/backups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bouncer resize requests
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/bouncer-resizes
# operationId: list_branch_bouncer_resize_requests
export def "organizations-databases-branches-bouncer-resizes requests" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, state: string, replicas_per_cell: int, parameters: record, previous_replicas_per_cell: int, previous_parameters: record, started_at: string, completed_at: string, created_at: string, updated_at: string, actor: record, bouncer: record, sku: record, previous_sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/bouncer-resizes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bouncers
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/bouncers
# operationId: list_bouncers
export def "organizations-databases-branches-bouncers bouncers" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, sku: record, target: string, replicas_per_cell: int, created_at: string, updated_at: string, deleted_at: string, actor: record, branch: record, parameters: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/bouncers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a bouncer
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/bouncers
# operationId: create_bouncer
export def "organizations-databases-branches-bouncers bouncer-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The bouncer name
  --target: string # The type of server the bouncer targets
  --bouncer-size: string # The size SKU for the bouncer
  --replicas-per-cell: int # The number of replica servers per cell
]: any -> record<id: string, name: string, sku: record<name: string, display_name: string, cpu: string, ram: int, sort_order: int>, target: string, replicas_per_cell: int, created_at: string, updated_at: string, deleted_at: string, actor: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, parameters: table<id: string, namespace: string, name: string, display_name: string, category: string, description: string, immutable: bool, parameter_type: string, default_value: string, value: string, required: bool, created_at: string, updated_at: string, restart: bool, max: float, min: float, step: float, url: string, options: list, actor: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/bouncers")
  let body = {name: $name, target: $target, bouncer_size: $bouncer_size, replicas_per_cell: $replicas_per_cell} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a bouncer
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/bouncers/{bouncer}
# operationId: get_bouncer
export def "organizations-databases-branches-bouncers bouncer-by-organization-database-branch-bouncer" [
  organization: string
  database: string
  branch: string
  bouncer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, sku: record<name: string, display_name: string, cpu: string, ram: int, sort_order: int>, target: string, replicas_per_cell: int, created_at: string, updated_at: string, deleted_at: string, actor: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, parameters: table<id: string, namespace: string, name: string, display_name: string, category: string, description: string, immutable: bool, parameter_type: string, default_value: string, value: string, required: bool, created_at: string, updated_at: string, restart: bool, max: float, min: float, step: float, url: string, options: list, actor: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/bouncers/($bouncer)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a bouncer
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/bouncers/{bouncer}
# operationId: delete_bouncer
export def "organizations-databases-branches-bouncers bouncer-by-organization-database-branch-bouncer-1" [
  organization: string
  database: string
  branch: string
  bouncer: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/bouncers/($bouncer)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bouncer resize requests
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/bouncers/{bouncer}/resizes
# operationId: list_bouncer_resize_requests
export def "organizations-databases-branches-bouncers-resizes requests" [
  organization: string
  database: string
  branch: string
  bouncer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, state: string, replicas_per_cell: int, parameters: record, previous_replicas_per_cell: int, previous_parameters: record, started_at: string, completed_at: string, created_at: string, updated_at: string, actor: record, bouncer: record, sku: record, previous_sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/bouncers/($bouncer)/resizes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upsert a bouncer resize request
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/bouncers/{bouncer}/resizes
# operationId: update_bouncer_resize_request
export def "organizations-databases-branches-bouncers-resizes request-by-organization-database-branch-bouncer" [
  organization: string
  database: string
  branch: string
  bouncer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bouncer-size: string # The bouncer size SKU name (e.g., 'PGB_5', 'PGB_10', 'PGB_20', 'PGB_40', 'PGB_80', 'PGB_160'). Defaults to 'PGB_5'.
  --replicas-per-cell: int # The number of PgBouncers per availability zone. Defaults to 1.
  --parameters: record # Bouncer configuration parameters nested by namespace (e.g., {"pgbouncer": {"default_pool_size": "100"}}). Use the 'List cluster parameters' endpoint to retrieve available parameters. Only parameters with namespace 'pgbouncer' can be updated.
]: any -> record<id: string, state: string, replicas_per_cell: int, parameters: record, previous_replicas_per_cell: int, previous_parameters: record, started_at: string, completed_at: string, created_at: string, updated_at: string, actor: record<id: string, display_name: string, avatar_url: string>, bouncer: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, sku: record<name: string, display_name: string, cpu: string, ram: int, sort_order: int>, previous_sku: record<name: string, display_name: string, cpu: string, ram: int, sort_order: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/bouncers/($bouncer)/resizes")
  let body = {bouncer_size: $bouncer_size, replicas_per_cell: $replicas_per_cell, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a resize request
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/bouncers/{bouncer}/resizes
# operationId: cancel_bouncer_resize_request
export def "organizations-databases-branches-bouncers-resizes request-by-organization-database-branch-bouncer-1" [
  organization: string
  database: string
  branch: string
  bouncer: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/bouncers/($bouncer)/resizes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get branch change requests
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/changes
# operationId: list_branch_change_requests
export def "organizations-databases-branches-changes requests" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, restart: list, state: string, started_at: string, completed_at: string, created_at: string, updated_at: string, actor: record, cluster_name: string, cluster_display_name: string, cluster_metal: bool, replicas: int, parameters: record, previous_cluster_name: string, previous_cluster_display_name: string, previous_cluster_metal: bool, previous_replicas: int, previous_parameters: record, minimum_storage_bytes: int, maximum_storage_bytes: int, storage_autoscaling: bool, storage_shrinking: bool, storage_type: string, storage_iops: int, storage_throughput_mibs: int, previous_minimum_storage_bytes: int, previous_maximum_storage_bytes: int, previous_storage_autoscaling: bool, previous_storage_shrinking: bool, previous_storage_type: string, previous_storage_iops: int, previous_storage_throughput_mibs: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upsert a change request
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/changes
# operationId: update_branch_change_request
export def "organizations-databases-branches-changes request-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-size: string # The size of the cluster. Available sizes can be found using the 'List cluster sizes' endpoint.
  --replicas: int # The total number of replicas
  --parameters: record # Cluster configuration parameters nested by namespace (e.g., {"pgconf": {"max_connections": "200"}}). Use the 'List cluster parameters' endpoint to retrieve available parameters. Supported namespaces include 'patroni', 'pgconf', and 'pgbouncer'.
]: any -> record<id: string, restart: list<int>, state: string, started_at: string, completed_at: string, created_at: string, updated_at: string, actor: record<id: string, display_name: string, avatar_url: string>, cluster_name: string, cluster_display_name: string, cluster_metal: bool, replicas: int, parameters: record, previous_cluster_name: string, previous_cluster_display_name: string, previous_cluster_metal: bool, previous_replicas: int, previous_parameters: record, minimum_storage_bytes: int, maximum_storage_bytes: int, storage_autoscaling: bool, storage_shrinking: bool, storage_type: string, storage_iops: int, storage_throughput_mibs: int, previous_minimum_storage_bytes: int, previous_maximum_storage_bytes: int, previous_storage_autoscaling: bool, previous_storage_shrinking: bool, previous_storage_type: string, previous_storage_iops: int, previous_storage_throughput_mibs: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/changes")
  let body = {cluster_size: $cluster_size, replicas: $replicas, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a branch change request
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/changes/{id}
# operationId: get_branch_change_request
export def "organizations-databases-branches-changes request-by-organization-database-branch-id" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, restart: list<int>, state: string, started_at: string, completed_at: string, created_at: string, updated_at: string, actor: record<id: string, display_name: string, avatar_url: string>, cluster_name: string, cluster_display_name: string, cluster_metal: bool, replicas: int, parameters: record, previous_cluster_name: string, previous_cluster_display_name: string, previous_cluster_metal: bool, previous_replicas: int, previous_parameters: record, minimum_storage_bytes: int, maximum_storage_bytes: int, storage_autoscaling: bool, storage_shrinking: bool, storage_type: string, storage_iops: int, storage_throughput_mibs: int, previous_minimum_storage_bytes: int, previous_maximum_storage_bytes: int, previous_storage_autoscaling: bool, previous_storage_shrinking: bool, previous_storage_type: string, previous_storage_iops: int, previous_storage_throughput_mibs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/changes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change a branch cluster configuration
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/cluster
# operationId: update_branch_cluster_config
export def "organizations-databases-branches-cluster config" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cluster_size: string # The new size of the database cluster: PS_10, PS_20,…
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/cluster")
  let body = {cluster_size: $cluster_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Demote a branch
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/demote
# operationId: demote_branch
export def "organizations-databases-branches-demote branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string, restore_checklist_completed_at: string, schema_last_updated_at: string, kind: string, mysql_address: string, mysql_edge_address: string, state: string, direct_vtgate: bool, vtgate_size: string, vtgate_count: int, cluster_name: string, cluster_iops: int, ready: bool, schema_ready: bool, metal: bool, production: bool, safe_migrations: bool, sharded: bool, shard_count: int, keyspace_count: int, stale_schema: bool, actor: record<id: string, display_name: string, avatar_url: string>, restored_from_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, private_edge_connectivity: bool, has_replicas: bool, has_read_only_replicas: bool, html_url: string, url: string, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, parent_branch: string, vtgate_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/demote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List cluster extensions
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/extensions
# operationId: list_extensions
export def "organizations-databases-branches-extensions extensions" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, description: string, internal: bool, loader: string, url: string, available: bool, unavailable_reason: string, parameters: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/extensions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get keyspaces
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/keyspaces
# operationId: list_keyspaces
export def "organizations-databases-branches-keyspaces keyspaces" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, shards: int, sharded: bool, replicas: int, extra_replicas: int, created_at: string, updated_at: string, cluster_name: string, cluster_display_name: string, resizing: bool, resize_pending: bool, config_change_in_progress: bool, ready: bool, metal: bool, default: bool, imported: bool, vector_pool_allocation: float, node_ttl_strategy: string, replication_durability_constraints: record, vreplication_flags: record, mysqld_options: record, vttablet_options: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/keyspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a keyspace
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/keyspaces
# operationId: create_keyspace
export def "organizations-databases-branches-keyspaces keyspace-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the keyspace
  cluster_size: string # The database cluster size name (e.g., 'PS_10', 'PS_80'). Use the 'List available cluster sizes' endpoint to get available options for your organization. /v1/organizations/:organization/cluster-size-skus
  --extra-replicas: int # The number of additional replicas beyond the included default
  --shards: int # The number of shards. Default: 1
]: any -> record<id: string, name: string, shards: int, sharded: bool, replicas: int, extra_replicas: int, created_at: string, updated_at: string, cluster_name: string, cluster_display_name: string, resizing: bool, resize_pending: bool, config_change_in_progress: bool, ready: bool, metal: bool, default: bool, imported: bool, vector_pool_allocation: float, node_ttl_strategy: string, replication_durability_constraints: record<strategy: string>, vreplication_flags: record<optimize_inserts: bool, allow_no_blob_binlog_row_image: bool, vplayer_batching: bool>, mysqld_options: record, vttablet_options: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/keyspaces")
  let body = {name: $name, cluster_size: $cluster_size, extra_replicas: $extra_replicas, shards: $shards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a keyspace
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/keyspaces/{keyspace}
# operationId: get_keyspace
export def "organizations-databases-branches-keyspaces keyspace-by-organization-database-branch-keyspace" [
  organization: string
  database: string
  branch: string
  keyspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, shards: int, sharded: bool, replicas: int, extra_replicas: int, created_at: string, updated_at: string, cluster_name: string, cluster_display_name: string, resizing: bool, resize_pending: bool, config_change_in_progress: bool, ready: bool, metal: bool, default: bool, imported: bool, vector_pool_allocation: float, node_ttl_strategy: string, replication_durability_constraints: record<strategy: string>, vreplication_flags: record<optimize_inserts: bool, allow_no_blob_binlog_row_image: bool, vplayer_batching: bool>, mysqld_options: record, vttablet_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/keyspaces/($keyspace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure keyspace settings
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/keyspaces/{keyspace}
# operationId: update_keyspace
export def "organizations-databases-branches-keyspaces keyspace-by-organization-database-branch-keyspace-1" [
  organization: string
  database: string
  branch: string
  keyspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, shards: int, sharded: bool, replicas: int, extra_replicas: int, created_at: string, updated_at: string, cluster_name: string, cluster_display_name: string, resizing: bool, resize_pending: bool, config_change_in_progress: bool, ready: bool, metal: bool, default: bool, imported: bool, vector_pool_allocation: float, node_ttl_strategy: string, replication_durability_constraints: record<strategy: string>, vreplication_flags: record<optimize_inserts: bool, allow_no_blob_binlog_row_image: bool, vplayer_batching: bool>, mysqld_options: record, vttablet_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/keyspaces/($keyspace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a keyspace
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/keyspaces/{keyspace}
# operationId: delete_keyspace
export def "organizations-databases-branches-keyspaces keyspace-by-organization-database-branch-keyspace-2" [
  organization: string
  database: string
  branch: string
  keyspace: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/keyspaces/($keyspace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get keyspace rollout status
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/keyspaces/{keyspace}/rollout-status
# operationId: get_keyspace_rollout_status
export def "organizations-databases-branches-keyspaces-rollout-status status" [
  organization: string
  database: string
  branch: string
  keyspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, state: string, shards: table<name: string, last_rollout_started_at: string, last_rollout_finished_at: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/keyspaces/($keyspace)/rollout-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the VSchema for the keyspace
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/keyspaces/{keyspace}/vschema
# operationId: get_keyspace_vschema
export def "organizations-databases-branches-keyspaces-vschema vschema-by-organization-database-branch-keyspace" [
  organization: string
  database: string
  branch: string
  keyspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<raw: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/keyspaces/($keyspace)/vschema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the VSchema for the keyspace
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/keyspaces/{keyspace}/vschema
# operationId: update_keyspace_vschema
export def "organizations-databases-branches-keyspaces-vschema vschema-by-organization-database-branch-keyspace-1" [
  organization: string
  database: string
  branch: string
  keyspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vschema: string # The new VSchema for the keyspace
]: any -> record<raw: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/keyspaces/($keyspace)/vschema")
  let body = {vschema: $vschema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List cluster parameters
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/parameters
# operationId: list_parameters
export def "organizations-databases-branches-parameters parameters" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, display_name: string, namespace: string, category: string, description: string, extension: bool, immutable: bool, parameter_type: string, default_value: string, value: string, required: bool, created_at: string, updated_at: string, restart: bool, max: float, min: float, step: float, url: string, options: list<string>, actor: record<id: string, display_name: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/parameters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List passwords
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/passwords
# operationId: list_passwords
export def "organizations-databases-branches-passwords passwords" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --read-only-region-id: string # A read-only region of the database branch. If present, the password results will be filtered to only those in the region
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, role: string, cidrs: list, created_at: string, deleted_at: string, expires_at: string, last_used_at: string, expired: bool, direct_vtgate: bool, direct_vtgate_addresses: list, ttl_seconds: int, access_host_url: string, access_host_regional_url: string, access_host_regional_urls: list, actor: record, region: record, username: string, plain_text: string, replica: bool, renewable: bool, database_branch: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "read_only_region_id" $read_only_region_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/passwords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a password
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/passwords
# operationId: create_password
export def "organizations-databases-branches-passwords password-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Optional name of the password
  --role: string@role-completer # The database role of the password (i.e. admin)
  --replica: oneof<nothing, bool> # Whether the password is for a read replica
  --ttl: int # Time to live (in seconds) for the password. The password will be invalid when TTL has passed
  --cidrs: list # List of IP addresses or CIDR ranges that can use this password
  --direct-vtgate: oneof<nothing, bool> # Whether the password connects directly to a VTGate
]: any -> record<id: string, name: string, role: string, cidrs: list<string>, created_at: string, deleted_at: string, expires_at: string, last_used_at: string, expired: bool, direct_vtgate: bool, direct_vtgate_addresses: list<string>, ttl_seconds: int, access_host_url: string, access_host_regional_url: string, access_host_regional_urls: list<string>, actor: record<id: string, display_name: string, avatar_url: string>, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, username: string, plain_text: string, replica: bool, renewable: bool, database_branch: record<name: string, id: string, production: bool, mysql_edge_address: string, private_edge_connectivity: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/passwords")
  let body = {name: $name, role: $role, replica: $replica, ttl: $ttl, cidrs: $cidrs, direct_vtgate: $direct_vtgate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a password
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/passwords/{id}
# operationId: get_password
export def "organizations-databases-branches-passwords password-by-organization-database-branch-id" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, role: string, cidrs: list<string>, created_at: string, deleted_at: string, expires_at: string, last_used_at: string, expired: bool, direct_vtgate: bool, direct_vtgate_addresses: list<string>, ttl_seconds: int, access_host_url: string, access_host_regional_url: string, access_host_regional_urls: list<string>, actor: record<id: string, display_name: string, avatar_url: string>, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, username: string, plain_text: string, replica: bool, renewable: bool, database_branch: record<name: string, id: string, production: bool, mysql_edge_address: string, private_edge_connectivity: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/passwords/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a password
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/passwords/{id}
# operationId: update_password
export def "organizations-databases-branches-passwords password-by-organization-database-branch-id-1" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for the password
  --cidrs: list # List of IP addresses or CIDR ranges that can use this password
]: any -> record<id: string, name: string, role: string, cidrs: list<string>, created_at: string, deleted_at: string, expires_at: string, last_used_at: string, expired: bool, direct_vtgate: bool, direct_vtgate_addresses: list<string>, ttl_seconds: int, access_host_url: string, access_host_regional_url: string, access_host_regional_urls: list<string>, actor: record<id: string, display_name: string, avatar_url: string>, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, username: string, plain_text: string, replica: bool, renewable: bool, database_branch: record<name: string, id: string, production: bool, mysql_edge_address: string, private_edge_connectivity: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/passwords/($id)")
  let body = {name: $name, cidrs: $cidrs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a password
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/passwords/{id}
# operationId: delete_password
export def "organizations-databases-branches-passwords password-by-organization-database-branch-id-2" [
  organization: string
  database: string
  branch: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/passwords/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Renew a password
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/passwords/{id}/renew
# operationId: renew_password
export def "organizations-databases-branches-passwords-renew password" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, role: string, cidrs: list<string>, created_at: string, deleted_at: string, expires_at: string, last_used_at: string, expired: bool, direct_vtgate: bool, direct_vtgate_addresses: list<string>, ttl_seconds: int, access_host_url: string, access_host_regional_url: string, access_host_regional_urls: list<string>, actor: record<id: string, display_name: string, avatar_url: string>, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, username: string, plain_text: string, replica: bool, renewable: bool, database_branch: record<name: string, id: string, production: bool, mysql_edge_address: string, private_edge_connectivity: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/passwords/($id)/renew")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Promote a branch
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/promote
# operationId: promote_branch
export def "organizations-databases-branches-promote branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string, restore_checklist_completed_at: string, schema_last_updated_at: string, kind: string, mysql_address: string, mysql_edge_address: string, state: string, direct_vtgate: bool, vtgate_size: string, vtgate_count: int, cluster_name: string, cluster_iops: int, ready: bool, schema_ready: bool, metal: bool, production: bool, safe_migrations: bool, sharded: bool, shard_count: int, keyspace_count: int, stale_schema: bool, actor: record<id: string, display_name: string, avatar_url: string>, restored_from_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, private_edge_connectivity: bool, has_replicas: bool, has_read_only_replicas: bool, html_url: string, url: string, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, parent_branch: string, vtgate_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/promote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List generated query patterns reports
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/query-patterns
# operationId: list_generated_query_patterns_reports
export def "organizations-databases-branches-query-patterns reports" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --starting-after: string # If provided, returns results after the specified cursor
  --ending-before: string # If provided, returns results before the specified cursor
  --limit: int # If provided, specifies the number of returned results (max 100) (default: 25)
]: nothing -> record<type: string, has_next: bool, has_prev: bool, cursor_start: string, cursor_end: string, data: table<id: string, state: string, created_at: string, finished_at: string, url: string, download_url: string, actor: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/query-patterns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new query patterns report
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/query-patterns
# operationId: create_query_patterns_report
export def "organizations-databases-branches-query-patterns report-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, state: string, created_at: string, finished_at: string, url: string, download_url: string, actor: record<id: string, display_name: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/query-patterns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show the status of a query patterns report
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/query-patterns/{id}
# operationId: get_query_patterns_report_status
export def "organizations-databases-branches-query-patterns status" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, state: string, created_at: string, finished_at: string, url: string, download_url: string, actor: record<id: string, display_name: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/query-patterns/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a query patterns report
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/query-patterns/{id}
# operationId: delete_query_patterns_report
export def "organizations-databases-branches-query-patterns report-by-organization-database-branch-id" [
  organization: string
  database: string
  branch: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/query-patterns/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a finished query patterns report
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/query-patterns/{id}/download
# operationId: get_query_patterns_report
export def "organizations-databases-branches-query-patterns-download report" [
  organization: string
  database: string
  branch: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/query-patterns/($id)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a change request
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/resizes
# operationId: cancel_branch_change_request
export def "organizations-databases-branches-resizes request" [
  organization: string
  database: string
  branch: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/resizes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List roles
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/roles
# operationId: list_roles
export def "organizations-databases-branches-roles roles" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
  --status: string # Filter roles by status
  --q: string # Search roles by name or username
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, access_host_url: string, private_access_host_url: string, private_connection_service_name: string, username: string, base_username: string, password: string, database_name: string, created_at: string, updated_at: string, deleted_at: string, expires_at: string, dropped_at: string, disabled_at: string, drop_failed: string, expired: bool, default: bool, ttl: int, inherited_roles: list, branch: record, actor: record, query_safety_settings: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create role credentials
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/roles
# operationId: create_role
export def "organizations-databases-branches-roles role-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the role
  --ttl: int # Time to live in seconds
  --inherited-roles: list # Roles to inherit from
  --require-where-on-delete: string # Require WHERE clause on DELETE statements
  --require-where-on-update: string # Require WHERE clause on UPDATE statements
]: any -> record<id: string, name: string, access_host_url: string, private_access_host_url: string, private_connection_service_name: string, username: string, base_username: string, password: string, database_name: string, created_at: string, updated_at: string, deleted_at: string, expires_at: string, dropped_at: string, disabled_at: string, drop_failed: string, expired: bool, default: bool, ttl: int, inherited_roles: list<string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, query_safety_settings: record<require_where_on_delete: string, require_where_on_update: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles")
  let body = {name: $name, ttl: $ttl, inherited_roles: $inherited_roles, require_where_on_delete: $require_where_on_delete, require_where_on_update: $require_where_on_update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the default postgres role
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/roles/default
# operationId: get_default_role
export def "organizations-databases-branches-roles-default role" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, access_host_url: string, private_access_host_url: string, private_connection_service_name: string, username: string, base_username: string, password: string, database_name: string, created_at: string, updated_at: string, deleted_at: string, expires_at: string, dropped_at: string, disabled_at: string, drop_failed: string, expired: bool, default: bool, ttl: int, inherited_roles: list<string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, query_safety_settings: record<require_where_on_delete: string, require_where_on_update: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset default credentials
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/roles/reset-default
# operationId: reset_default_role
export def "organizations-databases-branches-roles-reset-default role" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, access_host_url: string, private_access_host_url: string, private_connection_service_name: string, username: string, base_username: string, password: string, database_name: string, created_at: string, updated_at: string, deleted_at: string, expires_at: string, dropped_at: string, disabled_at: string, drop_failed: string, expired: bool, default: bool, ttl: int, inherited_roles: list<string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, query_safety_settings: record<require_where_on_delete: string, require_where_on_update: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles/reset-default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a role
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/roles/{id}
# operationId: get_role
export def "organizations-databases-branches-roles role-by-organization-database-branch-id" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, access_host_url: string, private_access_host_url: string, private_connection_service_name: string, username: string, base_username: string, password: string, database_name: string, created_at: string, updated_at: string, deleted_at: string, expires_at: string, dropped_at: string, disabled_at: string, drop_failed: string, expired: bool, default: bool, ttl: int, inherited_roles: list<string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, query_safety_settings: record<require_where_on_delete: string, require_where_on_update: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update role name
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/roles/{id}
# operationId: update_role
export def "organizations-databases-branches-roles role-by-organization-database-branch-id-1" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the role
  --require-where-on-delete: string # Require WHERE clause on DELETE statements
  --require-where-on-update: string # Require WHERE clause on UPDATE statements
]: any -> record<id: string, name: string, access_host_url: string, private_access_host_url: string, private_connection_service_name: string, username: string, base_username: string, password: string, database_name: string, created_at: string, updated_at: string, deleted_at: string, expires_at: string, dropped_at: string, disabled_at: string, drop_failed: string, expired: bool, default: bool, ttl: int, inherited_roles: list<string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, query_safety_settings: record<require_where_on_delete: string, require_where_on_update: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles/($id)")
  let body = {name: $name, require_where_on_delete: $require_where_on_delete, require_where_on_update: $require_where_on_update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete role credentials
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/roles/{id}
# operationId: delete_role
export def "organizations-databases-branches-roles role-by-organization-database-branch-id-2" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --successor: string # The optional role to reassign ownership to before dropping
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "successor" $successor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reassign objects owned by one role to another role
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/roles/{id}/reassign
# operationId: reassign_role_objects
export def "organizations-databases-branches-roles-reassign objects" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  successor: string # The role to reassign ownership to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles/($id)/reassign")
  let body = {successor: $successor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Renew role expiration
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/roles/{id}/renew
# operationId: renew_role
export def "organizations-databases-branches-roles-renew role" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, access_host_url: string, private_access_host_url: string, private_connection_service_name: string, username: string, base_username: string, password: string, database_name: string, created_at: string, updated_at: string, deleted_at: string, expires_at: string, dropped_at: string, disabled_at: string, drop_failed: string, expired: bool, default: bool, ttl: int, inherited_roles: list<string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, query_safety_settings: record<require_where_on_delete: string, require_where_on_update: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles/($id)/renew")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset a role's password
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/roles/{id}/reset
# operationId: reset_role
export def "organizations-databases-branches-roles-reset role" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, access_host_url: string, private_access_host_url: string, private_connection_service_name: string, username: string, base_username: string, password: string, database_name: string, created_at: string, updated_at: string, deleted_at: string, expires_at: string, dropped_at: string, disabled_at: string, drop_failed: string, expired: bool, default: bool, ttl: int, inherited_roles: list<string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, actor: record<id: string, display_name: string, avatar_url: string>, query_safety_settings: record<require_where_on_delete: string, require_where_on_update: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/roles/($id)/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable safe migrations for a branch
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/safe-migrations
# operationId: enable_safe_migrations
export def "organizations-databases-branches-safe-migrations migrations-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string, restore_checklist_completed_at: string, schema_last_updated_at: string, kind: string, mysql_address: string, mysql_edge_address: string, state: string, direct_vtgate: bool, vtgate_size: string, vtgate_count: int, cluster_name: string, cluster_iops: int, ready: bool, schema_ready: bool, metal: bool, production: bool, safe_migrations: bool, sharded: bool, shard_count: int, keyspace_count: int, stale_schema: bool, actor: record<id: string, display_name: string, avatar_url: string>, restored_from_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, private_edge_connectivity: bool, has_replicas: bool, has_read_only_replicas: bool, html_url: string, url: string, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, parent_branch: string, vtgate_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/safe-migrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable safe migrations for a branch
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/safe-migrations
# operationId: disable_safe_migrations
export def "organizations-databases-branches-safe-migrations migrations-by-organization-database-branch-1" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string, restore_checklist_completed_at: string, schema_last_updated_at: string, kind: string, mysql_address: string, mysql_edge_address: string, state: string, direct_vtgate: bool, vtgate_size: string, vtgate_count: int, cluster_name: string, cluster_iops: int, ready: bool, schema_ready: bool, metal: bool, production: bool, safe_migrations: bool, sharded: bool, shard_count: int, keyspace_count: int, stale_schema: bool, actor: record<id: string, display_name: string, avatar_url: string>, restored_from_branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, private_edge_connectivity: bool, has_replicas: bool, has_read_only_replicas: bool, html_url: string, url: string, region: record<id: string, provider: string, enabled: bool, public_ip_addresses: list<string>, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>, parent_branch: string, vtgate_options: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/safe-migrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a branch schema
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/schema
# operationId: get_branch_schema
export def "organizations-databases-branches-schema schema" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyspace: string # Return the schema for a single Vitess keyspace
  --namespace: string # Return the schema for a PostgreSQL catalog namespace in `<database>.<schema>` format (e.g. public.schema1)
]: nothing -> record<data: table<name: string, html: string, raw: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyspace" $keyspace "scalar") (serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/schema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lint a branch schema
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/schema/lint
# operationId: lint_branch_schema
export def "organizations-databases-branches-schema-lint schema" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<lint_error: string, subject_type: string, keyspace_name: string, table_name: string, error_description: string, docs_url: string, column_name: string, foreign_key_column_names: list, auto_increment_column_names: list, charset_name: string, engine_name: string, vindex_name: string, json_path: string, check_constraint_name: string, enum_value: string, partitioning_type: string, partition_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/schema/lint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List traffic budgets
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/traffic/budgets
# operationId: list_traffic_budgets
export def "organizations-databases-branches-traffic-budgets budgets" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
  --period: string # Time period filter (e.g., '1h', '24h', '7d')
  --created-at: string # Filter by creation date range (format: 'start..end')
  --fingerprint: string # Filter budgets by query fingerprint
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, mode: string, capacity: float, rate: float, burst: float, concurrency: float, warning_threshold: float, actor: record, rules: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "created_at" $created_at "scalar") (serialize-qp "fingerprint" $fingerprint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/traffic/budgets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a traffic budget
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/traffic/budgets
# operationId: create_traffic_budget
export def "organizations-databases-branches-traffic-budgets budget-by-organization-database-branch" [
  organization: string
  database: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the traffic budget
  --mode: string@mode-completer # The mode of the traffic budget
  --capacity: int # The maximum capacity that can be banked, measured as a percentage of seconds of full server usage (0-6000). Unlimited when not set.
  --rate: int # The rate at which capacity refills, as a percentage of server resources (0-100). Unlimited when not set.
  --burst: int # The maximum capacity a single query can consume, measured as a percentage of seconds of full server usage (0-6000). Unlimited when not set.
  --concurrency: int # The percentage of available worker processes this policy can use (0-100). Unlimited when not set.
  --warning-threshold: int # A percentage of capacity, burst, or concurrency thresholds to emit warnings for enforced budgets (0-100).
  --rules: list # Array of traffic rules to apply to the budget
]: any -> record<id: string, name: string, mode: string, capacity: float, rate: float, burst: float, concurrency: float, warning_threshold: float, actor: record<id: string, display_name: string, avatar_url: string>, rules: table<id: string, kind: string, tags: list, fingerprint: string, keyspace: string, actor: record, syntax_highlighted_sql: string, created_at: string, updated_at: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/traffic/budgets")
  let body = {name: $name, mode: $mode, capacity: $capacity, rate: $rate, burst: $burst, concurrency: $concurrency, warning_threshold: $warning_threshold, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a traffic rule
#
# POST /organizations/{organization}/databases/{database}/branches/{branch}/traffic/budgets/{budget_id}/rules
# operationId: create_traffic_rule
export def "organizations-databases-branches-traffic-budgets-rules rule-by-organization-database-branch-budget_id" [
  organization: string
  database: string
  branch: string
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string@kind-completer-1 # Kind of rule
  --keyspace: string # The keyspace to apply a query pattern rule to
  --fingerprint: string # Query pattern fingerprint to apply rule to
  --tags: list # Optional array of tags for this rule
]: any -> record<id: string, kind: string, tags: table<key_id: string, key: string, value: string, source: string>, fingerprint: string, keyspace: string, actor: record<id: string, display_name: string, avatar_url: string>, syntax_highlighted_sql: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/traffic/budgets/($budget_id)/rules")
  let body = {kind: $kind, keyspace: $keyspace, fingerprint: $fingerprint, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a traffic rule
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/traffic/budgets/{budget_id}/rules/{id}
# operationId: delete_traffic_rule
export def "organizations-databases-branches-traffic-budgets-rules rule-by-organization-database-branch-budget_id-id" [
  organization: string
  database: string
  branch: string
  budget_id: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/traffic/budgets/($budget_id)/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a traffic budget
#
# GET /organizations/{organization}/databases/{database}/branches/{branch}/traffic/budgets/{id}
# operationId: get_traffic_budget
export def "organizations-databases-branches-traffic-budgets budget-by-organization-database-branch-id" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, mode: string, capacity: float, rate: float, burst: float, concurrency: float, warning_threshold: float, actor: record<id: string, display_name: string, avatar_url: string>, rules: table<id: string, kind: string, tags: list, fingerprint: string, keyspace: string, actor: record, syntax_highlighted_sql: string, created_at: string, updated_at: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/traffic/budgets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a traffic budget
#
# PATCH /organizations/{organization}/databases/{database}/branches/{branch}/traffic/budgets/{id}
# operationId: update_traffic_budget
export def "organizations-databases-branches-traffic-budgets budget-by-organization-database-branch-id-1" [
  organization: string
  database: string
  branch: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the traffic budget
  --mode: string@mode-completer # The mode of the traffic budget
  --capacity: int # The maximum capacity that can be banked, measured as a percentage of seconds of full server usage (0-6000). Unlimited when not set.
  --rate: int # The rate at which capacity refills, as a percentage of server resources (0-100). Unlimited when not set.
  --burst: int # The maximum capacity a single query can consume, measured as a percentage of seconds of full server usage (0-6000). Unlimited when not set.
  --concurrency: int # The percentage of available worker processes this policy can use (0-100). Unlimited when not set.
  --warning-threshold: int # A percentage of capacity, burst, or concurrency thresholds to emit warnings for enforced budgets (0-100).
  --rules: list # Array of traffic rules to apply to the budget
]: any -> record<id: string, name: string, mode: string, capacity: float, rate: float, burst: float, concurrency: float, warning_threshold: float, actor: record<id: string, display_name: string, avatar_url: string>, rules: table<id: string, kind: string, tags: list, fingerprint: string, keyspace: string, actor: record, syntax_highlighted_sql: string, created_at: string, updated_at: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/traffic/budgets/($id)")
  let body = {name: $name, mode: $mode, capacity: $capacity, rate: $rate, burst: $burst, concurrency: $concurrency, warning_threshold: $warning_threshold, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a traffic budget
#
# DELETE /organizations/{organization}/databases/{database}/branches/{branch}/traffic/budgets/{id}
# operationId: delete_traffic_budget
export def "organizations-databases-branches-traffic-budgets budget-by-organization-database-branch-id-2" [
  organization: string
  database: string
  branch: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/branches/($branch)/traffic/budgets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List IP restriction entries
#
# GET /organizations/{organization}/databases/{database}/cidrs
# operationId: list_database_postgres_cidrs
export def "organizations-databases-cidrs cidrs" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, schema: string, role: string, cidrs: list, created_at: string, updated_at: string, deleted_at: string, actor: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/cidrs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an IP restriction entry
#
# POST /organizations/{organization}/databases/{database}/cidrs
# operationId: create_database_postgres_cidr
export def "organizations-databases-cidrs cidr-by-organization-database" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # The PostgreSQL schema to restrict access to. Leave empty or omit to allow access to all schemas.
  --role: string # The PostgreSQL role to restrict access to. Leave empty or omit to allow access for all roles.
  cidrs: list # List of IPv4 CIDR ranges (e.g., ['192.168.1.0/24', '192.168.1.1/32']). Must contain at least one valid IPv4 address or range.
]: any -> record<id: string, schema: string, role: string, cidrs: list<string>, created_at: string, updated_at: string, deleted_at: string, actor: record<id: string, display_name: string, avatar_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/cidrs")
  let body = {schema: $schema, role: $role, cidrs: $cidrs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an IP restriction entry
#
# GET /organizations/{organization}/databases/{database}/cidrs/{id}
# operationId: get_database_postgres_cidr
export def "organizations-databases-cidrs cidr-by-organization-database-id" [
  organization: string
  database: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, schema: string, role: string, cidrs: list<string>, created_at: string, updated_at: string, deleted_at: string, actor: record<id: string, display_name: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/cidrs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an IP restriction entry
#
# PATCH /organizations/{organization}/databases/{database}/cidrs/{id}
# operationId: update_database_postgres_cidr
export def "organizations-databases-cidrs cidr-by-organization-database-id-1" [
  organization: string
  database: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # The PostgreSQL schema to restrict access to. Leave empty to allow access to all schemas.
  --role: string # The PostgreSQL role to restrict access to. Leave empty to allow access for all roles.
  --cidrs: list # List of IPv4 CIDR ranges (e.g., ['192.168.1.0/24', '192.168.1.1/32']). Only provided fields will be updated.
]: any -> record<id: string, schema: string, role: string, cidrs: list<string>, created_at: string, updated_at: string, deleted_at: string, actor: record<id: string, display_name: string, avatar_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/cidrs/($id)")
  let body = {schema: $schema, role: $role, cidrs: $cidrs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an IP restriction entry
#
# DELETE /organizations/{organization}/databases/{database}/cidrs/{id}
# operationId: delete_database_postgres_cidr
export def "organizations-databases-cidrs cidr-by-organization-database-id-2" [
  organization: string
  database: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/cidrs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the deploy queue
#
# GET /organizations/{organization}/databases/{database}/deploy-queue
# operationId: get_deploy_queue
export def "organizations-databases-deploy-queue queue" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list, deploy_operations: list, deploy_operation_summaries: list, lint_errors: list, sequential_diff_dependencies: list, lookup_vindex_operations: list, throttler_configurations: record, deployment_revert_request: record, actor: record, cutover_actor: record, cancelled_actor: record, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-queue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List deploy requests
#
# GET /organizations/{organization}/databases/{database}/deploy-requests
# operationId: list_deploy_requests
export def "organizations-databases-deploy-requests requests" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Filter by state of the deploy request (open, closed, deployed)
  --branch: string # Filter by the name of the branch the deploy request is created from
  --into-branch: string # Filter by the name of the branch the deploy request will be merged into
  --deployed-at: string # Filter deploy requests by the date they were deployed. (e.g. 2023-01-01T00:00:00Z..2023-01-31T23:59:59Z)
  --running-at: string # Filter deploy requests by the date they were running. (e.g. 2023-01-01T00:00:00Z..2023-01-31T23:59:59Z)
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, number: int, actor: record, closed_by: record, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "into_branch" $into_branch "scalar") (serialize-qp "deployed_at" $deployed_at "scalar") (serialize-qp "running_at" $running_at "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a deploy request
#
# POST /organizations/{organization}/databases/{database}/deploy-requests
# operationId: create_deploy_request
export def "organizations-databases-deploy-requests request-by-organization-database" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branch: string # The name of the branch the deploy request is created from
  into_branch: string # The name of the branch the deploy request will be merged into
  --notes: string # Notes about the deploy request
  --auto-cutover: oneof<nothing, bool> # Whether or not to enable auto_cutover for the deploy request. When enabled, will auto cutover to the new schema as soon as it is ready.
  --auto-delete-branch: oneof<nothing, bool> # Whether or not to enable auto_delete_branch for the deploy request. When enabled, will delete the branch once the DR successfully completes.
]: any -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests")
  let body = {branch: $branch, into_branch: $into_branch, notes: $notes, auto_cutover: $auto_cutover, auto_delete_branch: $auto_delete_branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a deploy request
#
# GET /organizations/{organization}/databases/{database}/deploy-requests/{number}
# operationId: get_deploy_request
export def "organizations-databases-deploy-requests request-by-organization-database-number" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Close a deploy request
#
# PATCH /organizations/{organization}/databases/{database}/deploy-requests/{number}
# operationId: close_deploy_request
export def "organizations-databases-deploy-requests request-by-organization-database-number-1" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # The deploy request will be updated to this state
]: any -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)")
  let body = {state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete a gated deploy request
#
# POST /organizations/{organization}/databases/{database}/deploy-requests/{number}/apply-deploy
# operationId: complete_gated_deploy_request
export def "organizations-databases-deploy-requests-apply-deploy request" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/apply-deploy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update auto-apply for deploy request
#
# PUT /organizations/{organization}/databases/{database}/deploy-requests/{number}/auto-apply
# operationId: update_auto_apply
export def "organizations-databases-deploy-requests-auto-apply apply" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enable: oneof<nothing, bool> # Whether or not to enable auto-apply for the deploy request
]: any -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/auto-apply")
  let body = {enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update auto-delete branch for deploy request
#
# PUT /organizations/{organization}/databases/{database}/deploy-requests/{number}/auto-delete-branch
# operationId: update_auto_delete_branch
export def "organizations-databases-deploy-requests-auto-delete-branch branch" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enable: oneof<nothing, bool> # Whether or not to enable auto-delete branch for the deploy request
]: any -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/auto-delete-branch")
  let body = {enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a queued deploy request
#
# POST /organizations/{organization}/databases/{database}/deploy-requests/{number}/cancel
# operationId: cancel_deploy_request
export def "organizations-databases-deploy-requests-cancel request" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete an errored deploy
#
# POST /organizations/{organization}/databases/{database}/deploy-requests/{number}/complete-deploy
# operationId: complete_errored_deploy
export def "organizations-databases-deploy-requests-complete-deploy deploy" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/complete-deploy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queue a deploy request
#
# POST /organizations/{organization}/databases/{database}/deploy-requests/{number}/deploy
# operationId: queue_deploy_request
export def "organizations-databases-deploy-requests-deploy request" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --instant-ddl: oneof<nothing, bool> # Whether or not to deploy the request with instant DDL. Defaults to false.
]: any -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/deploy")
  let body = {instant_ddl: $instant_ddl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a deployment
#
# GET /organizations/{organization}/databases/{database}/deploy-requests/{number}/deployment
# operationId: get_deployment
export def "organizations-databases-deploy-requests-deployment deployment" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: table<id: string, state: string, keyspace_name: string, table_name: string, operation_name: string, eta_seconds: float, progress_percentage: float, deploy_error_docs_url: string, ddl_statement: string, syntax_highlighted_ddl: string, created_at: string, updated_at: string, throttled_at: string, can_drop_data: bool, table_locked: bool, table_recently_used: bool, table_recently_used_at: string, removed_foreign_key_names: list, deploy_errors: string>, deploy_operation_summaries: table<id: string, created_at: string, deploy_errors: string, ddl_statement: string, eta_seconds: int, keyspace_name: string, operation_name: string, progress_percentage: float, state: string, syntax_highlighted_ddl: string, table_name: string, table_recently_used_at: string, throttled_at: string, removed_foreign_key_names: list, shard_count: int, shard_names: list, can_drop_data: bool, table_recently_used: bool, sharded: bool, operations: list>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/deployment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable force cutover for a deploy request
#
# POST /organizations/{organization}/databases/{database}/deploy-requests/{number}/force-cutover
# operationId: force_cutover_deploy_request
export def "organizations-databases-deploy-requests-force-cutover request" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/force-cutover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List deploy operations
#
# GET /organizations/{organization}/databases/{database}/deploy-requests/{number}/operations
# operationId: list_deploy_operations
export def "organizations-databases-deploy-requests-operations operations" [
  number: int
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, state: string, keyspace_name: string, table_name: string, operation_name: string, eta_seconds: float, progress_percentage: float, deploy_error_docs_url: string, ddl_statement: string, syntax_highlighted_ddl: string, created_at: string, updated_at: string, throttled_at: string, can_drop_data: bool, table_locked: bool, table_recently_used: bool, table_recently_used_at: string, removed_foreign_key_names: list, deploy_errors: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete a revert
#
# POST /organizations/{organization}/databases/{database}/deploy-requests/{number}/revert
# operationId: complete_revert
export def "organizations-databases-deploy-requests-revert revert" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/revert")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List deploy request reviews
#
# GET /organizations/{organization}/databases/{database}/deploy-requests/{number}/reviews
# operationId: list_deploy_request_reviews
export def "organizations-databases-deploy-requests-reviews reviews" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, body: string, html_body: string, state: string, created_at: string, updated_at: string, actor: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Review a deploy request
#
# POST /organizations/{organization}/databases/{database}/deploy-requests/{number}/reviews
# operationId: review_deploy_request
export def "organizations-databases-deploy-requests-reviews request" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-2 # Whether the review is a comment or approval. Service tokens must have corresponding access (either `approve_deploy_request` or `review_deploy_request`)
  --body-body: string # Deploy request review comments
]: any -> record<id: string, body: string, html_body: string, state: string, created_at: string, updated_at: string, actor: record<id: string, display_name: string, avatar_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/reviews")
  let body = {state: $state, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Skip revert period
#
# POST /organizations/{organization}/databases/{database}/deploy-requests/{number}/skip-revert
# operationId: skip_revert_period
export def "organizations-databases-deploy-requests-skip-revert period" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, number: int, actor: record<id: string, display_name: string, avatar_url: string>, closed_by: record<id: string, display_name: string, avatar_url: string>, branch: string, branch_id: string, branch_deleted: bool, branch_deleted_by: record<id: string, display_name: string, avatar_url: string>, branch_deleted_at: string, into_branch: string, into_branch_sharded: bool, into_branch_shard_count: int, into_branch_keyspace_count: int, approved: bool, state: string, deployment_state: string, deployment: record<id: string, auto_cutover: bool, auto_delete_branch: bool, created_at: string, cutover_at: string, cutover_expiring: bool, deploy_check_errors: string, finished_at: string, force_cutover_requested_at: string, queued_at: string, ready_to_cutover_at: string, started_at: string, state: string, submitted_at: string, updated_at: string, into_branch: string, deploy_request_number: int, deployable: bool, preceding_deployments: list<record>, deploy_operations: list<record>, deploy_operation_summaries: list<record>, lint_errors: list<record>, sequential_diff_dependencies: list<record>, lookup_vindex_operations: list<record>, throttler_configurations: record, deployment_revert_request: record, actor: record<id: string, display_name: string, avatar_url: string>, cutover_actor: record<id: string, display_name: string, avatar_url: string>, cancelled_actor: record<id: string, display_name: string, avatar_url: string>, schema_last_updated_at: string, table_locked: bool, locked_table_name: string, instant_ddl: bool, instant_ddl_eligible: bool, queue_paused: bool, queue_pause_reason: string>, num_comments: int, html_url: string, notes: string, html_body: string, created_at: string, updated_at: string, closed_at: string, deployed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/skip-revert")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check deploy request storage
#
# GET /organizations/{organization}/databases/{database}/deploy-requests/{number}/storage-check
# operationId: check_deploy_request_storage
export def "organizations-databases-deploy-requests-storage-check storage" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enough_storage: bool, upgradeable: bool, storage_bytes_needed: int, storage_report: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/storage-check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get deploy request throttler configurations
#
# GET /organizations/{organization}/databases/{database}/deploy-requests/{number}/throttler
# operationId: get_deploy_request_throttler
export def "organizations-databases-deploy-requests-throttler throttler-by-organization-database-number" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keyspaces: list<string>, configurable: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, configurations: table<keyspace_name: string, ratio: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/throttler")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update deploy request throttler configurations
#
# PATCH /organizations/{organization}/databases/{database}/deploy-requests/{number}/throttler
# operationId: update_deploy_request_throttler
export def "organizations-databases-deploy-requests-throttler throttler-by-organization-database-number-1" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ratio: int # A throttler ratio between 0 and 95 that will apply to all keyspaces affected by the deploy request. 0 effectively disables throttler, while 95 drastically slows down migrations in the deploy request
  --configurations: list # If specifying throttler ratios per keyspace, an array of { "keyspace_name": "mykeyspace", "ratio": 10 }, one for each eligible keyspace
]: any -> record<keyspaces: list<string>, configurable: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, configurations: table<keyspace_name: string, ratio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/deploy-requests/($number)/throttler")
  let body = {ratio: $ratio, configurations: $configurations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List maintenance schedules
#
# GET /organizations/{organization}/databases/{database}/maintenance-schedules
# operationId: list_maintenance_schedules
export def "organizations-databases-maintenance-schedules schedules" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, created_at: string, updated_at: string, last_window_datetime: string, next_window_datetime: string, duration: int, day: int, hour: int, week: int, frequency_value: int, frequency_unit: string, enabled: bool, expires_at: string, deadline_at: string, required: bool, pending_vitess_version_update: bool, pending_vitess_version: string, pending_mysql_version_update: bool, pending_mysql_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/maintenance-schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a maintenance schedule
#
# GET /organizations/{organization}/databases/{database}/maintenance-schedules/{id}
# operationId: get_maintenance_schedule
export def "organizations-databases-maintenance-schedules schedule" [
  id: string
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string, last_window_datetime: string, next_window_datetime: string, duration: int, day: int, hour: int, week: int, frequency_value: int, frequency_unit: string, enabled: bool, expires_at: string, deadline_at: string, required: bool, pending_vitess_version_update: bool, pending_vitess_version: string, pending_mysql_version_update: bool, pending_mysql_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/maintenance-schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List maintenance windows
#
# GET /organizations/{organization}/databases/{database}/maintenance-schedules/{id}/windows
# operationId: list_maintenance_windows
export def "organizations-databases-maintenance-schedules-windows windows" [
  id: string
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, created_at: string, updated_at: string, started_at: string, finished_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/maintenance-schedules/($id)/windows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List read-only regions
#
# GET /organizations/{organization}/databases/{database}/read-only-regions
# operationId: list_read_only_regions
export def "organizations-databases-read-only-regions regions" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, display_name: string, created_at: string, updated_at: string, ready_at: string, ready: bool, actor: record, region: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/read-only-regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List database regions
#
# GET /organizations/{organization}/databases/{database}/regions
# operationId: list_database_regions
export def "organizations-databases-regions regions" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, provider: string, enabled: bool, public_ip_addresses: list, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List schema recommendations
#
# GET /organizations/{organization}/databases/{database}/schema-recommendations
# operationId: list_schema_recommendations
export def "organizations-databases-schema-recommendations recommendations" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-3 # Filter by recommendation state
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, html_url: string, title: string, table_name: string, keyspace: string, ddl_statement: string, number: int, state: string, recommendation_type: string, created_at: string, updated_at: string, applied_at: string, dismissed_at: string, closed_by_deploy_request: record, dismissed_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/schema-recommendations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a schema recommendation
#
# GET /organizations/{organization}/databases/{database}/schema-recommendations/{number}
# operationId: get_schema_recommendation
export def "organizations-databases-schema-recommendations recommendation" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, html_url: string, title: string, table_name: string, keyspace: string, ddl_statement: string, number: int, state: string, recommendation_type: string, created_at: string, updated_at: string, applied_at: string, dismissed_at: string, closed_by_deploy_request: record<id: string, branch_id: string, number: int>, dismissed_by: record<id: string, display_name: string, avatar_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/schema-recommendations/($number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dismiss a schema recommendation
#
# POST /organizations/{organization}/databases/{database}/schema-recommendations/{number}/dismiss
# operationId: dismiss_schema_recommendation
export def "organizations-databases-schema-recommendations-dismiss recommendation" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # The reason for dismissing the recommendation (max 500 characters)
]: any -> record<id: string, html_url: string, title: string, table_name: string, keyspace: string, ddl_statement: string, number: int, state: string, recommendation_type: string, created_at: string, updated_at: string, applied_at: string, dismissed_at: string, closed_by_deploy_request: record<id: string, branch_id: string, number: int>, dismissed_by: record<id: string, display_name: string, avatar_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/schema-recommendations/($number)/dismiss")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get database throttler configurations
#
# GET /organizations/{organization}/databases/{database}/throttler
# operationId: get_database_throttler
export def "organizations-databases-throttler throttler-by-organization-database" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keyspaces: list<string>, configurable: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, configurations: table<keyspace_name: string, ratio: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/throttler")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update database throttler configurations
#
# PATCH /organizations/{organization}/databases/{database}/throttler
# operationId: update_database_throttler
export def "organizations-databases-throttler throttler-by-organization-database-1" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ratio: int # A throttler ratio between 0 and 95 that will apply to all keyspaces in the database. 0 effectively disables throttler, while 95 drastically slows down deploy request migrations
  --configurations: list # If specifying throttler ratios per keyspace, an array of { "keyspace_name": "mykeyspace", "ratio": 10 }, one for each eligible keyspace
]: any -> record<keyspaces: list<string>, configurable: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, configurations: table<keyspace_name: string, ratio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/throttler")
  let body = {ratio: $ratio, configurations: $configurations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List webhooks
#
# GET /organizations/{organization}/databases/{database}/webhooks
# operationId: list_webhooks
export def "organizations-databases-webhooks webhooks" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, url: string, secret: string, enabled: bool, last_sent_result: string, last_sent_success: bool, last_sent_at: string, created_at: string, updated_at: string, events: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /organizations/{organization}/databases/{database}/webhooks
# operationId: create_webhook
export def "organizations-databases-webhooks webhook-by-organization-database" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The URL the webhook will send events to
  --enabled: oneof<nothing, bool> # Whether the webhook should be enabled
  --events: list # The events this webhook should subscribe to
]: any -> record<id: string, url: string, secret: string, enabled: bool, last_sent_result: string, last_sent_success: bool, last_sent_at: string, created_at: string, updated_at: string, events: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/webhooks")
  let body = {url: $body_url, enabled: $enabled, events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a webhook
#
# GET /organizations/{organization}/databases/{database}/webhooks/{id}
# operationId: get_webhook
export def "organizations-databases-webhooks webhook-by-organization-database-id" [
  organization: string
  database: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, url: string, secret: string, enabled: bool, last_sent_result: string, last_sent_success: bool, last_sent_at: string, created_at: string, updated_at: string, events: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /organizations/{organization}/databases/{database}/webhooks/{id}
# operationId: update_webhook
export def "organizations-databases-webhooks webhook-by-organization-database-id-1" [
  organization: string
  database: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The URL the webhook will send events to
  --enabled: oneof<nothing, bool> # Whether the webhook should be enabled
  --events: list # The events this webhook should subscribe to
]: any -> record<id: string, url: string, secret: string, enabled: bool, last_sent_result: string, last_sent_success: bool, last_sent_at: string, created_at: string, updated_at: string, events: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/webhooks/($id)")
  let body = {url: $body_url, enabled: $enabled, events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /organizations/{organization}/databases/{database}/webhooks/{id}
# operationId: delete_webhook
export def "organizations-databases-webhooks webhook-by-organization-database-id-2" [
  organization: string
  database: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test a webhook
#
# POST /organizations/{organization}/databases/{database}/webhooks/{id}/test
# operationId: test_webhook
export def "organizations-databases-webhooks-test webhook" [
  organization: string
  database: string
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
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/webhooks/($id)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List workflows
#
# GET /organizations/{organization}/databases/{database}/workflows
# operationId: list_workflows
export def "organizations-databases-workflows workflows" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --between: string # Filter workflows to those active during a time range (e.g. 2025-01-01T00:00:00Z..2025-01-01T23:59:59)
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record, verify_data_by: record, reversed_by: record, switch_replicas_by: record, switch_primaries_by: record, cancelled_by: record, completed_by: record, retried_by: record, cutover_by: record, reversed_cutover_by: record, branch: record, source_keyspace: record, target_keyspace: record, global_keyspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "between" $between "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a workflow
#
# POST /organizations/{organization}/databases/{database}/workflows
# operationId: create_workflow
export def "organizations-databases-workflows workflow-by-organization-database" [
  organization: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name the workflow
  source_keyspace: string # Name of the source keyspace
  target_keyspace: string # Name of the target keyspace
  --global-keyspace: string # Name of the global sequence keyspace
  --defer-secondary-keys: oneof<nothing, bool> # Defer secondary keys
  --on-ddl: string@on-ddl-completer # The behavior when DDL changes during the workflow
  tables: list # List of tables to move
]: any -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows")
  let body = {name: $name, source_keyspace: $source_keyspace, target_keyspace: $target_keyspace, global_keyspace: $global_keyspace, defer_secondary_keys: $defer_secondary_keys, on_ddl: $on_ddl, tables: $tables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a workflow
#
# GET /organizations/{organization}/databases/{database}/workflows/{number}
# operationId: get_workflow
export def "organizations-databases-workflows workflow-by-organization-database-number" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a workflow
#
# DELETE /organizations/{organization}/databases/{database}/workflows/{number}
# operationId: workflow_cancel
export def "organizations-databases-workflows cancel" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete a workflow
#
# PATCH /organizations/{organization}/databases/{database}/workflows/{number}/complete
# operationId: workflow_complete
export def "organizations-databases-workflows-complete complete" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cutover traffic
#
# PATCH /organizations/{organization}/databases/{database}/workflows/{number}/cutover
# operationId: workflow_cutover
export def "organizations-databases-workflows-cutover cutover" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)/cutover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry a failed workflow
#
# PATCH /organizations/{organization}/databases/{database}/workflows/{number}/retry
# operationId: workflow_retry
export def "organizations-databases-workflows-retry retry" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reverse traffic cutover
#
# PATCH /organizations/{organization}/databases/{database}/workflows/{number}/reverse-cutover
# operationId: workflow_reverse_cutover
export def "organizations-databases-workflows-reverse-cutover cutover" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)/reverse-cutover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reverse traffic
#
# PATCH /organizations/{organization}/databases/{database}/workflows/{number}/reverse-traffic
# operationId: workflow_reverse_traffic
export def "organizations-databases-workflows-reverse-traffic traffic" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)/reverse-traffic")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Switch primary traffic
#
# PATCH /organizations/{organization}/databases/{database}/workflows/{number}/switch-primaries
# operationId: workflow_switch_primaries
export def "organizations-databases-workflows-switch-primaries primaries" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)/switch-primaries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Switch replica traffic
#
# PATCH /organizations/{organization}/databases/{database}/workflows/{number}/switch-replicas
# operationId: workflow_switch_replicas
export def "organizations-databases-workflows-switch-replicas replicas" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)/switch-replicas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify workflow data
#
# PATCH /organizations/{organization}/databases/{database}/workflows/{number}/verify-data
# operationId: verify_workflow
export def "organizations-databases-workflows-verify-data workflow" [
  organization: string
  database: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, number: int, state: string, created_at: string, updated_at: string, started_at: string, completed_at: string, cancelled_at: string, reversed_at: string, retried_at: string, data_copy_completed_at: string, cutover_at: string, replicas_switched: bool, primaries_switched: bool, switch_replicas_at: string, switch_primaries_at: string, verify_data_at: string, workflow_type: string, workflow_subtype: string, defer_secondary_keys: bool, on_ddl: string, workflow_errors: string, may_retry: bool, may_restart: bool, verified_data_stale: bool, sequence_tables_applied: bool, actor: record<id: string, display_name: string, avatar_url: string>, verify_data_by: record<id: string, display_name: string, avatar_url: string>, reversed_by: record<id: string, display_name: string, avatar_url: string>, switch_replicas_by: record<id: string, display_name: string, avatar_url: string>, switch_primaries_by: record<id: string, display_name: string, avatar_url: string>, cancelled_by: record<id: string, display_name: string, avatar_url: string>, completed_by: record<id: string, display_name: string, avatar_url: string>, retried_by: record<id: string, display_name: string, avatar_url: string>, cutover_by: record<id: string, display_name: string, avatar_url: string>, reversed_cutover_by: record<id: string, display_name: string, avatar_url: string>, branch: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, source_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, target_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, global_keyspace: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/databases/($database)/workflows/($number)/verify-data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoices
#
# GET /organizations/{organization}/invoices
# operationId: list_invoices
export def "organizations-invoices invoices" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, total: string, billing_period_start: string, billing_period_end: string, paid: bool, overdue: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an invoice
#
# GET /organizations/{organization}/invoices/{id}
# operationId: get_invoice
export def "organizations-invoices invoice" [
  organization: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, total: string, billing_period_start: string, billing_period_end: string, paid: bool, overdue: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/invoices/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice line items
#
# GET /organizations/{organization}/invoices/{id}/line-items
# operationId: get_invoice_line_items
export def "organizations-invoices-line-items items" [
  organization: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, subtotal: float, description: string, metric_name: string, cloudflare_billed: bool, database_id: string, database_name: string, resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/invoices/($id)/line-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List organization members
#
# GET /organizations/{organization}/members
# operationId: list_organization_members
export def "organizations-members members" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term to filter members by name or email
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, user: record, role: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an organization member
#
# GET /organizations/{organization}/members/{id}
# operationId: get_organization_membership
export def "organizations-members membership-by-organization-id" [
  organization: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, user: record<id: string, display_name: string, name: string, email: string, avatar_url: string, created_at: string, updated_at: string, two_factor_auth_configured: bool, default_organization: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, sso: bool, managed: bool, directory_managed: bool, email_verified: bool>, role: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/members/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update organization member role
#
# PATCH /organizations/{organization}/members/{id}
# operationId: update_organization_membership
export def "organizations-members membership-by-organization-id-1" [
  organization: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role: string # The role to assign to the member (e.g., 'admin', 'member'). Note: Cannot update your own role. Roles managed by IdP cannot be updated via API.
]: any -> record<id: string, user: record<id: string, display_name: string, name: string, email: string, avatar_url: string, created_at: string, updated_at: string, two_factor_auth_configured: bool, default_organization: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, sso: bool, managed: bool, directory_managed: bool, email_verified: bool>, role: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/members/($id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from an organization
#
# DELETE /organizations/{organization}/members/{id}
# operationId: remove_organization_member
export def "organizations-members member" [
  organization: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-passwords: oneof<nothing, bool> # Whether to delete all passwords associated with the member. Only available when removing other members (not yourself).
  --delete-service-tokens: oneof<nothing, bool> # Whether to delete all service tokens associated with the member. Only available when removing other members (not yourself).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_passwords" $delete_passwords "scalar") (serialize-qp "delete_service_tokens" $delete_service_tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/members/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List OAuth applications
#
# GET /organizations/{organization}/oauth-applications
# operationId: list_oauth_applications
export def "organizations-oauth-applications applications" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, redirect_uri: string, domain: string, created_at: string, updated_at: string, scopes: string, avatar: string, client_id: string, tokens: int, dcr: bool, single_org_authorization: bool, scopes_by_resource: record, all_scopes_by_resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/oauth-applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an OAuth application
#
# GET /organizations/{organization}/oauth-applications/{application_id}
# operationId: get_oauth_application
export def "organizations-oauth-applications application" [
  organization: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, redirect_uri: string, domain: string, created_at: string, updated_at: string, scopes: string, avatar: string, client_id: string, tokens: int, dcr: bool, single_org_authorization: bool, scopes_by_resource: record, all_scopes_by_resource: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/oauth-applications/($application_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List OAuth tokens
#
# GET /organizations/{organization}/oauth-applications/{application_id}/tokens
# operationId: list_oauth_tokens
export def "organizations-oauth-applications-tokens tokens" [
  organization: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, display_name: string, token: string, plain_text_refresh_token: string, avatar_url: string, created_at: string, updated_at: string, expires_at: string, last_used_at: string, actor_id: string, actor_display_name: string, actor_type: string, service_token_accesses: list, oauth_accesses_by_resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/oauth-applications/($application_id)/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an OAuth token
#
# GET /organizations/{organization}/oauth-applications/{application_id}/tokens/{token_id}
# operationId: get_oauth_token
export def "organizations-oauth-applications-tokens token-by-organization-application_id-token_id" [
  organization: string
  application_id: string
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, display_name: string, token: string, plain_text_refresh_token: string, avatar_url: string, created_at: string, updated_at: string, expires_at: string, last_used_at: string, actor_id: string, actor_display_name: string, actor_type: string, service_token_accesses: table<id: string, access: string, description: string, resource_name: string, resource_id: string, resource_type: string, resource: record>, oauth_accesses_by_resource: record<database: record<databases: list, accesses: list>, organization: record<organizations: list, accesses: list>, branch: record<branches: list, accesses: list>, user: record<users: list, accesses: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/oauth-applications/($application_id)/tokens/($token_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an OAuth token
#
# DELETE /organizations/{organization}/oauth-applications/{application_id}/tokens/{token_id}
# operationId: delete_oauth_token
export def "organizations-oauth-applications-tokens token-by-organization-application_id-token_id-1" [
  organization: string
  application_id: string
  token_id: string
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
  let full_url = (build-url $base $"/organizations/($organization)/oauth-applications/($application_id)/tokens/($token_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or renew an OAuth token
#
# POST /organizations/{organization}/oauth-applications/{id}/token
# operationId: create_oauth_token
export def "organizations-oauth-applications-token token" [
  organization: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # The OAuth application's client ID
  client_secret: string # The OAuth application's client secret
  grant_type: string@grant-type-completer # Whether an OAuth grant code or a refresh token is being exchanged for an OAuth token
  --code: string # The OAuth grant code provided to your OAuth application's redirect URI. Required when grant_type is authorization_code
  --redirect-uri: string # The OAuth application's redirect URI. Required when grant_type is authorization_code
  --refresh-token: string # The refresh token from the original OAuth token grant. Required when grant_type is refresh_token
]: any -> record<id: string, name: string, display_name: string, token: string, plain_text_refresh_token: string, avatar_url: string, created_at: string, updated_at: string, expires_at: string, last_used_at: string, actor_id: string, actor_display_name: string, actor_type: string, service_token_accesses: table<id: string, access: string, description: string, resource_name: string, resource_id: string, resource_type: string, resource: record>, oauth_accesses_by_resource: record<database: record<databases: list, accesses: list>, organization: record<organizations: list, accesses: list>, branch: record<branches: list, accesses: list>, user: record<users: list, accesses: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/oauth-applications/($id)/token")
  let body = {client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, code: $code, redirect_uri: $redirect_uri, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List regions for an organization
#
# GET /organizations/{organization}/regions
# operationId: list_regions_for_organization
export def "organizations-regions organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, provider: string, enabled: bool, public_ip_addresses: list, display_name: string, location: string, slug: string, current_default: bool, mysql_supported: bool, postgresql_supported: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List service tokens
#
# GET /organizations/{organization}/service-tokens
# operationId: list_service_tokens
export def "organizations-service-tokens tokens" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, name: string, display_name: string, token: string, plain_text_refresh_token: string, avatar_url: string, created_at: string, updated_at: string, expires_at: string, last_used_at: string, actor_id: string, actor_display_name: string, actor_type: string, service_token_accesses: list, oauth_accesses_by_resource: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/service-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a service token
#
# POST /organizations/{organization}/service-tokens
# operationId: create_service_token
export def "organizations-service-tokens token-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the service token
  --ttl: int # Time to live (in seconds) for the service token. The token will be invalid when TTL has passed
]: any -> record<id: string, name: string, display_name: string, token: string, plain_text_refresh_token: string, avatar_url: string, created_at: string, updated_at: string, expires_at: string, last_used_at: string, actor_id: string, actor_display_name: string, actor_type: string, service_token_accesses: table<id: string, access: string, description: string, resource_name: string, resource_id: string, resource_type: string, resource: record>, oauth_accesses_by_resource: record<database: record<databases: list, accesses: list>, organization: record<organizations: list, accesses: list>, branch: record<branches: list, accesses: list>, user: record<users: list, accesses: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/service-tokens")
  let body = {name: $name, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a service token
#
# GET /organizations/{organization}/service-tokens/{id}
# operationId: get_service_token
export def "organizations-service-tokens token-by-organization-id" [
  organization: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, display_name: string, token: string, plain_text_refresh_token: string, avatar_url: string, created_at: string, updated_at: string, expires_at: string, last_used_at: string, actor_id: string, actor_display_name: string, actor_type: string, service_token_accesses: table<id: string, access: string, description: string, resource_name: string, resource_id: string, resource_type: string, resource: record>, oauth_accesses_by_resource: record<database: record<databases: list, accesses: list>, organization: record<organizations: list, accesses: list>, branch: record<branches: list, accesses: list>, user: record<users: list, accesses: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/service-tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a service token
#
# DELETE /organizations/{organization}/service-tokens/{id}
# operationId: delete_service_token
export def "organizations-service-tokens token-by-organization-id-1" [
  organization: string
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
  let full_url = (build-url $base $"/organizations/($organization)/service-tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List teams in an organization
#
# GET /organizations/{organization}/teams
# operationId: list_organization_teams
export def "organizations-teams teams" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term to filter teams by name
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, display_name: string, creator: record, members: list, databases: list, analyst_databases: list, name: string, slug: string, created_at: string, updated_at: string, description: string, managed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organization team
#
# POST /organizations/{organization}/teams
# operationId: create_organization_team
export def "organizations-teams team-by-organization" [
  organization: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the team
  --description: string # A description of the team's purpose
]: any -> record<id: string, display_name: string, creator: record<id: string, display_name: string, avatar_url: string>, members: table<id: string, display_name: string, name: string, email: string, avatar_url: string, created_at: string, updated_at: string, two_factor_auth_configured: bool, default_organization: record, sso: bool, managed: bool, directory_managed: bool, email_verified: bool>, databases: table<id: string, name: string, url: string, branches_url: string>, analyst_databases: table<id: string, name: string, url: string, branches_url: string>, name: string, slug: string, created_at: string, updated_at: string, description: string, managed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/teams")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an organization team
#
# GET /organizations/{organization}/teams/{team}
# operationId: get_organization_team
export def "organizations-teams team-by-organization-team" [
  organization: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, display_name: string, creator: record<id: string, display_name: string, avatar_url: string>, members: table<id: string, display_name: string, name: string, email: string, avatar_url: string, created_at: string, updated_at: string, two_factor_auth_configured: bool, default_organization: record, sso: bool, managed: bool, directory_managed: bool, email_verified: bool>, databases: table<id: string, name: string, url: string, branches_url: string>, analyst_databases: table<id: string, name: string, url: string, branches_url: string>, name: string, slug: string, created_at: string, updated_at: string, description: string, managed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/teams/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization team
#
# PATCH /organizations/{organization}/teams/{team}
# operationId: update_organization_team
export def "organizations-teams team-by-organization-team-1" [
  organization: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the team
  --description: string # The new description for the team
]: any -> record<id: string, display_name: string, creator: record<id: string, display_name: string, avatar_url: string>, members: table<id: string, display_name: string, name: string, email: string, avatar_url: string, created_at: string, updated_at: string, two_factor_auth_configured: bool, default_organization: record, sso: bool, managed: bool, directory_managed: bool, email_verified: bool>, databases: table<id: string, name: string, url: string, branches_url: string>, analyst_databases: table<id: string, name: string, url: string, branches_url: string>, name: string, slug: string, created_at: string, updated_at: string, description: string, managed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/teams/($team)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an organization team
#
# DELETE /organizations/{organization}/teams/{team}
# operationId: delete_organization_team
export def "organizations-teams team-by-organization-team-2" [
  organization: string
  team: string
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
  let full_url = (build-url $base $"/organizations/($organization)/teams/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List team members
#
# GET /organizations/{organization}/teams/{team}/members
# operationId: list_organization_team_members
export def "organizations-teams-members members" [
  organization: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, user: record, actor: record, created_at: string, updated_at: string, passwords: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/teams/($team)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to a team
#
# POST /organizations/{organization}/teams/{team}/members
# operationId: add_organization_team_member
export def "organizations-teams-members member-by-organization-team" [
  organization: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # The ID of the organization member to add to the team
]: any -> record<id: string, user: record<id: string, display_name: string, name: string, email: string, avatar_url: string, created_at: string, updated_at: string, two_factor_auth_configured: bool, default_organization: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, sso: bool, managed: bool, directory_managed: bool, email_verified: bool>, actor: record<id: string, display_name: string, avatar_url: string>, created_at: string, updated_at: string, passwords: table<id: string, name: string, role: string, cidrs: list, created_at: string, deleted_at: string, expires_at: string, last_used_at: string, expired: bool, direct_vtgate: bool, direct_vtgate_addresses: list, ttl_seconds: int, access_host_url: string, access_host_regional_url: string, access_host_regional_urls: list, actor: record, region: record, username: string, plain_text: string, replica: bool, renewable: bool, database_branch: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/teams/($team)/members")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a team member
#
# GET /organizations/{organization}/teams/{team}/members/{id}
# operationId: get_organization_team_member
export def "organizations-teams-members member-by-organization-team-id" [
  organization: string
  team: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, user: record<id: string, display_name: string, name: string, email: string, avatar_url: string, created_at: string, updated_at: string, two_factor_auth_configured: bool, default_organization: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, sso: bool, managed: bool, directory_managed: bool, email_verified: bool>, actor: record<id: string, display_name: string, avatar_url: string>, created_at: string, updated_at: string, passwords: table<id: string, name: string, role: string, cidrs: list, created_at: string, deleted_at: string, expires_at: string, last_used_at: string, expired: bool, direct_vtgate: bool, direct_vtgate_addresses: list, ttl_seconds: int, access_host_url: string, access_host_regional_url: string, access_host_regional_urls: list, actor: record, region: record, username: string, plain_text: string, replica: bool, renewable: bool, database_branch: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organization)/teams/($team)/members/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a member from a team
#
# DELETE /organizations/{organization}/teams/{team}/members/{id}
# operationId: remove_organization_team_member
export def "organizations-teams-members member-by-organization-team-id-1" [
  organization: string
  team: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-passwords: oneof<nothing, bool> # Whether to delete the member's passwords created through this team
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delete_passwords" $delete_passwords "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organization)/teams/($team)/members/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List public regions
#
# GET /regions
# operationId: list_public_regions
export def "regions regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # If provided, specifies the page offset of returned results (default: 1)
  --per-page: int # If provided, specifies the number of returned results (default: 25)
]: nothing -> record<type: string, current_page: int, next_page: int, next_page_url: string, prev_page: int, prev_page_url: string, data: table<id: string, provider: string, enabled: bool, public_ip_addresses: list, display_name: string, location: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current user
#
# GET /user
# operationId: get_current_user
export def "user user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, display_name: string, name: string, email: string, avatar_url: string, created_at: string, updated_at: string, two_factor_auth_configured: bool, default_organization: record<id: string, name: string, created_at: string, updated_at: string, deleted_at: string>, sso: bool, managed: bool, directory_managed: bool, email_verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
