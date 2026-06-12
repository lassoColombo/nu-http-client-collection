# Auto-generated client for Supabase API (v1) v1.0.0
# Source: https://api.supabase.com/api/v1-json
# Auth: --token flag or $env.SUPABASE_API_V1_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUPABASE_API_V1_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["CREATING_PROJECT" "FUNCTIONS_DEPLOYED" "FUNCTIONS_FAILED" "MIGRATIONS_FAILED" "MIGRATIONS_PASSED" "RUNNING_MIGRATIONS"] }
def plan-completer [] { ["free" "pro"] }
def region-completer [] { ["ap-east-1" "ap-northeast-1" "ap-northeast-2" "ap-south-1" "ap-southeast-1" "ap-southeast-2" "ca-central-1" "eu-central-1" "eu-central-2" "eu-north-1" "eu-west-1" "eu-west-2" "eu-west-3" "sa-east-1" "us-east-1" "us-east-2" "us-west-1" "us-west-2"] }
def desired-instance-size-completer [] { ["12xlarge" "16xlarge" "24xlarge" "24xlarge_high_memory" "24xlarge_optimized_cpu" "24xlarge_optimized_memory" "2xlarge" "48xlarge" "48xlarge_high_memory" "48xlarge_optimized_cpu" "48xlarge_optimized_memory" "4xlarge" "8xlarge" "large" "medium" "micro" "nano" "small" "xlarge"] }
def continent-completer [] { ["AF" "AN" "AS" "EU" "NA" "OC" "SA"] }
def response-type-completer [] { ["code" "id_token token" "token"] }
def code-challenge-method-completer [] { ["S256" "plain" "sha256"] }
def grant-type-completer [] { ["authorization_code" "refresh_token" "urn:ietf:params:oauth:grant-type:jwt-bearer"] }
def sort-by-completer [] { ["inserted_at" "name"] }
def sort-order-completer [] { ["asc" "desc"] }
def clone-completer [] { ["CREATED" "DEAD" "EXITED" "PAUSED" "REMOVING" "RESTARTING" "RUNNING"] }
def pull-completer [] { ["CREATED" "DEAD" "EXITED" "PAUSED" "REMOVING" "RESTARTING" "RUNNING"] }
def health-completer [] { ["CREATED" "DEAD" "EXITED" "PAUSED" "REMOVING" "RESTARTING" "RUNNING"] }
def configure-completer [] { ["CREATED" "DEAD" "EXITED" "PAUSED" "REMOVING" "RESTARTING" "RUNNING"] }
def migrate-completer [] { ["CREATED" "DEAD" "EXITED" "PAUSED" "REMOVING" "RESTARTING" "RUNNING"] }
def seed-completer [] { ["CREATED" "DEAD" "EXITED" "PAUSED" "REMOVING" "RESTARTING" "RUNNING"] }
def deploy-completer [] { ["CREATED" "DEAD" "EXITED" "PAUSED" "REMOVING" "RESTARTING" "RUNNING"] }
def type-completer [] { ["publishable" "secret"] }
def desired-instance-size-completer-1 [] { ["12xlarge" "16xlarge" "24xlarge" "24xlarge_high_memory" "24xlarge_optimized_cpu" "24xlarge_optimized_memory" "2xlarge" "48xlarge" "48xlarge_high_memory" "48xlarge_optimized_cpu" "48xlarge_optimized_memory" "4xlarge" "8xlarge" "large" "medium" "micro" "nano" "pico" "small" "xlarge"] }
def release-channel-completer [] { ["alpha" "beta" "ga" "internal" "preview" "withdrawn"] }
def postgres-engine-completer [] { ["15" "17" "17-oriole"] }
def state-completer [] { ["disabled" "enabled"] }
def read-replica-region-completer [] { ["ap-east-1" "ap-northeast-1" "ap-northeast-2" "ap-south-1" "ap-southeast-1" "ap-southeast-2" "ca-central-1" "eu-central-1" "eu-central-2" "eu-north-1" "eu-west-1" "eu-west-2" "eu-west-3" "sa-east-1" "us-east-1" "us-east-2" "us-west-1" "us-west-2"] }
def algorithm-completer [] { ["ES256" "EdDSA" "HS256" "RS256"] }
def status-completer-1 [] { ["in_use" "standby"] }
def status-completer-2 [] { ["in_use" "previously_used" "revoked" "standby"] }
def security-captcha-provider-completer [] { ["hcaptcha" "turnstile"] }
def password-required-characters-completer [] { ["" "abcdefghijklmnopqrstuvwxyz:ABCDEFGHIJKLMNOPQRSTUVWXYZ:0123456789" "abcdefghijklmnopqrstuvwxyz:ABCDEFGHIJKLMNOPQRSTUVWXYZ:0123456789:!@#$%^&*()_+-=[]{};'\\:"|<>?,./`~" "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ:0123456789"] }
def sms-provider-completer [] { ["messagebird" "textlocal" "twilio" "twilio_verify" "vonage"] }
def db-max-pool-size-unit-completer [] { ["connections" "percent"] }
def addon-type-completer [] { ["auth_mfa_phone" "auth_mfa_web_authn" "compute_instance" "custom_domain" "ipv4" "log_drain" "pitr"] }
def lint-type-completer [] { ["sql"] }
def interval-completer [] { ["15min" "1day" "1hr" "30min" "3day" "3hr" "7day"] }
def interval-completer-1 [] { ["15min" "1day" "1hr" "3hr"] }
def pool-mode-completer [] { ["session" "transaction"] }
def session-replication-role-completer [] { ["local" "origin" "replica"] }
def type-completer-1 [] { ["saml"] }
def name-id-format-completer [] { ["urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress" "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified" "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"] }
def sort-completer [] { ["created_asc" "created_desc" "name_asc" "name_desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "branches v1-get-a-branch-config" } } | get name | first)
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

# Get database branch config
#
# GET /v1/branches/{branch_id_or_ref}
# operationId: v1-get-a-branch-config
export def "branches v1-get-a-branch-config" [
  branch_id_or_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ref: string, postgres_version: string, postgres_engine: string, release_channel: string, status: string, db_host: string, db_port: int, db_user: string, db_pass: string, jwt_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/branches/($branch_id_or_ref)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update database branch config
#
# PATCH /v1/branches/{branch_id_or_ref}
# operationId: v1-update-a-branch-config
@deprecated --flag reset-on-push
export def "branches v1-update-a-branch-config" [
  branch_id_or_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-name: string
  --git-branch: string
  --reset-on-push: oneof<nothing, bool> # This field is deprecated and will be ignored. Use v1-reset-a-branch endpoint directly instead. (DEPRECATED)
  --persistent: oneof<nothing, bool>
  --status: string@status-completer
  --request-review: oneof<nothing, bool>
  --notify-url: string # HTTP endpoint to receive branch status updates. (format: uri)
]: any -> record<id: string, name: string, project_ref: string, parent_project_ref: string, is_default: bool, git_branch: string, pr_number: int, latest_check_run_id: float, persistent: bool, status: string, created_at: string, updated_at: string, review_requested_at: string, with_data: bool, notify_url: string, deletion_scheduled_at: string, preview_project_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/branches/($branch_id_or_ref)")
  let body = {branch_name: $branch_name, git_branch: $git_branch, reset_on_push: $reset_on_push, persistent: $persistent, status: $status, request_review: $request_review, notify_url: $notify_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a database branch
#
# DELETE /v1/branches/{branch_id_or_ref}
# operationId: v1-delete-a-branch
export def "branches v1-delete-a-branch" [
  branch_id_or_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If set to false, schedule deletion with 1-hour grace period (only when soft deletion is enabled). (default: true, e.g. false)
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/branches/($branch_id_or_ref)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pushes a database branch
#
# POST /v1/branches/{branch_id_or_ref}/push
# operationId: v1-push-a-branch
export def "branches-push v1-push-a-branch" [
  branch_id_or_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --migration-version: string
]: any -> record<workflow_run_id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/branches/($branch_id_or_ref)/push")
  let body = {migration_version: $migration_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Merges a database branch
#
# POST /v1/branches/{branch_id_or_ref}/merge
# operationId: v1-merge-a-branch
export def "branches-merge v1-merge-a-branch" [
  branch_id_or_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --migration-version: string
]: any -> record<workflow_run_id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/branches/($branch_id_or_ref)/merge")
  let body = {migration_version: $migration_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resets a database branch
#
# POST /v1/branches/{branch_id_or_ref}/reset
# operationId: v1-reset-a-branch
export def "branches-reset v1-reset-a-branch" [
  branch_id_or_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --migration-version: string
]: any -> record<workflow_run_id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/branches/($branch_id_or_ref)/reset")
  let body = {migration_version: $migration_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restore a scheduled branch deletion
#
# POST /v1/branches/{branch_id_or_ref}/restore
# operationId: v1-restore-a-branch
export def "branches-restore v1-restore-a-branch" [
  branch_id_or_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/branches/($branch_id_or_ref)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Diffs a database branch
#
# GET /v1/branches/{branch_id_or_ref}/diff
# operationId: v1-diff-a-branch
export def "branches-diff v1-diff-a-branch" [
  branch_id_or_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --included-schemas: string # e.g. public,auth
  --pgdelta: oneof<nothing, bool> # Use pg-delta instead of Migra for diffing when true (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "included_schemas" $included_schemas "scalar") (serialize-qp "pgdelta" $pgdelta "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/branches/($branch_id_or_ref)/diff" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all projects
#
# GET /v1/projects
# operationId: v1-list-all-projects
export def "projects v1-list-all-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, ref: string, organization_id: string, organization_slug: string, name: string, region: string, created_at: string, status: string, database: record<host: string, version: string, postgres_engine: string, release_channel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project
#
# POST /v1/projects
# operationId: v1-create-a-project
@deprecated --flag organization-id
@deprecated --flag plan
@deprecated --flag region
@deprecated --flag kps-enabled
export def "projects v1-create-a-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  db_pass: string # Database password
  name: string # Name of your project
  --organization-id: string # Deprecated: Use `organization_slug` instead. (DEPRECATED)
  organization_slug: string # Organization slug (e.g. tsrqponmlkjihgfedcba)
  --plan: string@plan-completer # Subscription Plan is now set on organization level and is ignored in this request (DEPRECATED)
  --region: string@region-completer # Region you want your server to reside in. Use region_selection instead. (DEPRECATED)
  --region-selection: any # Region selection. Only one of region or region_selection can be specified.
  --kps-enabled: oneof<nothing, bool> # This field is deprecated and is ignored in this request (DEPRECATED)
  --desired-instance-size: string@desired-instance-size-completer # Desired instance size. Omit this field to always default to the smallest possible size.
  --template-url: string # Template URL used to create the project from the CLI. (format: uri)
]: any -> record<id: string, ref: string, organization_id: string, organization_slug: string, name: string, region: string, created_at: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/projects")
  let body = {db_pass: $db_pass, name: $name, organization_id: $organization_id, organization_slug: $organization_slug, plan: $plan, region: $region, region_selection: $region_selection, kps_enabled: $kps_enabled, desired_instance_size: $desired_instance_size, template_url: $template_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Gets the list of available regions that can be used for a new project
#
# GET /v1/projects/available-regions
# operationId: v1-get-available-regions
export def "projects-available-regions v1-get-available-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-slug: string # Slug of your organization (e.g. tsrqponmlkjihgfedcba)
  --continent: string@continent-completer # Continent code to determine regional recommendations: NA (North America), SA (South America), EU (Europe), AF (Africa), AS (Asia), OC (Oceania), AN (Antarctica) (e.g. NA)
  --desired-instance-size: string@desired-instance-size-completer # Desired instance size. Omit this field to always default to the smallest possible size.
]: nothing -> record<recommendations: record<smartGroup: record<name: string, code: string, type: string>, specific: list<record>>, all: record<smartGroup: list<record>, specific: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_slug" $organization_slug "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "desired_instance_size" $desired_instance_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/projects/available-regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all organizations
#
# GET /v1/organizations
# operationId: v1-list-all-organizations
export def "organizations v1-list-all-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, slug: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /v1/organizations
# operationId: v1-create-an-organization
export def "organizations v1-create-an-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: string, slug: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Authorize user through oauth
#
# GET /v1/oauth/authorize
# operationId: v1-authorize-user
export def "oauth-authorize v1-authorize-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # format: uuid, e.g. 66666666-6666-4666-8666-666666666666
  --response-type: string@response-type-completer # e.g. code
  --redirect-uri: string # e.g. https://app.acme.com/auth/callback
  --scope: string # e.g. projects:read projects:write
  --state: string # e.g. st_9f4d3a206b2e4a7e8c91
  --response-mode: string # e.g. query
  --code-challenge: string # e.g. Z_P4EKbGwIkA01e3Y5fp4tMCvn_Ae5nUw7qY7XwkTrQ
  --code-challenge-method: string@code-challenge-method-completer # e.g. S256
  --organization-slug: string # Organization slug (e.g. tsrqponmlkjihgfedcba)
  --resource: string # Resource indicator for MCP (Model Context Protocol) clients (format: uri)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "response_type" $response_type "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "response_mode" $response_mode "scalar") (serialize-qp "code_challenge" $code_challenge "scalar") (serialize-qp "code_challenge_method" $code_challenge_method "scalar") (serialize-qp "organization_slug" $organization_slug "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/oauth/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Exchange auth code for user's access and refresh token
#
# POST /v1/oauth/token
# operationId: v1-exchange-oauth-token
export def "oauth-token v1-exchange-oauth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --grant-type: string@grant-type-completer
  --client-id: string # format: uuid
  --client-secret: string
  --code: string
  --code-verifier: string
  --redirect-uri: string
  --refresh-token: string
  --assertion: string # IDJAG assertion JWT for grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer. Beta - available on Team and Enterprise plans only.
  --resource: string # Resource indicator for MCP (Model Context Protocol) clients (format: uri)
  --scope: string
]: any -> record<access_token: string, refresh_token: string, expires_in: int, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/token")
  let body = {grant_type: $grant_type, client_id: $client_id, client_secret: $client_secret, code: $code, code_verifier: $code_verifier, redirect_uri: $redirect_uri, refresh_token: $refresh_token, assertion: $assertion, resource: $resource, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# [Beta] Revoke oauth app authorization and it's corresponding tokens
#
# POST /v1/oauth/revoke
# operationId: v1-revoke-token
export def "oauth-revoke v1-revoke-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # format: uuid
  client_secret: string
  refresh_token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/revoke")
  let body = {client_id: $client_id, client_secret: $client_secret, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorize user through oauth and claim a project
#
# GET /v1/oauth/authorize/project-claim
# operationId: v1-oauth-authorize-project-claim
export def "oauth-authorize-project-claim v1-oauth-authorize-project-claim" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-ref: string # Project ref (e.g. abcdefghijklmnopqrst)
  --client-id: string # format: uuid, e.g. 66666666-6666-4666-8666-666666666666
  --response-type: string@response-type-completer # e.g. code
  --redirect-uri: string # e.g. https://app.acme.com/auth/callback
  --state: string # e.g. st_9f4d3a206b2e4a7e8c91
  --response-mode: string # e.g. query
  --code-challenge: string # e.g. Z_P4EKbGwIkA01e3Y5fp4tMCvn_Ae5nUw7qY7XwkTrQ
  --code-challenge-method: string@code-challenge-method-completer # e.g. S256
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_ref" $project_ref "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "response_type" $response_type "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "response_mode" $response_mode "scalar") (serialize-qp "code_challenge" $code_challenge "scalar") (serialize-qp "code_challenge_method" $code_challenge_method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/oauth/authorize/project-claim" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists SQL snippets for the logged in user
#
# GET /v1/snippets
# operationId: v1-list-all-snippets
export def "snippets v1-list-all-snippets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-ref: string # Project ref (e.g. abcdefghijklmnopqrst)
  --cursor: string
  --limit: string
  --sort-by: string@sort-by-completer
  --sort-order: string@sort-order-completer
]: nothing -> record<data: table<id: string, inserted_at: string, updated_at: string, type: string, visibility: string, name: string, description: string, project: record, owner: record, updated_by: record, favorite: bool>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_ref" $project_ref "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/snippets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a specific SQL snippet
#
# GET /v1/snippets/{id}
# operationId: v1-get-a-snippet
export def "snippets v1-get-a-snippet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, inserted_at: string, updated_at: string, type: string, visibility: string, name: string, description: string, project: record<id: float, name: string>, owner: record<id: float, username: string>, updated_by: record<id: float, username: string>, favorite: bool, content: record<favorite: bool, schema_version: string, sql: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/snippets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the user's profile
#
# GET /v1/profile
# operationId: v1-get-profile
export def "profile v1-get-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<gotrue_id: string, primary_email: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all action runs
#
# GET /v1/projects/{ref}/actions
# operationId: v1-list-action-runs
export def "projects-actions v1-list-action-runs" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # e.g. 0
  --limit: float # e.g. 20
]: nothing -> table<id: string, branch_id: string, run_steps: list<record>, git_config: any, workdir: string, check_run_id: float, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count the number of action runs
#
# HEAD /v1/projects/{ref}/actions
# operationId: v1-count-action-runs
export def "projects-actions v1-count-action-runs" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the status of an action run
#
# GET /v1/projects/{ref}/actions/{run_id}
# operationId: v1-get-action-run
export def "projects-actions v1-get-action-run" [
  ref: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, branch_id: string, run_steps: table<name: string, status: string, created_at: string, updated_at: string>, git_config: any, workdir: string, check_run_id: float, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/actions/($run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the status of an action run
#
# PATCH /v1/projects/{ref}/actions/{run_id}/status
# operationId: v1-update-action-run-status
export def "projects-actions-status v1-update-action-run-status" [
  ref: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clone: string@clone-completer
  --pull: string@pull-completer
  --health: string@health-completer
  --configure: string@configure-completer
  --migrate: string@migrate-completer
  --seed: string@seed-completer
  --deploy: string@deploy-completer
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/actions/($run_id)/status")
  let body = {clone: $clone, pull: $pull, health: $health, configure: $configure, migrate: $migrate, seed: $seed, deploy: $deploy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the logs of an action run
#
# GET /v1/projects/{ref}/actions/{run_id}/logs
# operationId: v1-get-action-run-logs
export def "projects-actions-logs v1-get-action-run-logs" [
  ref: string
  run_id: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/actions/($run_id)/logs")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project api keys
#
# GET /v1/projects/{ref}/api-keys
# operationId: v1-get-project-api-keys
export def "projects-api-keys v1-get-project-api-keys" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reveal: oneof<nothing, bool> # Boolean string, true or false (e.g. true)
]: nothing -> table<api_key: string, id: string, type: string, prefix: string, name: string, description: string, hash: string, secret_jwt_template: record, inserted_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reveal" $reveal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/api-keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new API key for the project
#
# POST /v1/projects/{ref}/api-keys
# operationId: v1-create-project-api-key
export def "projects-api-keys v1-create-project-api-key" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reveal: oneof<nothing, bool> # Boolean string, true or false (e.g. true)
  type: string@type-completer
  name: string
  --description: string # nullable
  --secret-jwt-template: record # nullable
]: any -> record<api_key: string, id: string, type: string, prefix: string, name: string, description: string, hash: string, secret_jwt_template: record, inserted_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reveal" $reveal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/api-keys" $qp)
  let body = {type: $type, name: $name, description: $description, secret_jwt_template: $secret_jwt_template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check whether JWT based legacy (anon, service_role) API keys are enabled. This API endpoint will be removed in the future, check for HTTP 404 Not Found.
#
# GET /v1/projects/{ref}/api-keys/legacy
# operationId: v1-get-project-legacy-api-keys
export def "projects-api-keys-legacy v1-get-project-legacy-api-keys" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/api-keys/legacy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable or re-enable JWT based legacy (anon, service_role) API keys. This API endpoint will be removed in the future, check for HTTP 404 Not Found.
#
# PUT /v1/projects/{ref}/api-keys/legacy
# operationId: v1-update-project-legacy-api-keys
export def "projects-api-keys-legacy v1-update-project-legacy-api-keys" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Boolean string, true or false (e.g. true)
]: nothing -> record<enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/api-keys/legacy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an API key for the project
#
# PATCH /v1/projects/{ref}/api-keys/{id}
# operationId: v1-update-project-api-key
export def "projects-api-keys v1-update-project-api-key" [
  ref: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reveal: oneof<nothing, bool> # Boolean string, true or false (e.g. true)
  --name: string
  --description: string # nullable
  --secret-jwt-template: record # nullable
]: any -> record<api_key: string, id: string, type: string, prefix: string, name: string, description: string, hash: string, secret_jwt_template: record, inserted_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reveal" $reveal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/api-keys/($id)" $qp)
  let body = {name: $name, description: $description, secret_jwt_template: $secret_jwt_template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get API key
#
# GET /v1/projects/{ref}/api-keys/{id}
# operationId: v1-get-project-api-key
export def "projects-api-keys v1-get-project-api-key" [
  ref: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reveal: oneof<nothing, bool> # Boolean string, true or false (e.g. true)
]: nothing -> record<api_key: string, id: string, type: string, prefix: string, name: string, description: string, hash: string, secret_jwt_template: record, inserted_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reveal" $reveal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/api-keys/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an API key for the project
#
# DELETE /v1/projects/{ref}/api-keys/{id}
# operationId: v1-delete-project-api-key
export def "projects-api-keys v1-delete-project-api-key" [
  ref: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reveal: oneof<nothing, bool> # Boolean string, true or false (e.g. true)
  --was-compromised: oneof<nothing, bool> # Boolean string, true or false (e.g. false)
  --reason: string # e.g. rotating_key
]: nothing -> record<api_key: string, id: string, type: string, prefix: string, name: string, description: string, hash: string, secret_jwt_template: record, inserted_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reveal" $reveal "scalar") (serialize-qp "was_compromised" $was_compromised "scalar") (serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/api-keys/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all database branches
#
# GET /v1/projects/{ref}/branches
# operationId: v1-list-all-branches
export def "projects-branches v1-list-all-branches" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, project_ref: string, parent_project_ref: string, is_default: bool, git_branch: string, pr_number: int, latest_check_run_id: float, persistent: bool, status: string, created_at: string, updated_at: string, review_requested_at: string, with_data: bool, notify_url: string, deletion_scheduled_at: string, preview_project_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a database branch
#
# POST /v1/projects/{ref}/branches
# operationId: v1-create-a-branch
export def "projects-branches v1-create-a-branch" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branch_name: string
  --git-branch: string
  --is-default: oneof<nothing, bool>
  --persistent: oneof<nothing, bool>
  --region: string
  --desired-instance-size: string@desired-instance-size-completer-1
  --release-channel: string@release-channel-completer # Release channel. If not provided, GA will be used.
  --postgres-engine: string@postgres-engine-completer # Postgres engine version. If not provided, the latest version will be used.
  --secrets: record
  --with-data: oneof<nothing, bool>
  --notify-url: string # HTTP endpoint to receive branch status updates. (format: uri)
]: any -> record<id: string, name: string, project_ref: string, parent_project_ref: string, is_default: bool, git_branch: string, pr_number: int, latest_check_run_id: float, persistent: bool, status: string, created_at: string, updated_at: string, review_requested_at: string, with_data: bool, notify_url: string, deletion_scheduled_at: string, preview_project_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/branches")
  let body = {branch_name: $branch_name, git_branch: $git_branch, is_default: $is_default, persistent: $persistent, region: $region, desired_instance_size: $desired_instance_size, release_channel: $release_channel, postgres_engine: $postgres_engine, secrets: $secrets, with_data: $with_data, notify_url: $notify_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disables preview branching
#
# DELETE /v1/projects/{ref}/branches
# operationId: v1-disable-preview-branching
export def "projects-branches v1-disable-preview-branching" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a database branch
#
# GET /v1/projects/{ref}/branches/{name}
# operationId: v1-get-a-branch
export def "projects-branches v1-get-a-branch" [
  ref: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, project_ref: string, parent_project_ref: string, is_default: bool, git_branch: string, pr_number: int, latest_check_run_id: float, persistent: bool, status: string, created_at: string, updated_at: string, review_requested_at: string, with_data: bool, notify_url: string, deletion_scheduled_at: string, preview_project_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/branches/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Gets project's custom hostname config
#
# GET /v1/projects/{ref}/custom-hostname
# operationId: v1-get-hostname-config
export def "projects-custom-hostname v1-get-hostname-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, custom_hostname: string, data: record<success: bool, errors: list<any>, messages: list<any>, result: record<id: string, hostname: string, ssl: record, ownership_verification: record, custom_origin_server: string, verification_errors: list, status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/custom-hostname")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Deletes a project's custom hostname configuration
#
# DELETE /v1/projects/{ref}/custom-hostname
# operationId: v1-Delete hostname config
export def "projects-custom-hostname v1-Delete-hostname-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --remove-addon: oneof<nothing, bool> # If true, also removes the custom domain add-on from the project subscription. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remove_addon" $remove_addon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/custom-hostname" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Updates project's custom hostname configuration
#
# POST /v1/projects/{ref}/custom-hostname/initialize
# operationId: v1-update-hostname-config
export def "projects-custom-hostname-initialize v1-update-hostname-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  custom_hostname: string
]: any -> record<status: string, custom_hostname: string, data: record<success: bool, errors: list<any>, messages: list<any>, result: record<id: string, hostname: string, ssl: record, ownership_verification: record, custom_origin_server: string, verification_errors: list, status: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/custom-hostname/initialize")
  let body = {custom_hostname: $custom_hostname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Attempts to verify the DNS configuration for project's custom hostname configuration
#
# POST /v1/projects/{ref}/custom-hostname/reverify
# operationId: v1-verify-dns-config
export def "projects-custom-hostname-reverify v1-verify-dns-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, custom_hostname: string, data: record<success: bool, errors: list<any>, messages: list<any>, result: record<id: string, hostname: string, ssl: record, ownership_verification: record, custom_origin_server: string, verification_errors: list, status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/custom-hostname/reverify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Activates a custom hostname for a project.
#
# POST /v1/projects/{ref}/custom-hostname/activate
# operationId: v1-activate-custom-hostname
export def "projects-custom-hostname-activate v1-activate-custom-hostname" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, custom_hostname: string, data: record<success: bool, errors: list<any>, messages: list<any>, result: record<id: string, hostname: string, ssl: record, ownership_verification: record, custom_origin_server: string, verification_errors: list, status: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/custom-hostname/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Get project's temporary access configuration.
#
# GET /v1/projects/{ref}/jit-access
# Discriminator (response): state
# operationId: v1-get-jit-access-config
export def "projects-jit-access v1-get-jit-access-config" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/jit-access")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Update project's temporary access configuration.
#
# PUT /v1/projects/{ref}/jit-access
# Discriminator (response): state
# operationId: v1-update-jit-access-config
export def "projects-jit-access v1-update-jit-access-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  state: string@state-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/jit-access")
  let body = {state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Gets project's network bans
#
# POST /v1/projects/{ref}/network-bans/retrieve
# operationId: v1-list-all-network-bans
export def "projects-network-bans-retrieve v1-list-all-network-bans" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<banned_ipv4_addresses: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/network-bans/retrieve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Gets project's network bans with additional information about which databases they affect
#
# POST /v1/projects/{ref}/network-bans/retrieve/enriched
# operationId: v1-list-all-network-bans-enriched
export def "projects-network-bans-retrieve-enriched v1-list-all-network-bans-enriched" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<banned_ipv4_addresses: table<banned_address: string, identifier: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/network-bans/retrieve/enriched")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Remove network bans.
#
# DELETE /v1/projects/{ref}/network-bans
# operationId: v1-delete-network-bans
export def "projects-network-bans v1-delete-network-bans" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ipv4_addresses: list # List of IP addresses to unban.
  --requester-ip: oneof<nothing, bool> # Include requester's public IP in the list of addresses to unban. (default: false)
  --identifier: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/network-bans")
  let body = {ipv4_addresses: $ipv4_addresses, requester_ip: $requester_ip, identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Gets project's network restrictions
#
# GET /v1/projects/{ref}/network-restrictions
# operationId: v1-get-network-restrictions
export def "projects-network-restrictions v1-get-network-restrictions" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entitlement: string, config: record<dbAllowedCidrs: list<string>, dbAllowedCidrsV6: list<string>>, old_config: record<dbAllowedCidrs: list<string>, dbAllowedCidrsV6: list<string>>, status: string, updated_at: string, applied_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/network-restrictions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Alpha] Updates project's network restrictions by adding or removing CIDRs
#
# PATCH /v1/projects/{ref}/network-restrictions
# operationId: v1-patch-network-restrictions
# --add shape: {dbAllowedCidrs?: list, dbAllowedCidrsV6?: list}
# --remove shape: {dbAllowedCidrs?: list, dbAllowedCidrsV6?: list}
export def "projects-network-restrictions v1-patch-network-restrictions" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --add: record # shape: {dbAllowedCidrs?: list, dbAllowedCidrsV6?: list}
  --remove: record # shape: {dbAllowedCidrs?: list, dbAllowedCidrsV6?: list}
]: any -> record<entitlement: string, config: record<dbAllowedCidrs: list<record>>, old_config: record<dbAllowedCidrs: list<record>>, updated_at: string, applied_at: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/network-restrictions")
  let body = {add: $add, remove: $remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Updates project's network restrictions
#
# POST /v1/projects/{ref}/network-restrictions/apply
# operationId: v1-update-network-restrictions
export def "projects-network-restrictions-apply v1-update-network-restrictions" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dbAllowedCidrs: list
  --dbAllowedCidrsV6: list
]: any -> record<entitlement: string, config: record<dbAllowedCidrs: list<string>, dbAllowedCidrsV6: list<string>>, old_config: record<dbAllowedCidrs: list<string>, dbAllowedCidrsV6: list<string>>, status: string, updated_at: string, applied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/network-restrictions/apply")
  let body = {dbAllowedCidrs: $dbAllowedCidrs, dbAllowedCidrsV6: $dbAllowedCidrsV6} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Gets project's pgsodium config
#
# GET /v1/projects/{ref}/pgsodium
# operationId: v1-get-pgsodium-config
export def "projects-pgsodium v1-get-pgsodium-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<root_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/pgsodium")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Updates project's pgsodium config. Updating the root_key can cause all data encrypted with the older key to become inaccessible.
#
# PUT /v1/projects/{ref}/pgsodium
# operationId: v1-update-pgsodium-config
export def "projects-pgsodium v1-update-pgsodium-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  root_key: string
]: any -> record<root_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/pgsodium")
  let body = {root_key: $root_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets project's postgrest config
#
# GET /v1/projects/{ref}/postgrest
# operationId: v1-get-postgrest-service-config
export def "projects-postgrest v1-get-postgrest-service-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<db_schema: string, max_rows: int, db_extra_search_path: string, db_pool: int, jwt_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/postgrest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates project's postgrest config
#
# PATCH /v1/projects/{ref}/postgrest
# operationId: v1-update-postgrest-service-config
export def "projects-postgrest v1-update-postgrest-service-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-extra-search-path: string
  --db-schema: string
  --max-rows: int
  --db-pool: int
]: any -> record<db_schema: string, max_rows: int, db_extra_search_path: string, db_pool: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/postgrest")
  let body = {db_extra_search_path: $db_extra_search_path, db_schema: $db_schema, max_rows: $max_rows, db_pool: $db_pool} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a specific project that belongs to the authenticated user
#
# GET /v1/projects/{ref}
# operationId: v1-get-project
export def "projects v1-get-project" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, ref: string, organization_id: string, organization_slug: string, name: string, region: string, created_at: string, status: string, database: record<host: string, version: string, postgres_engine: string, release_channel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the given project
#
# DELETE /v1/projects/{ref}
# operationId: v1-delete-a-project
export def "projects v1-delete-a-project" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, ref: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the given project
#
# PATCH /v1/projects/{ref}
# operationId: v1-update-a-project
export def "projects v1-update-a-project" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<id: int, ref: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all secrets
#
# GET /v1/projects/{ref}/secrets
# operationId: v1-list-all-secrets
export def "projects-secrets v1-list-all-secrets" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/secrets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk create secrets
#
# POST /v1/projects/{ref}/secrets
# operationId: v1-bulk-create-secrets
export def "projects-secrets v1-bulk-create-secrets" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bulk delete secrets
#
# DELETE /v1/projects/{ref}/secrets
# operationId: v1-bulk-delete-secrets
export def "projects-secrets v1-bulk-delete-secrets" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Get project's SSL enforcement configuration.
#
# GET /v1/projects/{ref}/ssl-enforcement
# operationId: v1-get-ssl-enforcement-config
export def "projects-ssl-enforcement v1-get-ssl-enforcement-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currentConfig: record<database: bool>, appliedSuccessfully: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/ssl-enforcement")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Update project's SSL enforcement configuration.
#
# PUT /v1/projects/{ref}/ssl-enforcement
# operationId: v1-update-ssl-enforcement-config
# --requestedConfig shape: {database: bool}
export def "projects-ssl-enforcement v1-update-ssl-enforcement-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  requestedConfig: record # shape: {database: bool}
]: any -> record<currentConfig: record<database: bool>, appliedSuccessfully: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/ssl-enforcement")
  let body = {requestedConfig: $requestedConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate TypeScript types
#
# GET /v1/projects/{ref}/types/typescript
# operationId: v1-generate-typescript-types
export def "projects-types-typescript v1-generate-typescript-types" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --included-schemas: string # default: public, e.g. public,auth
]: nothing -> record<types: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "included_schemas" $included_schemas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/types/typescript" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Gets current vanity subdomain config
#
# GET /v1/projects/{ref}/vanity-subdomain
# operationId: v1-get-vanity-subdomain-config
export def "projects-vanity-subdomain v1-get-vanity-subdomain-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, custom_domain: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/vanity-subdomain")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Deletes a project's vanity subdomain configuration
#
# DELETE /v1/projects/{ref}/vanity-subdomain
# operationId: v1-deactivate-vanity-subdomain-config
export def "projects-vanity-subdomain v1-deactivate-vanity-subdomain-config" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/vanity-subdomain")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Checks vanity subdomain availability
#
# POST /v1/projects/{ref}/vanity-subdomain/check-availability
# operationId: v1-check-vanity-subdomain-availability
export def "projects-vanity-subdomain-check-availability v1-check-vanity-subdomain-availability" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vanity_subdomain: string
]: any -> record<available: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/vanity-subdomain/check-availability")
  let body = {vanity_subdomain: $vanity_subdomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Activates a vanity subdomain for a project.
#
# POST /v1/projects/{ref}/vanity-subdomain/activate
# operationId: v1-activate-vanity-subdomain-config
export def "projects-vanity-subdomain-activate v1-activate-vanity-subdomain-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vanity_subdomain: string
]: any -> record<custom_domain: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/vanity-subdomain/activate")
  let body = {vanity_subdomain: $vanity_subdomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Upgrades the project's Postgres version
#
# POST /v1/projects/{ref}/upgrade
# operationId: v1-upgrade-postgres-version
export def "projects-upgrade v1-upgrade-postgres-version" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  target_version: string
  --release-channel: string@release-channel-completer
]: any -> record<tracking_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/upgrade")
  let body = {target_version: $target_version, release_channel: $release_channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Returns the project's eligibility for upgrades
#
# GET /v1/projects/{ref}/upgrade/eligibility
# operationId: v1-get-postgres-upgrade-eligibility
export def "projects-upgrade-eligibility v1-get-postgres-upgrade-eligibility" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<eligible: bool, current_app_version: string, current_app_version_release_channel: string, latest_app_version: string, target_upgrade_versions: table<postgres_version: string, release_channel: string, app_version: string>, duration_estimate_hours: float, legacy_auth_custom_roles: list<string>, objects_to_be_dropped: list<string>, unsupported_extensions: list<string>, user_defined_objects_in_internal_schemas: list<string>, validation_errors: list<any>, warnings: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/upgrade/eligibility")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Gets the latest status of the project's upgrade
#
# GET /v1/projects/{ref}/upgrade/status
# operationId: v1-get-postgres-upgrade-status
export def "projects-upgrade-status v1-get-postgres-upgrade-status" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tracking-id: string # e.g. 9f4d3a20-6b2e-4a7e-8c91-1d5f3e7a2b4c
]: nothing -> record<databaseUpgradeStatus: record<initiated_at: string, latest_status_at: string, target_version: float, error: string, progress: string, status: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tracking_id" $tracking_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/upgrade/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns project's readonly mode status
#
# GET /v1/projects/{ref}/readonly
# operationId: v1-get-readonly-mode-status
export def "projects-readonly v1-get-readonly-mode-status" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, override_enabled: bool, override_active_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/readonly")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disables project's readonly mode for the next 15 minutes
#
# POST /v1/projects/{ref}/readonly/temporary-disable
# operationId: v1-disable-readonly-mode-temporarily
export def "projects-readonly-temporary-disable v1-disable-readonly-mode-temporarily" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/readonly/temporary-disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Set up a read replica
#
# POST /v1/projects/{ref}/read-replicas/setup
# operationId: v1-setup-a-read-replica
export def "projects-read-replicas-setup v1-setup-a-read-replica" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  read_replica_region: string@read-replica-region-completer # Region you want your read replica to reside in
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/read-replicas/setup")
  let body = {read_replica_region: $read_replica_region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Remove a read replica
#
# POST /v1/projects/{ref}/read-replicas/remove
# operationId: v1-remove-a-read-replica
export def "projects-read-replicas-remove v1-remove-a-read-replica" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  database_identifier: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/read-replicas/remove")
  let body = {database_identifier: $database_identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets project's service health status
#
# GET /v1/projects/{ref}/health
# operationId: v1-get-services-health
export def "projects-health v1-get-services-health" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --services: list # e.g. [auth, rest]
  --timeout-ms: int # e.g. 2000
]: nothing -> table<name: string, healthy: bool, status: string, info: any, error: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "services" $services "multi") (serialize-qp "timeout_ms" $timeout_ms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/health" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set up the project's existing JWT secret as an in_use JWT signing key. This endpoint will be removed in the future always check for HTTP 404 Not Found.
#
# POST /v1/projects/{ref}/config/auth/signing-keys/legacy
# operationId: v1-create-legacy-signing-key
export def "projects-config-auth-signing-keys-legacy v1-create-legacy-signing-key" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, algorithm: string, status: string, public_jwk: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/signing-keys/legacy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the signing key information for the JWT secret imported as signing key for this project. This endpoint will be removed in the future, check for HTTP 404 Not Found.
#
# GET /v1/projects/{ref}/config/auth/signing-keys/legacy
# operationId: v1-get-legacy-signing-key
export def "projects-config-auth-signing-keys-legacy v1-get-legacy-signing-key" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, algorithm: string, status: string, public_jwk: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/signing-keys/legacy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new signing key for the project in standby status
#
# POST /v1/projects/{ref}/config/auth/signing-keys
# operationId: v1-create-project-signing-key
export def "projects-config-auth-signing-keys v1-create-project-signing-key" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  algorithm: string@algorithm-completer
  --status: string@status-completer-1
  --private-jwk: any
]: any -> record<id: string, algorithm: string, status: string, public_jwk: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/signing-keys")
  let body = {algorithm: $algorithm, status: $status, private_jwk: $private_jwk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all signing keys for the project
#
# GET /v1/projects/{ref}/config/auth/signing-keys
# operationId: v1-get-project-signing-keys
export def "projects-config-auth-signing-keys v1-get-project-signing-keys" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<id: string, algorithm: string, status: string, public_jwk: any, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/signing-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a signing key
#
# GET /v1/projects/{ref}/config/auth/signing-keys/{id}
# operationId: v1-get-project-signing-key
export def "projects-config-auth-signing-keys v1-get-project-signing-key" [
  id: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, algorithm: string, status: string, public_jwk: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/signing-keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a signing key from a project. Only possible if the key has been in revoked status for a while.
#
# DELETE /v1/projects/{ref}/config/auth/signing-keys/{id}
# operationId: v1-remove-project-signing-key
export def "projects-config-auth-signing-keys v1-remove-project-signing-key" [
  id: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, algorithm: string, status: string, public_jwk: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/signing-keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a signing key, mainly its status
#
# PATCH /v1/projects/{ref}/config/auth/signing-keys/{id}
# operationId: v1-update-project-signing-key
export def "projects-config-auth-signing-keys v1-update-project-signing-key" [
  id: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-2
]: any -> record<id: string, algorithm: string, status: string, public_jwk: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/signing-keys/($id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets project's auth config
#
# GET /v1/projects/{ref}/config/auth
# operationId: v1-get-auth-service-config
export def "projects-config-auth v1-get-auth-service-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api_max_request_duration: int, db_max_pool_size: int, db_max_pool_size_unit: string, disable_signup: bool, external_anonymous_users_enabled: bool, external_apple_additional_client_ids: string, external_apple_client_id: string, external_apple_email_optional: bool, external_apple_enabled: bool, external_apple_secret: string, external_azure_client_id: string, external_azure_email_optional: bool, external_azure_enabled: bool, external_azure_secret: string, external_azure_url: string, external_bitbucket_client_id: string, external_bitbucket_email_optional: bool, external_bitbucket_enabled: bool, external_bitbucket_secret: string, external_discord_client_id: string, external_discord_email_optional: bool, external_discord_enabled: bool, external_discord_secret: string, external_email_enabled: bool, external_facebook_client_id: string, external_facebook_email_optional: bool, external_facebook_enabled: bool, external_facebook_secret: string, external_figma_client_id: string, external_figma_email_optional: bool, external_figma_enabled: bool, external_figma_secret: string, external_github_client_id: string, external_github_email_optional: bool, external_github_enabled: bool, external_github_secret: string, external_gitlab_client_id: string, external_gitlab_email_optional: bool, external_gitlab_enabled: bool, external_gitlab_secret: string, external_gitlab_url: string, external_google_additional_client_ids: string, external_google_client_id: string, external_google_email_optional: bool, external_google_enabled: bool, external_google_secret: string, external_google_skip_nonce_check: bool, external_kakao_client_id: string, external_kakao_email_optional: bool, external_kakao_enabled: bool, external_kakao_secret: string, external_keycloak_client_id: string, external_keycloak_email_optional: bool, external_keycloak_enabled: bool, external_keycloak_secret: string, external_keycloak_url: string, external_linkedin_oidc_client_id: string, external_linkedin_oidc_email_optional: bool, external_linkedin_oidc_enabled: bool, external_linkedin_oidc_secret: string, external_slack_oidc_client_id: string, external_slack_oidc_email_optional: bool, external_slack_oidc_enabled: bool, external_slack_oidc_secret: string, external_notion_client_id: string, external_notion_email_optional: bool, external_notion_enabled: bool, external_notion_secret: string, external_phone_enabled: bool, external_slack_client_id: string, external_slack_email_optional: bool, external_slack_enabled: bool, external_slack_secret: string, external_spotify_client_id: string, external_spotify_email_optional: bool, external_spotify_enabled: bool, external_spotify_secret: string, external_twitch_client_id: string, external_twitch_email_optional: bool, external_twitch_enabled: bool, external_twitch_secret: string, external_twitter_client_id: string, external_twitter_email_optional: bool, external_twitter_enabled: bool, external_twitter_secret: string, external_x_client_id: string, external_x_email_optional: bool, external_x_enabled: bool, external_x_secret: string, external_workos_client_id: string, external_workos_enabled: bool, external_workos_secret: string, external_workos_url: string, external_web3_solana_enabled: bool, external_web3_ethereum_enabled: bool, external_zoom_client_id: string, external_zoom_email_optional: bool, external_zoom_enabled: bool, external_zoom_secret: string, hook_custom_access_token_enabled: bool, hook_custom_access_token_uri: string, hook_custom_access_token_secrets: string, hook_mfa_verification_attempt_enabled: bool, hook_mfa_verification_attempt_uri: string, hook_mfa_verification_attempt_secrets: string, hook_password_verification_attempt_enabled: bool, hook_password_verification_attempt_uri: string, hook_password_verification_attempt_secrets: string, hook_send_sms_enabled: bool, hook_send_sms_uri: string, hook_send_sms_secrets: string, hook_send_email_enabled: bool, hook_send_email_uri: string, hook_send_email_secrets: string, hook_before_user_created_enabled: bool, hook_before_user_created_uri: string, hook_before_user_created_secrets: string, hook_after_user_created_enabled: bool, hook_after_user_created_uri: string, hook_after_user_created_secrets: string, jwt_exp: int, mailer_allow_unverified_email_sign_ins: bool, mailer_autoconfirm: bool, mailer_otp_exp: int, mailer_otp_length: int, mailer_secure_email_change_enabled: bool, mailer_subjects_confirmation: string, mailer_subjects_email_change: string, mailer_subjects_invite: string, mailer_subjects_magic_link: string, mailer_subjects_reauthentication: string, mailer_subjects_recovery: string, mailer_subjects_password_changed_notification: string, mailer_subjects_email_changed_notification: string, mailer_subjects_phone_changed_notification: string, mailer_subjects_mfa_factor_enrolled_notification: string, mailer_subjects_mfa_factor_unenrolled_notification: string, mailer_subjects_identity_linked_notification: string, mailer_subjects_identity_unlinked_notification: string, mailer_templates_confirmation_content: string, mailer_templates_email_change_content: string, mailer_templates_invite_content: string, mailer_templates_magic_link_content: string, mailer_templates_reauthentication_content: string, mailer_templates_recovery_content: string, mailer_templates_password_changed_notification_content: string, mailer_templates_email_changed_notification_content: string, mailer_templates_phone_changed_notification_content: string, mailer_templates_mfa_factor_enrolled_notification_content: string, mailer_templates_mfa_factor_unenrolled_notification_content: string, mailer_templates_identity_linked_notification_content: string, mailer_templates_identity_unlinked_notification_content: string, mailer_notifications_password_changed_enabled: bool, mailer_notifications_email_changed_enabled: bool, mailer_notifications_phone_changed_enabled: bool, mailer_notifications_mfa_factor_enrolled_enabled: bool, mailer_notifications_mfa_factor_unenrolled_enabled: bool, mailer_notifications_identity_linked_enabled: bool, mailer_notifications_identity_unlinked_enabled: bool, mfa_max_enrolled_factors: int, mfa_totp_enroll_enabled: bool, mfa_totp_verify_enabled: bool, mfa_phone_enroll_enabled: bool, mfa_phone_verify_enabled: bool, mfa_web_authn_enroll_enabled: bool, mfa_web_authn_verify_enabled: bool, passkey_enabled: bool, webauthn_rp_display_name: string, webauthn_rp_id: string, webauthn_rp_origins: string, mfa_phone_otp_length: int, mfa_phone_template: string, mfa_phone_max_frequency: int, nimbus_oauth_client_id: string, nimbus_oauth_email_optional: bool, nimbus_oauth_client_secret: string, password_hibp_enabled: bool, password_min_length: int, password_required_characters: string, rate_limit_anonymous_users: int, rate_limit_email_sent: int, rate_limit_sms_sent: int, rate_limit_token_refresh: int, rate_limit_verify: int, rate_limit_otp: int, rate_limit_web3: int, refresh_token_rotation_enabled: bool, saml_enabled: bool, saml_external_url: string, saml_allow_encrypted_assertions: bool, security_sb_forwarded_for_enabled: bool, security_captcha_enabled: bool, security_captcha_provider: string, security_captcha_secret: string, security_manual_linking_enabled: bool, security_refresh_token_reuse_interval: int, security_update_password_require_reauthentication: bool, sessions_inactivity_timeout: float, sessions_single_per_user: bool, sessions_tags: string, sessions_timebox: float, site_url: string, sms_autoconfirm: bool, sms_max_frequency: int, sms_messagebird_access_key: string, sms_messagebird_originator: string, sms_otp_exp: int, sms_otp_length: int, sms_provider: string, sms_template: string, sms_test_otp: string, sms_test_otp_valid_until: string, sms_textlocal_api_key: string, sms_textlocal_sender: string, sms_twilio_account_sid: string, sms_twilio_auth_token: string, sms_twilio_content_sid: string, sms_twilio_message_service_sid: string, sms_twilio_verify_account_sid: string, sms_twilio_verify_auth_token: string, sms_twilio_verify_message_service_sid: string, sms_vonage_api_key: string, sms_vonage_api_secret: string, sms_vonage_from: string, smtp_admin_email: string, smtp_host: string, smtp_max_frequency: int, smtp_pass: string, smtp_port: string, smtp_sender_name: string, smtp_user: string, uri_allow_list: string, oauth_server_enabled: bool, oauth_server_allow_dynamic_registration: bool, oauth_server_authorization_path: string, custom_oauth_enabled: bool, custom_oauth_max_providers: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a project's auth config
#
# PATCH /v1/projects/{ref}/config/auth
# operationId: v1-update-auth-service-config
export def "projects-config-auth v1-update-auth-service-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-url: string # nullable
  --disable-signup: oneof<nothing, bool> # nullable
  --jwt-exp: int # nullable
  --smtp-admin-email: string # nullable, format: email
  --smtp-host: string # nullable
  --smtp-port: string # nullable
  --smtp-user: string # nullable
  --smtp-pass: string # nullable
  --smtp-max-frequency: int # nullable
  --smtp-sender-name: string # nullable
  --mailer-allow-unverified-email-sign-ins: oneof<nothing, bool> # nullable
  --mailer-autoconfirm: oneof<nothing, bool> # nullable
  --mailer-subjects-invite: string # nullable
  --mailer-subjects-confirmation: string # nullable
  --mailer-subjects-recovery: string # nullable
  --mailer-subjects-email-change: string # nullable
  --mailer-subjects-magic-link: string # nullable
  --mailer-subjects-reauthentication: string # nullable
  --mailer-subjects-password-changed-notification: string # nullable
  --mailer-subjects-email-changed-notification: string # nullable
  --mailer-subjects-phone-changed-notification: string # nullable
  --mailer-subjects-mfa-factor-enrolled-notification: string # nullable
  --mailer-subjects-mfa-factor-unenrolled-notification: string # nullable
  --mailer-subjects-identity-linked-notification: string # nullable
  --mailer-subjects-identity-unlinked-notification: string # nullable
  --mailer-templates-invite-content: string # nullable
  --mailer-templates-confirmation-content: string # nullable
  --mailer-templates-recovery-content: string # nullable
  --mailer-templates-email-change-content: string # nullable
  --mailer-templates-magic-link-content: string # nullable
  --mailer-templates-reauthentication-content: string # nullable
  --mailer-templates-password-changed-notification-content: string # nullable
  --mailer-templates-email-changed-notification-content: string # nullable
  --mailer-templates-phone-changed-notification-content: string # nullable
  --mailer-templates-mfa-factor-enrolled-notification-content: string # nullable
  --mailer-templates-mfa-factor-unenrolled-notification-content: string # nullable
  --mailer-templates-identity-linked-notification-content: string # nullable
  --mailer-templates-identity-unlinked-notification-content: string # nullable
  --mailer-notifications-password-changed-enabled: oneof<nothing, bool> # nullable
  --mailer-notifications-email-changed-enabled: oneof<nothing, bool> # nullable
  --mailer-notifications-phone-changed-enabled: oneof<nothing, bool> # nullable
  --mailer-notifications-mfa-factor-enrolled-enabled: oneof<nothing, bool> # nullable
  --mailer-notifications-mfa-factor-unenrolled-enabled: oneof<nothing, bool> # nullable
  --mailer-notifications-identity-linked-enabled: oneof<nothing, bool> # nullable
  --mailer-notifications-identity-unlinked-enabled: oneof<nothing, bool> # nullable
  --mfa-max-enrolled-factors: int # nullable
  --uri-allow-list: string # nullable
  --external-anonymous-users-enabled: oneof<nothing, bool> # nullable
  --external-email-enabled: oneof<nothing, bool> # nullable
  --external-phone-enabled: oneof<nothing, bool> # nullable
  --saml-enabled: oneof<nothing, bool> # nullable
  --saml-external-url: string # nullable
  --security-sb-forwarded-for-enabled: oneof<nothing, bool> # nullable
  --security-captcha-enabled: oneof<nothing, bool> # nullable
  --security-captcha-provider: string@security-captcha-provider-completer # nullable
  --security-captcha-secret: string # nullable
  --sessions-timebox: float # nullable
  --sessions-inactivity-timeout: float # nullable
  --sessions-single-per-user: oneof<nothing, bool> # nullable
  --sessions-tags: string # nullable
  --rate-limit-anonymous-users: int # nullable
  --rate-limit-email-sent: int # nullable
  --rate-limit-sms-sent: int # nullable
  --rate-limit-verify: int # nullable
  --rate-limit-token-refresh: int # nullable
  --rate-limit-otp: int # nullable
  --rate-limit-web3: int # nullable
  --mailer-secure-email-change-enabled: oneof<nothing, bool> # nullable
  --refresh-token-rotation-enabled: oneof<nothing, bool> # nullable
  --password-hibp-enabled: oneof<nothing, bool> # nullable
  --password-min-length: int # nullable
  --password-required-characters: string@password-required-characters-completer # nullable
  --security-manual-linking-enabled: oneof<nothing, bool> # nullable
  --security-update-password-require-reauthentication: oneof<nothing, bool> # nullable
  --security-refresh-token-reuse-interval: int # nullable
  --mailer-otp-exp: int
  --mailer-otp-length: int # nullable
  --sms-autoconfirm: oneof<nothing, bool> # nullable
  --sms-max-frequency: int # nullable
  --sms-otp-exp: int # nullable
  --sms-otp-length: int
  --sms-provider: string@sms-provider-completer # nullable
  --sms-messagebird-access-key: string # nullable
  --sms-messagebird-originator: string # nullable
  --sms-test-otp: string # nullable
  --sms-test-otp-valid-until: string # nullable, format: date-time
  --sms-textlocal-api-key: string # nullable
  --sms-textlocal-sender: string # nullable
  --sms-twilio-account-sid: string # nullable
  --sms-twilio-auth-token: string # nullable
  --sms-twilio-content-sid: string # nullable
  --sms-twilio-message-service-sid: string # nullable
  --sms-twilio-verify-account-sid: string # nullable
  --sms-twilio-verify-auth-token: string # nullable
  --sms-twilio-verify-message-service-sid: string # nullable
  --sms-vonage-api-key: string # nullable
  --sms-vonage-api-secret: string # nullable
  --sms-vonage-from: string # nullable
  --sms-template: string # nullable
  --hook-mfa-verification-attempt-enabled: oneof<nothing, bool> # nullable
  --hook-mfa-verification-attempt-uri: string # nullable
  --hook-mfa-verification-attempt-secrets: string # nullable
  --hook-password-verification-attempt-enabled: oneof<nothing, bool> # nullable
  --hook-password-verification-attempt-uri: string # nullable
  --hook-password-verification-attempt-secrets: string # nullable
  --hook-custom-access-token-enabled: oneof<nothing, bool> # nullable
  --hook-custom-access-token-uri: string # nullable
  --hook-custom-access-token-secrets: string # nullable
  --hook-send-sms-enabled: oneof<nothing, bool> # nullable
  --hook-send-sms-uri: string # nullable
  --hook-send-sms-secrets: string # nullable
  --hook-send-email-enabled: oneof<nothing, bool> # nullable
  --hook-send-email-uri: string # nullable
  --hook-send-email-secrets: string # nullable
  --hook-before-user-created-enabled: oneof<nothing, bool> # nullable
  --hook-before-user-created-uri: string # nullable
  --hook-before-user-created-secrets: string # nullable
  --hook-after-user-created-enabled: oneof<nothing, bool> # nullable
  --hook-after-user-created-uri: string # nullable
  --hook-after-user-created-secrets: string # nullable
  --external-apple-enabled: oneof<nothing, bool> # nullable
  --external-apple-client-id: string # nullable
  --external-apple-email-optional: oneof<nothing, bool> # nullable
  --external-apple-secret: string # nullable
  --external-apple-additional-client-ids: string # nullable
  --external-azure-enabled: oneof<nothing, bool> # nullable
  --external-azure-client-id: string # nullable
  --external-azure-email-optional: oneof<nothing, bool> # nullable
  --external-azure-secret: string # nullable
  --external-azure-url: string # nullable
  --external-bitbucket-enabled: oneof<nothing, bool> # nullable
  --external-bitbucket-client-id: string # nullable
  --external-bitbucket-email-optional: oneof<nothing, bool> # nullable
  --external-bitbucket-secret: string # nullable
  --external-discord-enabled: oneof<nothing, bool> # nullable
  --external-discord-client-id: string # nullable
  --external-discord-email-optional: oneof<nothing, bool> # nullable
  --external-discord-secret: string # nullable
  --external-facebook-enabled: oneof<nothing, bool> # nullable
  --external-facebook-client-id: string # nullable
  --external-facebook-email-optional: oneof<nothing, bool> # nullable
  --external-facebook-secret: string # nullable
  --external-figma-enabled: oneof<nothing, bool> # nullable
  --external-figma-client-id: string # nullable
  --external-figma-email-optional: oneof<nothing, bool> # nullable
  --external-figma-secret: string # nullable
  --external-github-enabled: oneof<nothing, bool> # nullable
  --external-github-client-id: string # nullable
  --external-github-email-optional: oneof<nothing, bool> # nullable
  --external-github-secret: string # nullable
  --external-gitlab-enabled: oneof<nothing, bool> # nullable
  --external-gitlab-client-id: string # nullable
  --external-gitlab-email-optional: oneof<nothing, bool> # nullable
  --external-gitlab-secret: string # nullable
  --external-gitlab-url: string # nullable
  --external-google-enabled: oneof<nothing, bool> # nullable
  --external-google-client-id: string # nullable
  --external-google-email-optional: oneof<nothing, bool> # nullable
  --external-google-secret: string # nullable
  --external-google-additional-client-ids: string # nullable
  --external-google-skip-nonce-check: oneof<nothing, bool> # nullable
  --external-kakao-enabled: oneof<nothing, bool> # nullable
  --external-kakao-client-id: string # nullable
  --external-kakao-email-optional: oneof<nothing, bool> # nullable
  --external-kakao-secret: string # nullable
  --external-keycloak-enabled: oneof<nothing, bool> # nullable
  --external-keycloak-client-id: string # nullable
  --external-keycloak-email-optional: oneof<nothing, bool> # nullable
  --external-keycloak-secret: string # nullable
  --external-keycloak-url: string # nullable
  --external-linkedin-oidc-enabled: oneof<nothing, bool> # nullable
  --external-linkedin-oidc-client-id: string # nullable
  --external-linkedin-oidc-email-optional: oneof<nothing, bool> # nullable
  --external-linkedin-oidc-secret: string # nullable
  --external-slack-oidc-enabled: oneof<nothing, bool> # nullable
  --external-slack-oidc-client-id: string # nullable
  --external-slack-oidc-email-optional: oneof<nothing, bool> # nullable
  --external-slack-oidc-secret: string # nullable
  --external-notion-enabled: oneof<nothing, bool> # nullable
  --external-notion-client-id: string # nullable
  --external-notion-email-optional: oneof<nothing, bool> # nullable
  --external-notion-secret: string # nullable
  --external-slack-enabled: oneof<nothing, bool> # nullable
  --external-slack-client-id: string # nullable
  --external-slack-email-optional: oneof<nothing, bool> # nullable
  --external-slack-secret: string # nullable
  --external-spotify-enabled: oneof<nothing, bool> # nullable
  --external-spotify-client-id: string # nullable
  --external-spotify-email-optional: oneof<nothing, bool> # nullable
  --external-spotify-secret: string # nullable
  --external-twitch-enabled: oneof<nothing, bool> # nullable
  --external-twitch-client-id: string # nullable
  --external-twitch-email-optional: oneof<nothing, bool> # nullable
  --external-twitch-secret: string # nullable
  --external-twitter-enabled: oneof<nothing, bool> # nullable
  --external-twitter-client-id: string # nullable
  --external-twitter-email-optional: oneof<nothing, bool> # nullable
  --external-twitter-secret: string # nullable
  --external-x-enabled: oneof<nothing, bool> # nullable
  --external-x-client-id: string # nullable
  --external-x-email-optional: oneof<nothing, bool> # nullable
  --external-x-secret: string # nullable
  --external-workos-enabled: oneof<nothing, bool> # nullable
  --external-workos-client-id: string # nullable
  --external-workos-secret: string # nullable
  --external-workos-url: string # nullable
  --external-web3-solana-enabled: oneof<nothing, bool> # nullable
  --external-web3-ethereum-enabled: oneof<nothing, bool> # nullable
  --external-zoom-enabled: oneof<nothing, bool> # nullable
  --external-zoom-client-id: string # nullable
  --external-zoom-email-optional: oneof<nothing, bool> # nullable
  --external-zoom-secret: string # nullable
  --db-max-pool-size: int # nullable
  --db-max-pool-size-unit: string@db-max-pool-size-unit-completer # nullable
  --api-max-request-duration: int # nullable
  --mfa-totp-enroll-enabled: oneof<nothing, bool> # nullable
  --mfa-totp-verify-enabled: oneof<nothing, bool> # nullable
  --mfa-web-authn-enroll-enabled: oneof<nothing, bool> # nullable
  --mfa-web-authn-verify-enabled: oneof<nothing, bool> # nullable
  --passkey-enabled: oneof<nothing, bool>
  --webauthn-rp-display-name: string # nullable
  --webauthn-rp-id: string # nullable
  --webauthn-rp-origins: string # nullable
  --mfa-phone-enroll-enabled: oneof<nothing, bool> # nullable
  --mfa-phone-verify-enabled: oneof<nothing, bool> # nullable
  --mfa-phone-max-frequency: int # nullable
  --mfa-phone-otp-length: int # nullable
  --mfa-phone-template: string # nullable
  --nimbus-oauth-client-id: string # nullable
  --nimbus-oauth-client-secret: string # nullable
  --oauth-server-enabled: oneof<nothing, bool> # nullable
  --oauth-server-allow-dynamic-registration: oneof<nothing, bool> # nullable
  --oauth-server-authorization-path: string # nullable
  --custom-oauth-enabled: oneof<nothing, bool>
]: any -> record<api_max_request_duration: int, db_max_pool_size: int, db_max_pool_size_unit: string, disable_signup: bool, external_anonymous_users_enabled: bool, external_apple_additional_client_ids: string, external_apple_client_id: string, external_apple_email_optional: bool, external_apple_enabled: bool, external_apple_secret: string, external_azure_client_id: string, external_azure_email_optional: bool, external_azure_enabled: bool, external_azure_secret: string, external_azure_url: string, external_bitbucket_client_id: string, external_bitbucket_email_optional: bool, external_bitbucket_enabled: bool, external_bitbucket_secret: string, external_discord_client_id: string, external_discord_email_optional: bool, external_discord_enabled: bool, external_discord_secret: string, external_email_enabled: bool, external_facebook_client_id: string, external_facebook_email_optional: bool, external_facebook_enabled: bool, external_facebook_secret: string, external_figma_client_id: string, external_figma_email_optional: bool, external_figma_enabled: bool, external_figma_secret: string, external_github_client_id: string, external_github_email_optional: bool, external_github_enabled: bool, external_github_secret: string, external_gitlab_client_id: string, external_gitlab_email_optional: bool, external_gitlab_enabled: bool, external_gitlab_secret: string, external_gitlab_url: string, external_google_additional_client_ids: string, external_google_client_id: string, external_google_email_optional: bool, external_google_enabled: bool, external_google_secret: string, external_google_skip_nonce_check: bool, external_kakao_client_id: string, external_kakao_email_optional: bool, external_kakao_enabled: bool, external_kakao_secret: string, external_keycloak_client_id: string, external_keycloak_email_optional: bool, external_keycloak_enabled: bool, external_keycloak_secret: string, external_keycloak_url: string, external_linkedin_oidc_client_id: string, external_linkedin_oidc_email_optional: bool, external_linkedin_oidc_enabled: bool, external_linkedin_oidc_secret: string, external_slack_oidc_client_id: string, external_slack_oidc_email_optional: bool, external_slack_oidc_enabled: bool, external_slack_oidc_secret: string, external_notion_client_id: string, external_notion_email_optional: bool, external_notion_enabled: bool, external_notion_secret: string, external_phone_enabled: bool, external_slack_client_id: string, external_slack_email_optional: bool, external_slack_enabled: bool, external_slack_secret: string, external_spotify_client_id: string, external_spotify_email_optional: bool, external_spotify_enabled: bool, external_spotify_secret: string, external_twitch_client_id: string, external_twitch_email_optional: bool, external_twitch_enabled: bool, external_twitch_secret: string, external_twitter_client_id: string, external_twitter_email_optional: bool, external_twitter_enabled: bool, external_twitter_secret: string, external_x_client_id: string, external_x_email_optional: bool, external_x_enabled: bool, external_x_secret: string, external_workos_client_id: string, external_workos_enabled: bool, external_workos_secret: string, external_workos_url: string, external_web3_solana_enabled: bool, external_web3_ethereum_enabled: bool, external_zoom_client_id: string, external_zoom_email_optional: bool, external_zoom_enabled: bool, external_zoom_secret: string, hook_custom_access_token_enabled: bool, hook_custom_access_token_uri: string, hook_custom_access_token_secrets: string, hook_mfa_verification_attempt_enabled: bool, hook_mfa_verification_attempt_uri: string, hook_mfa_verification_attempt_secrets: string, hook_password_verification_attempt_enabled: bool, hook_password_verification_attempt_uri: string, hook_password_verification_attempt_secrets: string, hook_send_sms_enabled: bool, hook_send_sms_uri: string, hook_send_sms_secrets: string, hook_send_email_enabled: bool, hook_send_email_uri: string, hook_send_email_secrets: string, hook_before_user_created_enabled: bool, hook_before_user_created_uri: string, hook_before_user_created_secrets: string, hook_after_user_created_enabled: bool, hook_after_user_created_uri: string, hook_after_user_created_secrets: string, jwt_exp: int, mailer_allow_unverified_email_sign_ins: bool, mailer_autoconfirm: bool, mailer_otp_exp: int, mailer_otp_length: int, mailer_secure_email_change_enabled: bool, mailer_subjects_confirmation: string, mailer_subjects_email_change: string, mailer_subjects_invite: string, mailer_subjects_magic_link: string, mailer_subjects_reauthentication: string, mailer_subjects_recovery: string, mailer_subjects_password_changed_notification: string, mailer_subjects_email_changed_notification: string, mailer_subjects_phone_changed_notification: string, mailer_subjects_mfa_factor_enrolled_notification: string, mailer_subjects_mfa_factor_unenrolled_notification: string, mailer_subjects_identity_linked_notification: string, mailer_subjects_identity_unlinked_notification: string, mailer_templates_confirmation_content: string, mailer_templates_email_change_content: string, mailer_templates_invite_content: string, mailer_templates_magic_link_content: string, mailer_templates_reauthentication_content: string, mailer_templates_recovery_content: string, mailer_templates_password_changed_notification_content: string, mailer_templates_email_changed_notification_content: string, mailer_templates_phone_changed_notification_content: string, mailer_templates_mfa_factor_enrolled_notification_content: string, mailer_templates_mfa_factor_unenrolled_notification_content: string, mailer_templates_identity_linked_notification_content: string, mailer_templates_identity_unlinked_notification_content: string, mailer_notifications_password_changed_enabled: bool, mailer_notifications_email_changed_enabled: bool, mailer_notifications_phone_changed_enabled: bool, mailer_notifications_mfa_factor_enrolled_enabled: bool, mailer_notifications_mfa_factor_unenrolled_enabled: bool, mailer_notifications_identity_linked_enabled: bool, mailer_notifications_identity_unlinked_enabled: bool, mfa_max_enrolled_factors: int, mfa_totp_enroll_enabled: bool, mfa_totp_verify_enabled: bool, mfa_phone_enroll_enabled: bool, mfa_phone_verify_enabled: bool, mfa_web_authn_enroll_enabled: bool, mfa_web_authn_verify_enabled: bool, passkey_enabled: bool, webauthn_rp_display_name: string, webauthn_rp_id: string, webauthn_rp_origins: string, mfa_phone_otp_length: int, mfa_phone_template: string, mfa_phone_max_frequency: int, nimbus_oauth_client_id: string, nimbus_oauth_email_optional: bool, nimbus_oauth_client_secret: string, password_hibp_enabled: bool, password_min_length: int, password_required_characters: string, rate_limit_anonymous_users: int, rate_limit_email_sent: int, rate_limit_sms_sent: int, rate_limit_token_refresh: int, rate_limit_verify: int, rate_limit_otp: int, rate_limit_web3: int, refresh_token_rotation_enabled: bool, saml_enabled: bool, saml_external_url: string, saml_allow_encrypted_assertions: bool, security_sb_forwarded_for_enabled: bool, security_captcha_enabled: bool, security_captcha_provider: string, security_captcha_secret: string, security_manual_linking_enabled: bool, security_refresh_token_reuse_interval: int, security_update_password_require_reauthentication: bool, sessions_inactivity_timeout: float, sessions_single_per_user: bool, sessions_tags: string, sessions_timebox: float, site_url: string, sms_autoconfirm: bool, sms_max_frequency: int, sms_messagebird_access_key: string, sms_messagebird_originator: string, sms_otp_exp: int, sms_otp_length: int, sms_provider: string, sms_template: string, sms_test_otp: string, sms_test_otp_valid_until: string, sms_textlocal_api_key: string, sms_textlocal_sender: string, sms_twilio_account_sid: string, sms_twilio_auth_token: string, sms_twilio_content_sid: string, sms_twilio_message_service_sid: string, sms_twilio_verify_account_sid: string, sms_twilio_verify_auth_token: string, sms_twilio_verify_message_service_sid: string, sms_vonage_api_key: string, sms_vonage_api_secret: string, sms_vonage_from: string, smtp_admin_email: string, smtp_host: string, smtp_max_frequency: int, smtp_pass: string, smtp_port: string, smtp_sender_name: string, smtp_user: string, uri_allow_list: string, oauth_server_enabled: bool, oauth_server_allow_dynamic_registration: bool, oauth_server_authorization_path: string, custom_oauth_enabled: bool, custom_oauth_max_providers: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth")
  let body = {site_url: $site_url, disable_signup: $disable_signup, jwt_exp: $jwt_exp, smtp_admin_email: $smtp_admin_email, smtp_host: $smtp_host, smtp_port: $smtp_port, smtp_user: $smtp_user, smtp_pass: $smtp_pass, smtp_max_frequency: $smtp_max_frequency, smtp_sender_name: $smtp_sender_name, mailer_allow_unverified_email_sign_ins: $mailer_allow_unverified_email_sign_ins, mailer_autoconfirm: $mailer_autoconfirm, mailer_subjects_invite: $mailer_subjects_invite, mailer_subjects_confirmation: $mailer_subjects_confirmation, mailer_subjects_recovery: $mailer_subjects_recovery, mailer_subjects_email_change: $mailer_subjects_email_change, mailer_subjects_magic_link: $mailer_subjects_magic_link, mailer_subjects_reauthentication: $mailer_subjects_reauthentication, mailer_subjects_password_changed_notification: $mailer_subjects_password_changed_notification, mailer_subjects_email_changed_notification: $mailer_subjects_email_changed_notification, mailer_subjects_phone_changed_notification: $mailer_subjects_phone_changed_notification, mailer_subjects_mfa_factor_enrolled_notification: $mailer_subjects_mfa_factor_enrolled_notification, mailer_subjects_mfa_factor_unenrolled_notification: $mailer_subjects_mfa_factor_unenrolled_notification, mailer_subjects_identity_linked_notification: $mailer_subjects_identity_linked_notification, mailer_subjects_identity_unlinked_notification: $mailer_subjects_identity_unlinked_notification, mailer_templates_invite_content: $mailer_templates_invite_content, mailer_templates_confirmation_content: $mailer_templates_confirmation_content, mailer_templates_recovery_content: $mailer_templates_recovery_content, mailer_templates_email_change_content: $mailer_templates_email_change_content, mailer_templates_magic_link_content: $mailer_templates_magic_link_content, mailer_templates_reauthentication_content: $mailer_templates_reauthentication_content, mailer_templates_password_changed_notification_content: $mailer_templates_password_changed_notification_content, mailer_templates_email_changed_notification_content: $mailer_templates_email_changed_notification_content, mailer_templates_phone_changed_notification_content: $mailer_templates_phone_changed_notification_content, mailer_templates_mfa_factor_enrolled_notification_content: $mailer_templates_mfa_factor_enrolled_notification_content, mailer_templates_mfa_factor_unenrolled_notification_content: $mailer_templates_mfa_factor_unenrolled_notification_content, mailer_templates_identity_linked_notification_content: $mailer_templates_identity_linked_notification_content, mailer_templates_identity_unlinked_notification_content: $mailer_templates_identity_unlinked_notification_content, mailer_notifications_password_changed_enabled: $mailer_notifications_password_changed_enabled, mailer_notifications_email_changed_enabled: $mailer_notifications_email_changed_enabled, mailer_notifications_phone_changed_enabled: $mailer_notifications_phone_changed_enabled, mailer_notifications_mfa_factor_enrolled_enabled: $mailer_notifications_mfa_factor_enrolled_enabled, mailer_notifications_mfa_factor_unenrolled_enabled: $mailer_notifications_mfa_factor_unenrolled_enabled, mailer_notifications_identity_linked_enabled: $mailer_notifications_identity_linked_enabled, mailer_notifications_identity_unlinked_enabled: $mailer_notifications_identity_unlinked_enabled, mfa_max_enrolled_factors: $mfa_max_enrolled_factors, uri_allow_list: $uri_allow_list, external_anonymous_users_enabled: $external_anonymous_users_enabled, external_email_enabled: $external_email_enabled, external_phone_enabled: $external_phone_enabled, saml_enabled: $saml_enabled, saml_external_url: $saml_external_url, security_sb_forwarded_for_enabled: $security_sb_forwarded_for_enabled, security_captcha_enabled: $security_captcha_enabled, security_captcha_provider: $security_captcha_provider, security_captcha_secret: $security_captcha_secret, sessions_timebox: $sessions_timebox, sessions_inactivity_timeout: $sessions_inactivity_timeout, sessions_single_per_user: $sessions_single_per_user, sessions_tags: $sessions_tags, rate_limit_anonymous_users: $rate_limit_anonymous_users, rate_limit_email_sent: $rate_limit_email_sent, rate_limit_sms_sent: $rate_limit_sms_sent, rate_limit_verify: $rate_limit_verify, rate_limit_token_refresh: $rate_limit_token_refresh, rate_limit_otp: $rate_limit_otp, rate_limit_web3: $rate_limit_web3, mailer_secure_email_change_enabled: $mailer_secure_email_change_enabled, refresh_token_rotation_enabled: $refresh_token_rotation_enabled, password_hibp_enabled: $password_hibp_enabled, password_min_length: $password_min_length, password_required_characters: $password_required_characters, security_manual_linking_enabled: $security_manual_linking_enabled, security_update_password_require_reauthentication: $security_update_password_require_reauthentication, security_refresh_token_reuse_interval: $security_refresh_token_reuse_interval, mailer_otp_exp: $mailer_otp_exp, mailer_otp_length: $mailer_otp_length, sms_autoconfirm: $sms_autoconfirm, sms_max_frequency: $sms_max_frequency, sms_otp_exp: $sms_otp_exp, sms_otp_length: $sms_otp_length, sms_provider: $sms_provider, sms_messagebird_access_key: $sms_messagebird_access_key, sms_messagebird_originator: $sms_messagebird_originator, sms_test_otp: $sms_test_otp, sms_test_otp_valid_until: $sms_test_otp_valid_until, sms_textlocal_api_key: $sms_textlocal_api_key, sms_textlocal_sender: $sms_textlocal_sender, sms_twilio_account_sid: $sms_twilio_account_sid, sms_twilio_auth_token: $sms_twilio_auth_token, sms_twilio_content_sid: $sms_twilio_content_sid, sms_twilio_message_service_sid: $sms_twilio_message_service_sid, sms_twilio_verify_account_sid: $sms_twilio_verify_account_sid, sms_twilio_verify_auth_token: $sms_twilio_verify_auth_token, sms_twilio_verify_message_service_sid: $sms_twilio_verify_message_service_sid, sms_vonage_api_key: $sms_vonage_api_key, sms_vonage_api_secret: $sms_vonage_api_secret, sms_vonage_from: $sms_vonage_from, sms_template: $sms_template, hook_mfa_verification_attempt_enabled: $hook_mfa_verification_attempt_enabled, hook_mfa_verification_attempt_uri: $hook_mfa_verification_attempt_uri, hook_mfa_verification_attempt_secrets: $hook_mfa_verification_attempt_secrets, hook_password_verification_attempt_enabled: $hook_password_verification_attempt_enabled, hook_password_verification_attempt_uri: $hook_password_verification_attempt_uri, hook_password_verification_attempt_secrets: $hook_password_verification_attempt_secrets, hook_custom_access_token_enabled: $hook_custom_access_token_enabled, hook_custom_access_token_uri: $hook_custom_access_token_uri, hook_custom_access_token_secrets: $hook_custom_access_token_secrets, hook_send_sms_enabled: $hook_send_sms_enabled, hook_send_sms_uri: $hook_send_sms_uri, hook_send_sms_secrets: $hook_send_sms_secrets, hook_send_email_enabled: $hook_send_email_enabled, hook_send_email_uri: $hook_send_email_uri, hook_send_email_secrets: $hook_send_email_secrets, hook_before_user_created_enabled: $hook_before_user_created_enabled, hook_before_user_created_uri: $hook_before_user_created_uri, hook_before_user_created_secrets: $hook_before_user_created_secrets, hook_after_user_created_enabled: $hook_after_user_created_enabled, hook_after_user_created_uri: $hook_after_user_created_uri, hook_after_user_created_secrets: $hook_after_user_created_secrets, external_apple_enabled: $external_apple_enabled, external_apple_client_id: $external_apple_client_id, external_apple_email_optional: $external_apple_email_optional, external_apple_secret: $external_apple_secret, external_apple_additional_client_ids: $external_apple_additional_client_ids, external_azure_enabled: $external_azure_enabled, external_azure_client_id: $external_azure_client_id, external_azure_email_optional: $external_azure_email_optional, external_azure_secret: $external_azure_secret, external_azure_url: $external_azure_url, external_bitbucket_enabled: $external_bitbucket_enabled, external_bitbucket_client_id: $external_bitbucket_client_id, external_bitbucket_email_optional: $external_bitbucket_email_optional, external_bitbucket_secret: $external_bitbucket_secret, external_discord_enabled: $external_discord_enabled, external_discord_client_id: $external_discord_client_id, external_discord_email_optional: $external_discord_email_optional, external_discord_secret: $external_discord_secret, external_facebook_enabled: $external_facebook_enabled, external_facebook_client_id: $external_facebook_client_id, external_facebook_email_optional: $external_facebook_email_optional, external_facebook_secret: $external_facebook_secret, external_figma_enabled: $external_figma_enabled, external_figma_client_id: $external_figma_client_id, external_figma_email_optional: $external_figma_email_optional, external_figma_secret: $external_figma_secret, external_github_enabled: $external_github_enabled, external_github_client_id: $external_github_client_id, external_github_email_optional: $external_github_email_optional, external_github_secret: $external_github_secret, external_gitlab_enabled: $external_gitlab_enabled, external_gitlab_client_id: $external_gitlab_client_id, external_gitlab_email_optional: $external_gitlab_email_optional, external_gitlab_secret: $external_gitlab_secret, external_gitlab_url: $external_gitlab_url, external_google_enabled: $external_google_enabled, external_google_client_id: $external_google_client_id, external_google_email_optional: $external_google_email_optional, external_google_secret: $external_google_secret, external_google_additional_client_ids: $external_google_additional_client_ids, external_google_skip_nonce_check: $external_google_skip_nonce_check, external_kakao_enabled: $external_kakao_enabled, external_kakao_client_id: $external_kakao_client_id, external_kakao_email_optional: $external_kakao_email_optional, external_kakao_secret: $external_kakao_secret, external_keycloak_enabled: $external_keycloak_enabled, external_keycloak_client_id: $external_keycloak_client_id, external_keycloak_email_optional: $external_keycloak_email_optional, external_keycloak_secret: $external_keycloak_secret, external_keycloak_url: $external_keycloak_url, external_linkedin_oidc_enabled: $external_linkedin_oidc_enabled, external_linkedin_oidc_client_id: $external_linkedin_oidc_client_id, external_linkedin_oidc_email_optional: $external_linkedin_oidc_email_optional, external_linkedin_oidc_secret: $external_linkedin_oidc_secret, external_slack_oidc_enabled: $external_slack_oidc_enabled, external_slack_oidc_client_id: $external_slack_oidc_client_id, external_slack_oidc_email_optional: $external_slack_oidc_email_optional, external_slack_oidc_secret: $external_slack_oidc_secret, external_notion_enabled: $external_notion_enabled, external_notion_client_id: $external_notion_client_id, external_notion_email_optional: $external_notion_email_optional, external_notion_secret: $external_notion_secret, external_slack_enabled: $external_slack_enabled, external_slack_client_id: $external_slack_client_id, external_slack_email_optional: $external_slack_email_optional, external_slack_secret: $external_slack_secret, external_spotify_enabled: $external_spotify_enabled, external_spotify_client_id: $external_spotify_client_id, external_spotify_email_optional: $external_spotify_email_optional, external_spotify_secret: $external_spotify_secret, external_twitch_enabled: $external_twitch_enabled, external_twitch_client_id: $external_twitch_client_id, external_twitch_email_optional: $external_twitch_email_optional, external_twitch_secret: $external_twitch_secret, external_twitter_enabled: $external_twitter_enabled, external_twitter_client_id: $external_twitter_client_id, external_twitter_email_optional: $external_twitter_email_optional, external_twitter_secret: $external_twitter_secret, external_x_enabled: $external_x_enabled, external_x_client_id: $external_x_client_id, external_x_email_optional: $external_x_email_optional, external_x_secret: $external_x_secret, external_workos_enabled: $external_workos_enabled, external_workos_client_id: $external_workos_client_id, external_workos_secret: $external_workos_secret, external_workos_url: $external_workos_url, external_web3_solana_enabled: $external_web3_solana_enabled, external_web3_ethereum_enabled: $external_web3_ethereum_enabled, external_zoom_enabled: $external_zoom_enabled, external_zoom_client_id: $external_zoom_client_id, external_zoom_email_optional: $external_zoom_email_optional, external_zoom_secret: $external_zoom_secret, db_max_pool_size: $db_max_pool_size, db_max_pool_size_unit: $db_max_pool_size_unit, api_max_request_duration: $api_max_request_duration, mfa_totp_enroll_enabled: $mfa_totp_enroll_enabled, mfa_totp_verify_enabled: $mfa_totp_verify_enabled, mfa_web_authn_enroll_enabled: $mfa_web_authn_enroll_enabled, mfa_web_authn_verify_enabled: $mfa_web_authn_verify_enabled, passkey_enabled: $passkey_enabled, webauthn_rp_display_name: $webauthn_rp_display_name, webauthn_rp_id: $webauthn_rp_id, webauthn_rp_origins: $webauthn_rp_origins, mfa_phone_enroll_enabled: $mfa_phone_enroll_enabled, mfa_phone_verify_enabled: $mfa_phone_verify_enabled, mfa_phone_max_frequency: $mfa_phone_max_frequency, mfa_phone_otp_length: $mfa_phone_otp_length, mfa_phone_template: $mfa_phone_template, nimbus_oauth_client_id: $nimbus_oauth_client_id, nimbus_oauth_client_secret: $nimbus_oauth_client_secret, oauth_server_enabled: $oauth_server_enabled, oauth_server_allow_dynamic_registration: $oauth_server_allow_dynamic_registration, oauth_server_authorization_path: $oauth_server_authorization_path, custom_oauth_enabled: $custom_oauth_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new third-party auth integration
#
# POST /v1/projects/{ref}/config/auth/third-party-auth
# operationId: v1-create-project-tpa-integration
export def "projects-config-auth-third-party-auth v1-create-project-tpa-integration" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --oidc-issuer-url: string
  --jwks-url: string
  --custom-jwks: any
]: any -> record<id: string, type: string, oidc_issuer_url: string, jwks_url: string, custom_jwks: any, resolved_jwks: any, inserted_at: string, updated_at: string, resolved_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/third-party-auth")
  let body = {oidc_issuer_url: $oidc_issuer_url, jwks_url: $jwks_url, custom_jwks: $custom_jwks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all third-party auth integrations
#
# GET /v1/projects/{ref}/config/auth/third-party-auth
# operationId: v1-list-project-tpa-integrations
export def "projects-config-auth-third-party-auth v1-list-project-tpa-integrations" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, type: string, oidc_issuer_url: string, jwks_url: string, custom_jwks: any, resolved_jwks: any, inserted_at: string, updated_at: string, resolved_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/third-party-auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a third-party auth integration
#
# DELETE /v1/projects/{ref}/config/auth/third-party-auth/{tpa_id}
# operationId: v1-delete-project-tpa-integration
export def "projects-config-auth-third-party-auth v1-delete-project-tpa-integration" [
  ref: string
  tpa_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, oidc_issuer_url: string, jwks_url: string, custom_jwks: any, resolved_jwks: any, inserted_at: string, updated_at: string, resolved_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/third-party-auth/($tpa_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a third-party integration
#
# GET /v1/projects/{ref}/config/auth/third-party-auth/{tpa_id}
# operationId: v1-get-project-tpa-integration
export def "projects-config-auth-third-party-auth v1-get-project-tpa-integration" [
  ref: string
  tpa_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, oidc_issuer_url: string, jwks_url: string, custom_jwks: any, resolved_jwks: any, inserted_at: string, updated_at: string, resolved_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/third-party-auth/($tpa_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pauses the given project
#
# POST /v1/projects/{ref}/pause
# operationId: v1-pause-a-project
export def "projects-pause v1-pause-a-project" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restarts the given project
#
# POST /v1/projects/{ref}/restart
# operationId: v1-restart-a-project
export def "projects-restart v1-restart-a-project" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists available restore versions for the given project
#
# GET /v1/projects/{ref}/restore
# operationId: v1-list-available-restore-versions
export def "projects-restore v1-list-available-restore-versions" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available_versions: table<version: string, release_channel: string, postgres_engine: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores the given project
#
# POST /v1/projects/{ref}/restore
# operationId: v1-restore-a-project
export def "projects-restore v1-restore-a-project" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancels the given project restoration
#
# POST /v1/projects/{ref}/restore/cancel
# operationId: v1-cancel-a-project-restoration
export def "projects-restore-cancel v1-cancel-a-project-restoration" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/restore/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List billing addons and compute instance selections
#
# GET /v1/projects/{ref}/billing/addons
# operationId: v1-list-project-addons
export def "projects-billing-addons v1-list-project-addons" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<selected_addons: table<type: string, variant: record>, available_addons: table<type: string, name: string, variants: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/billing/addons")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apply or update billing addons, including compute instance size
#
# PATCH /v1/projects/{ref}/billing/addons
# operationId: v1-apply-project-addon
export def "projects-billing-addons v1-apply-project-addon" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  addon_variant: any
  addon_type: string@addon-type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/billing/addons")
  let body = {addon_variant: $addon_variant, addon_type: $addon_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove billing addons or revert compute instance sizing
#
# DELETE /v1/projects/{ref}/billing/addons/{addon_variant}
# operationId: v1-remove-project-addon
export def "projects-billing-addons v1-remove-project-addon" [
  ref: string
  addon_variant: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/billing/addons/($addon_variant)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project claim token
#
# GET /v1/projects/{ref}/claim-token
# operationId: v1-get-project-claim-token
export def "projects-claim-token v1-get-project-claim-token" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token_alias: string, expires_at: string, created_at: string, created_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/claim-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates project claim token
#
# POST /v1/projects/{ref}/claim-token
# operationId: v1-create-project-claim-token
export def "projects-claim-token v1-create-project-claim-token" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: string, token_alias: string, expires_at: string, created_at: string, created_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/claim-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revokes project claim token
#
# DELETE /v1/projects/{ref}/claim-token
# operationId: v1-delete-project-claim-token
export def "projects-claim-token v1-delete-project-claim-token" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/claim-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project performance advisors.
#
# GET /v1/projects/{ref}/advisors/performance
# DEPRECATED
# operationId: v1-get-performance-advisors
@deprecated
export def "projects-advisors-performance v1-get-performance-advisors" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<lints: table<name: string, title: string, level: string, facing: string, categories: list, description: string, detail: string, remediation: string, metadata: record, cache_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/advisors/performance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project security advisors.
#
# GET /v1/projects/{ref}/advisors/security
# DEPRECATED
# operationId: v1-get-security-advisors
@deprecated
export def "projects-advisors-security v1-get-security-advisors" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lint-type: string@lint-type-completer # e.g. sql
]: nothing -> record<lints: table<name: string, title: string, level: string, facing: string, categories: list, description: string, detail: string, remediation: string, metadata: record, cache_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lint_type" $lint_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/advisors/security" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project's logs
#
# GET /v1/projects/{ref}/analytics/endpoints/logs.all
# operationId: v1-get-project-logs
export def "projects-analytics-endpoints-logsall v1-get-project-logs" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sql: string # Custom SQL query to execute on the logs. See [querying logs](/docs/guides/telemetry/logs?queryGroups=product&product=postgres&queryGroups=source&source=edge_logs#querying-with-the-logs-explorer) for more details.
  --iso-timestamp-start: string # format: date-time, e.g. 2025-03-01T00:00:00Z
  --iso-timestamp-end: string # format: date-time, e.g. 2025-03-01T23:59:59Z
]: nothing -> record<result: list<any>, error: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sql" $sql "scalar") (serialize-qp "iso_timestamp_start" $iso_timestamp_start "scalar") (serialize-qp "iso_timestamp_end" $iso_timestamp_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/analytics/endpoints/logs.all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project's usage api counts
#
# GET /v1/projects/{ref}/analytics/endpoints/usage.api-counts
# operationId: v1-get-project-usage-api-count
export def "projects-analytics-endpoints-usageapi-counts v1-get-project-usage-api-count" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string@interval-completer # e.g. 1day
]: nothing -> record<result: table<timestamp: string, total_auth_requests: float, total_realtime_requests: float, total_rest_requests: float, total_storage_requests: float>, error: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/analytics/endpoints/usage.api-counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project's usage api requests count
#
# GET /v1/projects/{ref}/analytics/endpoints/usage.api-requests-count
# operationId: v1-get-project-usage-request-count
export def "projects-analytics-endpoints-usageapi-requests-count v1-get-project-usage-request-count" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: table<count: float>, error: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/analytics/endpoints/usage.api-requests-count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a project's function combined statistics
#
# GET /v1/projects/{ref}/analytics/endpoints/functions.combined-stats
# operationId: v1-get-project-function-combined-stats
export def "projects-analytics-endpoints-functionscombined-stats v1-get-project-function-combined-stats" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string@interval-completer-1 # e.g. 1hr
  --function-id: string # e.g. 3c078cce-ad70-4148-9f37-4da362789053
]: nothing -> record<result: list<any>, error: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "interval" $interval "scalar") (serialize-qp "function_id" $function_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/analytics/endpoints/functions.combined-stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [Beta] Create a login role for CLI with temporary password
#
# POST /v1/projects/{ref}/cli/login-role
# operationId: v1-create-login-role
export def "projects-cli-login-role v1-create-login-role" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --read-only: oneof<nothing, bool>
]: any -> record<role: string, password: string, ttl_seconds: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/cli/login-role")
  let body = {read_only: $read_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Delete existing login roles used by CLI
#
# DELETE /v1/projects/{ref}/cli/login-role
# operationId: v1-delete-login-roles
export def "projects-cli-login-role v1-delete-login-roles" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/cli/login-role")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List applied migration versions
#
# GET /v1/projects/{ref}/database/migrations
# operationId: v1-list-migration-history
export def "projects-database-migrations v1-list-migration-history" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<version: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/migrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Apply a database migration
#
# POST /v1/projects/{ref}/database/migrations
# operationId: v1-apply-a-migration
export def "projects-database-migrations v1-apply-a-migration" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique key to ensure the same migration is tracked only once.
  --body-query: string
  --name: string
  --rollback: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/migrations")
  let body = {query: $body_query, name: $name, rollback: $rollback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upsert a database migration without applying
#
# PUT /v1/projects/{ref}/database/migrations
# operationId: v1-upsert-a-migration
export def "projects-database-migrations v1-upsert-a-migration" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Idempotency-Key: string # A unique key to ensure the same migration is tracked only once.
  --body-query: string
  --name: string
  --rollback: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/migrations")
  let body = {query: $body_query, name: $name, rollback: $rollback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rollback database migrations and remove them from history table
#
# DELETE /v1/projects/{ref}/database/migrations
# operationId: v1-rollback-migrations
export def "projects-database-migrations v1-rollback-migrations" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gte: string # Rollback migrations greater or equal to this version (e.g. 20250312000000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gte" $gte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/database/migrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an existing entry from migration history
#
# GET /v1/projects/{ref}/database/migrations/{version}
# operationId: v1-get-a-migration
export def "projects-database-migrations v1-get-a-migration" [
  ref: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<version: string, name: string, statements: list<string>, rollback: list<string>, created_by: string, idempotency_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/migrations/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch an existing entry in migration history
#
# PATCH /v1/projects/{ref}/database/migrations/{version}
# operationId: v1-patch-a-migration
export def "projects-database-migrations v1-patch-a-migration" [
  ref: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --rollback: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/migrations/($version)")
  let body = {name: $name, rollback: $rollback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Run sql query
#
# POST /v1/projects/{ref}/database/query
# operationId: v1-run-a-query
export def "projects-database-query v1-run-a-query" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string
  --parameters: list
  --read-only: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/query")
  let body = {query: $body_query, parameters: $parameters, read_only: $read_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Run a sql query as supabase_read_only_user
#
# POST /v1/projects/{ref}/database/query/read-only
# operationId: v1-read-only-query
export def "projects-database-query-read-only v1-read-only-query" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string
  --parameters: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/query/read-only")
  let body = {query: $body_query, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [Beta] Enables Database Webhooks on the project
#
# POST /v1/projects/{ref}/database/webhooks/enable
# operationId: v1-enable-database-webhook
export def "projects-database-webhooks-enable v1-enable-database-webhook" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/database/webhooks/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets database metadata for the given project.
#
# GET /v1/projects/{ref}/database/context
# DEPRECATED
# operationId: v1-get-database-metadata
@deprecated
export def "projects-database-context v1-get-database-metadata" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<databases: table<name: string, schemas: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/context")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the database password
#
# PATCH /v1/projects/{ref}/database/password
# operationId: v1-update-database-password
export def "projects-database-password v1-update-database-password" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get user-id to role mappings for JIT access
#
# GET /v1/projects/{ref}/database/jit
# operationId: v1-get-jit-access
export def "projects-database-jit v1-get-jit-access" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user_id: string, user_roles: table<role: string, expires_at: float, allowed_networks: record, branches_only: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/jit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authorize user-id to role mappings for JIT access
#
# POST /v1/projects/{ref}/database/jit
# operationId: v1-authorize-jit-access
export def "projects-database-jit v1-authorize-jit-access" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  role: string
  rhost: string
]: any -> record<user_id: string, user_role: record<role: string, expires_at: float, allowed_networks: record<allowed_cidrs: list, allowed_cidrs_v6: list>, branches_only: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/jit")
  let body = {role: $role, rhost: $rhost} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a user mapping for JIT access
#
# PUT /v1/projects/{ref}/database/jit
# operationId: v1-update-jit-access
# --roles item shape: {role: string, expires_at?: float, allowed_networks?: record, branches_only?: bool}
export def "projects-database-jit v1-update-jit-access" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # format: uuid
  roles: list # item shape: {role: string, expires_at?: float, allowed_networks?: record, branches_only?: bool}
]: any -> record<user_id: string, user_roles: table<role: string, expires_at: float, allowed_networks: record, branches_only: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/jit")
  let body = {user_id: $user_id, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all user-id to role mappings for JIT access
#
# GET /v1/projects/{ref}/database/jit/list
# operationId: v1-list-jit-access
export def "projects-database-jit-list v1-list-jit-access" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<user_id: string, user_roles: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/jit/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete JIT access by user-id
#
# DELETE /v1/projects/{ref}/database/jit/{user_id}
# operationId: v1-delete-jit-access
export def "projects-database-jit v1-delete-jit-access" [
  ref: string
  user_id: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/database/jit/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get PostgREST OpenAPI spec
#
# GET /v1/projects/{ref}/database/openapi
# operationId: v1-get-database-openapi
export def "projects-database-openapi v1-get-database-openapi" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: string # The database schema to generate the OpenAPI spec for (default: public)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/database/openapi" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all functions
#
# GET /v1/projects/{ref}/functions
# operationId: v1-list-all-functions
export def "projects-functions v1-list-all-functions" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, slug: string, name: string, status: string, version: int, created_at: int, updated_at: int, verify_jwt: bool, import_map: bool, entrypoint_path: string, import_map_path: string, ezbr_sha256: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/functions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a function
#
# POST /v1/projects/{ref}/functions
# DEPRECATED
# operationId: v1-create-a-function
@deprecated
export def "projects-functions v1-create-a-function" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --slug: string # e.g. hello-world
  --name: string # e.g. Hello World
  --verify-jwt: oneof<nothing, bool> # Boolean string, true or false (e.g. true)
  --import-map: oneof<nothing, bool> # Boolean string, true or false (e.g. false)
  --entrypoint-path: string # e.g. index.ts
  --import-map-path: string # e.g. import_map.json
  --ezbr-sha256: string # e.g. 44c691990518d25498f0fd80cf6631ecf2b58eb9c5eb2a087dd1688f2904dac7
  slug: string
  name: string
  --body-body: string
  --verify-jwt: oneof<nothing, bool>
]: any -> record<id: string, slug: string, name: string, status: string, version: int, created_at: int, updated_at: int, verify_jwt: bool, import_map: bool, entrypoint_path: string, import_map_path: string, ezbr_sha256: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "verify_jwt" $verify_jwt "scalar") (serialize-qp "import_map" $import_map "scalar") (serialize-qp "entrypoint_path" $entrypoint_path "scalar") (serialize-qp "import_map_path" $import_map_path "scalar") (serialize-qp "ezbr_sha256" $ezbr_sha256 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/functions" $qp)
  let body = {slug: $slug, name: $name, body: $body_body, verify_jwt: $verify_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bulk update functions
#
# PUT /v1/projects/{ref}/functions
# operationId: v1-bulk-update-functions
export def "projects-functions v1-bulk-update-functions" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<functions: table<id: string, slug: string, name: string, status: string, version: int, created_at: int, updated_at: int, verify_jwt: bool, import_map: bool, entrypoint_path: string, import_map_path: string, ezbr_sha256: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/functions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deploy a function
#
# POST /v1/projects/{ref}/functions/deploy
# operationId: v1-deploy-a-function
# --metadata shape: {entrypoint_path: string, import_map_path?: string, static_patterns?: list, verify_jwt?: bool, name?: string}
export def "projects-functions-deploy v1-deploy-a-function" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --slug: string # e.g. hello-world
  --bundleOnly: oneof<nothing, bool> # Boolean string, true or false (e.g. false)
  --file: list
  metadata: record # shape: {entrypoint_path: string, import_map_path?: string, static_patterns?: list, verify_jwt?: bool, name?: string}
]: any -> record<id: string, slug: string, name: string, status: string, version: int, created_at: int, updated_at: int, verify_jwt: bool, import_map: bool, entrypoint_path: string, import_map_path: string, ezbr_sha256: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar") (serialize-qp "bundleOnly" $bundleOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/functions/deploy" $qp)
  let body = {file: $file, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve a function
#
# GET /v1/projects/{ref}/functions/{function_slug}
# operationId: v1-get-a-function
export def "projects-functions v1-get-a-function" [
  ref: string
  function_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, slug: string, name: string, status: string, version: int, created_at: int, updated_at: int, verify_jwt: bool, import_map: bool, entrypoint_path: string, import_map_path: string, ezbr_sha256: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/functions/($function_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a function
#
# PATCH /v1/projects/{ref}/functions/{function_slug}
# operationId: v1-update-a-function
export def "projects-functions v1-update-a-function" [
  ref: string
  function_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --slug: string # e.g. hello-world
  --name: string # e.g. Hello World
  --verify-jwt: oneof<nothing, bool> # Boolean string, true or false (e.g. true)
  --import-map: oneof<nothing, bool> # Boolean string, true or false (e.g. false)
  --entrypoint-path: string # e.g. index.ts
  --import-map-path: string # e.g. import_map.json
  --ezbr-sha256: string # e.g. 44c691990518d25498f0fd80cf6631ecf2b58eb9c5eb2a087dd1688f2904dac7
  --name: string
  --body-body: string
  --verify-jwt: oneof<nothing, bool>
]: any -> record<id: string, slug: string, name: string, status: string, version: int, created_at: int, updated_at: int, verify_jwt: bool, import_map: bool, entrypoint_path: string, import_map_path: string, ezbr_sha256: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "slug" $slug "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "verify_jwt" $verify_jwt "scalar") (serialize-qp "import_map" $import_map "scalar") (serialize-qp "entrypoint_path" $entrypoint_path "scalar") (serialize-qp "import_map_path" $import_map_path "scalar") (serialize-qp "ezbr_sha256" $ezbr_sha256 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/functions/($function_slug)" $qp)
  let body = {name: $name, body: $body_body, verify_jwt: $verify_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a function
#
# DELETE /v1/projects/{ref}/functions/{function_slug}
# operationId: v1-delete-a-function
export def "projects-functions v1-delete-a-function" [
  ref: string
  function_slug: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/functions/($function_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a function body
#
# GET /v1/projects/{ref}/functions/{function_slug}/body
# operationId: v1-get-a-function-body
export def "projects-functions-body v1-get-a-function-body" [
  ref: string
  function_slug: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/functions/($function_slug)/body")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all buckets
#
# GET /v1/projects/{ref}/storage/buckets
# operationId: v1-list-all-buckets
export def "projects-storage-buckets v1-list-all-buckets" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, owner: string, created_at: string, updated_at: string, public: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/storage/buckets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get database disk attributes
#
# GET /v1/projects/{ref}/config/disk
# operationId: v1-get-database-disk
export def "projects-config-disk v1-get-database-disk" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: any, last_modified_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/disk")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify database disk
#
# POST /v1/projects/{ref}/config/disk
# operationId: v1-modify-database-disk
export def "projects-config-disk v1-modify-database-disk" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/disk")
  let body = {attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get disk utilization
#
# GET /v1/projects/{ref}/config/disk/util
# operationId: v1-get-disk-utilization
export def "projects-config-disk-util v1-get-disk-utilization" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<timestamp: string, metrics: record<fs_size_bytes: float, fs_avail_bytes: float, fs_used_bytes: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/disk/util")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project disk autoscale config
#
# GET /v1/projects/{ref}/config/disk/autoscale
# operationId: v1-get-project-disk-autoscale-config
export def "projects-config-disk-autoscale v1-get-project-disk-autoscale-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<growth_percent: int, min_increment_gb: int, max_size_gb: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/disk/autoscale")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project's storage config
#
# GET /v1/projects/{ref}/config/storage
# operationId: v1-get-storage-config
export def "projects-config-storage v1-get-storage-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fileSizeLimit: int, features: record<imageTransformation: record<enabled: bool>, s3Protocol: record<enabled: bool>, icebergCatalog: record<enabled: bool, maxNamespaces: int, maxTables: int, maxCatalogs: int>, vectorBuckets: record<enabled: bool, maxBuckets: int, maxIndexes: int>>, capabilities: record<list_v2: bool, iceberg_catalog: bool>, external: record<upstreamTarget: string>, migrationVersion: string, databasePoolMode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/storage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates project's storage config
#
# PATCH /v1/projects/{ref}/config/storage
# operationId: v1-update-storage-config
# --features shape: {imageTransformation?: record, s3Protocol?: record, icebergCatalog?: record, vectorBuckets?: record}
# --external shape: {upstreamTarget: "main"|"canary"}
export def "projects-config-storage v1-update-storage-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fileSizeLimit: int # format: int64
  --features: record # shape: {imageTransformation?: record, s3Protocol?: record, icebergCatalog?: record, vectorBuckets?: record}
  --external: record # shape: {upstreamTarget: "main"|"canary"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/storage")
  let body = {fileSizeLimit: $fileSizeLimit, features: $features, external: $external} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get project's pgbouncer config
#
# GET /v1/projects/{ref}/config/database/pgbouncer
# operationId: v1-get-project-pgbouncer-config
export def "projects-config-database-pgbouncer v1-get-project-pgbouncer-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<default_pool_size: int, ignore_startup_parameters: string, max_client_conn: int, pool_mode: string, connection_string: string, server_idle_timeout: int, server_lifetime: int, query_wait_timeout: int, reserve_pool_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/database/pgbouncer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project's supavisor config
#
# GET /v1/projects/{ref}/config/database/pooler
# operationId: v1-get-pooler-config
export def "projects-config-database-pooler v1-get-pooler-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<identifier: string, database_type: string, is_using_scram_auth: bool, db_user: string, db_host: string, db_port: int, db_name: string, connection_string: string, connectionString: string, default_pool_size: int, max_client_conn: int, pool_mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/database/pooler")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates project's supavisor config
#
# PATCH /v1/projects/{ref}/config/database/pooler
# operationId: v1-update-pooler-config
export def "projects-config-database-pooler v1-update-pooler-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-pool-size: int # nullable
  --pool-mode: string@pool-mode-completer # Dedicated pooler mode for the project
]: any -> record<default_pool_size: int, pool_mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/database/pooler")
  let body = {default_pool_size: $default_pool_size, pool_mode: $pool_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets project's Postgres config
#
# GET /v1/projects/{ref}/config/database/postgres
# operationId: v1-get-postgres-config
export def "projects-config-database-postgres v1-get-postgres-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<effective_cache_size: string, logical_decoding_work_mem: string, cron_log_statement: bool, log_autovacuum_min_duration: string, log_checkpoints: bool, log_connections: bool, log_disconnections: bool, log_duration: bool, log_lock_waits: bool, log_recovery_conflict_waits: bool, log_replication_commands: bool, log_startup_progress_interval: string, log_temp_files: string, maintenance_work_mem: string, track_activity_query_size: string, max_connections: int, max_locks_per_transaction: int, max_parallel_maintenance_workers: int, max_parallel_workers: int, max_parallel_workers_per_gather: int, max_replication_slots: int, max_slot_wal_keep_size: string, max_standby_archive_delay: string, max_standby_streaming_delay: string, max_wal_size: string, max_wal_senders: int, max_worker_processes: int, session_replication_role: string, shared_buffers: string, statement_timeout: string, track_commit_timestamp: bool, wal_keep_size: string, wal_sender_timeout: string, work_mem: string, checkpoint_timeout: string, hot_standby_feedback: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/database/postgres")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates project's Postgres config
#
# PUT /v1/projects/{ref}/config/database/postgres
# operationId: v1-update-postgres-config
export def "projects-config-database-postgres v1-update-postgres-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --effective-cache-size: string
  --logical-decoding-work-mem: string
  --cronlog-statement: oneof<nothing, bool>
  --log-autovacuum-min-duration: string # Default unit: ms
  --log-checkpoints: oneof<nothing, bool>
  --log-connections: oneof<nothing, bool>
  --log-disconnections: oneof<nothing, bool>
  --log-duration: oneof<nothing, bool>
  --log-lock-waits: oneof<nothing, bool>
  --log-recovery-conflict-waits: oneof<nothing, bool>
  --log-replication-commands: oneof<nothing, bool>
  --log-startup-progress-interval: string # Default unit: ms
  --log-temp-files: string
  --maintenance-work-mem: string
  --track-activity-query-size: string
  --max-connections: int
  --max-locks-per-transaction: int
  --max-parallel-maintenance-workers: int
  --max-parallel-workers: int
  --max-parallel-workers-per-gather: int
  --max-replication-slots: int
  --max-slot-wal-keep-size: string
  --max-standby-archive-delay: string
  --max-standby-streaming-delay: string
  --max-wal-size: string
  --max-wal-senders: int
  --max-worker-processes: int
  --session-replication-role: string@session-replication-role-completer
  --shared-buffers: string
  --statement-timeout: string # Default unit: ms
  --track-commit-timestamp: oneof<nothing, bool>
  --wal-keep-size: string
  --wal-sender-timeout: string # Default unit: ms
  --work-mem: string
  --checkpoint-timeout: string # Default unit: s
  --hot-standby-feedback: oneof<nothing, bool>
  --restart-database: oneof<nothing, bool>
]: any -> record<effective_cache_size: string, logical_decoding_work_mem: string, cron_log_statement: bool, log_autovacuum_min_duration: string, log_checkpoints: bool, log_connections: bool, log_disconnections: bool, log_duration: bool, log_lock_waits: bool, log_recovery_conflict_waits: bool, log_replication_commands: bool, log_startup_progress_interval: string, log_temp_files: string, maintenance_work_mem: string, track_activity_query_size: string, max_connections: int, max_locks_per_transaction: int, max_parallel_maintenance_workers: int, max_parallel_workers: int, max_parallel_workers_per_gather: int, max_replication_slots: int, max_slot_wal_keep_size: string, max_standby_archive_delay: string, max_standby_streaming_delay: string, max_wal_size: string, max_wal_senders: int, max_worker_processes: int, session_replication_role: string, shared_buffers: string, statement_timeout: string, track_commit_timestamp: bool, wal_keep_size: string, wal_sender_timeout: string, work_mem: string, checkpoint_timeout: string, hot_standby_feedback: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/database/postgres")
  let body = {effective_cache_size: $effective_cache_size, logical_decoding_work_mem: $logical_decoding_work_mem, cron.log_statement: $cronlog_statement, log_autovacuum_min_duration: $log_autovacuum_min_duration, log_checkpoints: $log_checkpoints, log_connections: $log_connections, log_disconnections: $log_disconnections, log_duration: $log_duration, log_lock_waits: $log_lock_waits, log_recovery_conflict_waits: $log_recovery_conflict_waits, log_replication_commands: $log_replication_commands, log_startup_progress_interval: $log_startup_progress_interval, log_temp_files: $log_temp_files, maintenance_work_mem: $maintenance_work_mem, track_activity_query_size: $track_activity_query_size, max_connections: $max_connections, max_locks_per_transaction: $max_locks_per_transaction, max_parallel_maintenance_workers: $max_parallel_maintenance_workers, max_parallel_workers: $max_parallel_workers, max_parallel_workers_per_gather: $max_parallel_workers_per_gather, max_replication_slots: $max_replication_slots, max_slot_wal_keep_size: $max_slot_wal_keep_size, max_standby_archive_delay: $max_standby_archive_delay, max_standby_streaming_delay: $max_standby_streaming_delay, max_wal_size: $max_wal_size, max_wal_senders: $max_wal_senders, max_worker_processes: $max_worker_processes, session_replication_role: $session_replication_role, shared_buffers: $shared_buffers, statement_timeout: $statement_timeout, track_commit_timestamp: $track_commit_timestamp, wal_keep_size: $wal_keep_size, wal_sender_timeout: $wal_sender_timeout, work_mem: $work_mem, checkpoint_timeout: $checkpoint_timeout, hot_standby_feedback: $hot_standby_feedback, restart_database: $restart_database} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets realtime configuration
#
# GET /v1/projects/{ref}/config/realtime
# operationId: v1-get-realtime-config
export def "projects-config-realtime v1-get-realtime-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<private_only: bool, connection_pool: int, max_concurrent_users: int, max_events_per_second: int, max_bytes_per_second: int, max_channels_per_client: int, max_joins_per_second: int, max_presence_events_per_second: int, max_payload_size_in_kb: int, suspend: bool, presence_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/realtime")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates realtime configuration
#
# PATCH /v1/projects/{ref}/config/realtime
# operationId: v1-update-realtime-config
export def "projects-config-realtime v1-update-realtime-config" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --private-only: oneof<nothing, bool> # Whether to only allow private channels
  --connection-pool: int # Sets connection pool size for Realtime Authorization
  --max-concurrent-users: int # Sets maximum number of concurrent users rate limit
  --max-events-per-second: int # Sets maximum number of events per second rate per channel limit
  --max-bytes-per-second: int # Sets maximum number of bytes per second rate per channel limit
  --max-channels-per-client: int # Sets maximum number of channels per client rate limit
  --max-joins-per-second: int # Sets maximum number of joins per second rate limit
  --max-presence-events-per-second: int # Sets maximum number of presence events per second rate limit
  --max-payload-size-in-kb: int # Sets maximum number of payload size in KB rate limit
  --suspend: oneof<nothing, bool> # Disables the Realtime service for this project when true. Set to false to re-enable it.
  --presence-enabled: oneof<nothing, bool> # Whether to enable presence
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/realtime")
  let body = {private_only: $private_only, connection_pool: $connection_pool, max_concurrent_users: $max_concurrent_users, max_events_per_second: $max_events_per_second, max_bytes_per_second: $max_bytes_per_second, max_channels_per_client: $max_channels_per_client, max_joins_per_second: $max_joins_per_second, max_presence_events_per_second: $max_presence_events_per_second, max_payload_size_in_kb: $max_payload_size_in_kb, suspend: $suspend, presence_enabled: $presence_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Shutdowns realtime connections for a project
#
# POST /v1/projects/{ref}/config/realtime/shutdown
# operationId: v1-shutdown-realtime
export def "projects-config-realtime-shutdown v1-shutdown-realtime" [
  ref: string
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
  let full_url = (build-url $base $"/v1/projects/($ref)/config/realtime/shutdown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new SSO provider
#
# POST /v1/projects/{ref}/config/auth/sso/providers
# operationId: v1-create-a-sso-provider
# --attribute_mapping shape: {keys: record}
export def "projects-config-auth-sso-providers v1-create-a-sso-provider" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-1 # What type of provider will be created
  --metadata-xml: string
  --metadata-url: string
  --domains: list
  --attribute-mapping: record # shape: {keys: record}
  --name-id-format: string@name-id-format-completer
]: any -> record<id: string, saml: record<id: string, entity_id: string, metadata_url: string, metadata_xml: string, attribute_mapping: record<keys: record>, name_id_format: string>, domains: table<id: string, domain: string, created_at: string, updated_at: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/sso/providers")
  let body = {type: $type, metadata_xml: $metadata_xml, metadata_url: $metadata_url, domains: $domains, attribute_mapping: $attribute_mapping, name_id_format: $name_id_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all SSO providers
#
# GET /v1/projects/{ref}/config/auth/sso/providers
# operationId: v1-list-all-sso-provider
export def "projects-config-auth-sso-providers v1-list-all-sso-provider" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<id: string, saml: record, domains: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/sso/providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a SSO provider by its UUID
#
# GET /v1/projects/{ref}/config/auth/sso/providers/{provider_id}
# operationId: v1-get-a-sso-provider
export def "projects-config-auth-sso-providers v1-get-a-sso-provider" [
  ref: string
  provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, saml: record<id: string, entity_id: string, metadata_url: string, metadata_xml: string, attribute_mapping: record<keys: record>, name_id_format: string>, domains: table<id: string, domain: string, created_at: string, updated_at: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/sso/providers/($provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a SSO provider by its UUID
#
# PUT /v1/projects/{ref}/config/auth/sso/providers/{provider_id}
# operationId: v1-update-a-sso-provider
# --attribute_mapping shape: {keys: record}
export def "projects-config-auth-sso-providers v1-update-a-sso-provider" [
  ref: string
  provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata-xml: string
  --metadata-url: string
  --domains: list
  --attribute-mapping: record # shape: {keys: record}
  --name-id-format: string@name-id-format-completer
]: any -> record<id: string, saml: record<id: string, entity_id: string, metadata_url: string, metadata_xml: string, attribute_mapping: record<keys: record>, name_id_format: string>, domains: table<id: string, domain: string, created_at: string, updated_at: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/sso/providers/($provider_id)")
  let body = {metadata_xml: $metadata_xml, metadata_url: $metadata_url, domains: $domains, attribute_mapping: $attribute_mapping, name_id_format: $name_id_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a SSO provider by its UUID
#
# DELETE /v1/projects/{ref}/config/auth/sso/providers/{provider_id}
# operationId: v1-delete-a-sso-provider
export def "projects-config-auth-sso-providers v1-delete-a-sso-provider" [
  ref: string
  provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, saml: record<id: string, entity_id: string, metadata_url: string, metadata_xml: string, attribute_mapping: record<keys: record>, name_id_format: string>, domains: table<id: string, domain: string, created_at: string, updated_at: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/config/auth/sso/providers/($provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all backups
#
# GET /v1/projects/{ref}/database/backups
# operationId: v1-list-all-backups
export def "projects-database-backups v1-list-all-backups" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<region: string, walg_enabled: bool, pitr_enabled: bool, backups: table<id: int, is_physical_backup: bool, status: string, inserted_at: string>, physical_backup_data: record<earliest_physical_backup_date_unix: int, latest_physical_backup_date_unix: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/backups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores a PITR backup for a database
#
# POST /v1/projects/{ref}/database/backups/restore-pitr
# operationId: v1-restore-pitr-backup
export def "projects-database-backups-restore-pitr v1-restore-pitr-backup" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  recovery_time_target_unix: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/backups/restore-pitr")
  let body = {recovery_time_target_unix: $recovery_time_target_unix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Initiates a creation of a restore point for a database
#
# POST /v1/projects/{ref}/database/backups/restore-point
# operationId: v1-create-restore-point
export def "projects-database-backups-restore-point v1-create-restore-point" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<name: string, status: string, completed_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/backups/restore-point")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get restore points for project
#
# GET /v1/projects/{ref}/database/backups/restore-point
# operationId: v1-get-restore-point
export def "projects-database-backups-restore-point v1-get-restore-point" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: nothing -> record<name: string, status: string, completed_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($ref)/database/backups/restore-point" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores a physical backup for a database
#
# POST /v1/projects/{ref}/database/backups/restore
# operationId: v1-restore-physical-backup
export def "projects-database-backups-restore v1-restore-physical-backup" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/backups/restore")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the backup schedule for a project
#
# GET /v1/projects/{ref}/database/backups/schedule
# operationId: v1-get-backup-schedule
export def "projects-database-backups-schedule v1-get-backup-schedule" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule_for: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/backups/schedule")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the backup schedule time for a project
#
# PATCH /v1/projects/{ref}/database/backups/schedule
# operationId: v1-update-backup-schedule
export def "projects-database-backups-schedule v1-update-backup-schedule" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule_for: string # Time of day to schedule daily backups, in UTC. Format: HH:MM:SS. (e.g. 04:00:00)
]: any -> record<schedule_for: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/backups/schedule")
  let body = {schedule_for: $schedule_for} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Initiates an undo to a given restore point
#
# POST /v1/projects/{ref}/database/backups/undo
# operationId: v1-undo
export def "projects-database-backups-undo v1-undo" [
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($ref)/database/backups/undo")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get entitlements for an organization
#
# GET /v1/organizations/{slug}/entitlements
# operationId: v1-get-organization-entitlements
export def "organizations-entitlements v1-get-organization-entitlements" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entitlements: table<feature: record, hasAccess: bool, type: string, config: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($slug)/entitlements")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List members of an organization
#
# GET /v1/organizations/{slug}/members
# operationId: v1-list-organization-members
export def "organizations-members v1-list-organization-members" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<user_id: string, user_name: string, email: string, role_name: string, mfa_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($slug)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the organization
#
# GET /v1/organizations/{slug}
# operationId: v1-get-an-organization
export def "organizations v1-get-an-organization" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, plan: string, opt_in_tags: list<string>, allowed_release_channels: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets project details for the specified organization and claim token
#
# GET /v1/organizations/{slug}/project-claim/{token}
# operationId: v1-get-organization-project-claim
export def "organizations-project-claim v1-get-organization-project-claim" [
  slug: string
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<project: record<ref: string, name: string>, preview: record<valid: bool, warnings: list<record>, errors: list<record>, info: list<record>, members_exceeding_free_project_limit: list<record>, source_subscription_plan: string, target_subscription_plan: string>, expires_at: string, created_at: string, created_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($slug)/project-claim/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Claims project for the specified organization
#
# POST /v1/organizations/{slug}/project-claim/{token}
# operationId: v1-claim-project-for-organization
export def "organizations-project-claim v1-claim-project-for-organization" [
  slug: string
  token: string
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
  let full_url = (build-url $base $"/v1/organizations/($slug)/project-claim/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all projects for the given organization
#
# GET /v1/organizations/{slug}/projects
# operationId: v1-get-all-projects-for-organization
export def "organizations-projects v1-get-all-projects-for-organization" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Number of projects to skip (default: 0, e.g. 0)
  --limit: int # Number of projects to return per page (default: 100, e.g. 20)
  --search: string # Search projects by name (e.g. acme)
  --qp-sort: string@sort-completer # Sort order for projects (default: name_asc, e.g. created_desc)
  --statuses: string # A comma-separated list of project statuses to filter by.  The following values are supported: `ACTIVE_HEALTHY`, `INACTIVE`. (e.g. ACTIVE_HEALTHY,INACTIVE)
]: nothing -> record<projects: table<ref: string, name: string, cloud_provider: string, region: string, is_branch: bool, status: string, inserted_at: string, databases: list>, pagination: record<count: float, limit: float, offset: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "statuses" $statuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/organizations/($slug)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
