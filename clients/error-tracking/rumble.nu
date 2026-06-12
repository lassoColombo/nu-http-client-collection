# Auto-generated client for Rumble API (deprecated) v2.15.0
# Source: https://api.apis.guru/v2/specs/rumble.run/2.15.0/openapi.json
# Auth: --token flag or $env.RUMBLE_API_DEPRECATED_TOKEN

const BASE_URL = "https://console.rumble.run/api/v1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RUMBLE_API_DEPRECATED_TOKEN | default "" }
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

def base-url-completer [] { ["https://console.rumble.run/api/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["aws_access_secret" "miradore_api_key_v1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-agents get" } } | get name | first)
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

# Get all agents across all organizations
#
# GET /account/agents
# operationId: getAccountAgents
export def "account-agents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all account credentials
#
# GET /account/credentials
# operationId: getAccountCredentials
export def "account-credentials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new credential
#
# PUT /account/credentials
# operationId: createAccountCredential
export def "account-credentials createAccountCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl: record # e.g. {e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8: user, e77602e0-3fb8-4734-aef9-fbc6fdcb0fa9: none}
  --cidrs: string # e.g. 10.0.0.17/32, 192.168.1.0/24
  --global: oneof<nothing, bool> # e.g. false
  --name: string # e.g. credentials_name
  --secret: any
  --type: string@type-completer # e.g. miradore_api_key_v1
]: any -> record<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/credentials")
  let body = {acl: $acl, cidrs: $cidrs, global: $global, name: $name, secret: $secret, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove this credential
#
# DELETE /account/credentials/{credential_id}
# operationId: removeAccountCredential
export def "account-credentials removeAccountCredential" [
  credential_id: string
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
  let full_url = (build-url $base $"/account/credentials/($credential_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get credential details
#
# GET /account/credentials/{credential_id}
# operationId: getAccountCredential
export def "account-credentials get" [
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acl: record, cidrs: list<string>, client_id: string, created_at: int, created_by_email: string, created_by_id: string, global: bool, id: string, last_used_at: int, last_used_by_id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/credentials/($credential_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# System event log as JSON
#
# GET /account/events.json
# operationId: exportEventsJSON
export def "account-eventsjson exportEventsJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> table<action: string, client_id: string, created_at: int, details: record, id: string, organization_id: string, processed_at: int, processor_id: string, site_id: string, source_id: string, source_name: string, source_type: string, state: string, success: bool, target_id: string, target_name: string, target_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/events.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# System event log as JSON line-delimited
#
# GET /account/events.jsonl
# operationId: exportEventsJSONL
export def "account-eventsjsonl exportEventsJSONL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> table<action: string, client_id: string, created_at: int, details: record, id: string, organization_id: string, processed_at: int, processor_id: string, site_id: string, source_id: string, source_name: string, source_type: string, state: string, success: bool, target_id: string, target_name: string, target_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/events.jsonl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all groups
#
# GET /account/groups
# operationId: getAccountGroups
export def "account-groups list" [
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
  let full_url = (build-url $base "/account/groups")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new group
#
# POST /account/groups
# operationId: createAccountGroup
export def "account-groups createAccountGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Viewers Group
  --expires-at: int # format: int64, e.g. 1576300370
  --name: string # e.g. Viewers
  --org-default-role: string # e.g. admin
  --org-roles: record # e.g. {1a5e612e-4d64-45fe-aa3e-afba5cf3b9bf: viewer, fd6d6662-732b-4c4b-8331-051178994384: admin}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/groups")
  let body = {description: $description, expires_at: $expires_at, name: $name, org_default_role: $org_default_role, org_roles: $org_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an existing group
#
# PUT /account/groups
# operationId: updateAccountGroup
export def "account-groups updateAccountGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Viewers Group
  --expires-at: int # format: int64, e.g. 1576300370
  --id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --name: string # e.g. Viewers
  --org-default-role: string # e.g. admin
  --org-roles: record # e.g. {1a5e612e-4d64-45fe-aa3e-afba5cf3b9bf: viewer, fd6d6662-732b-4c4b-8331-051178994384: admin}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/groups")
  let body = {description: $description, expires_at: $expires_at, id: $id, name: $name, org_default_role: $org_default_role, org_roles: $org_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove this group
#
# DELETE /account/groups/{group_id}
# operationId: removeAccountGroup
export def "account-groups removeAccountGroup" [
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
  let full_url = (build-url $base $"/account/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group details
#
# GET /account/groups/{group_id}
# operationId: getAccountGroup
export def "account-groups get" [
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
  let full_url = (build-url $base $"/account/groups/($group_id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all active API keys
#
# GET /account/keys
# operationId: getAccountKeys
export def "account-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new key
#
# PUT /account/keys
# operationId: createAccountKey
export def "account-keys createAccountKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # e.g. Splunk integration key
  --organization-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
]: any -> record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/keys")
  let body = {comment: $comment, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove this key
#
# DELETE /account/keys/{key_id}
# operationId: removeAccountKey
export def "account-keys removeAccountKey" [
  key_id: string
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
  let full_url = (build-url $base $"/account/keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get key details
#
# GET /account/keys/{key_id}
# operationId: getAccountKey
export def "account-keys get" [
  key_id: string
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
  let full_url = (build-url $base $"/account/keys/($key_id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rotates the key secret
#
# PATCH /account/keys/{key_id}/rotate
# operationId: rotateAccountKey
export def "account-keys-rotate rotateAccountKey" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/keys/($key_id)/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get license details
#
# GET /account/license
# operationId: getAccountLicense
export def "account-license get" [
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
  let full_url = (build-url $base "/account/license")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all organization details
#
# GET /account/orgs
# operationId: getAccountOrganizations
export def "account-orgs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/orgs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new organization
#
# PUT /account/orgs
# operationId: createAccountOrganization
export def "account-orgs createAccountOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Wobbly Widgets, Inc.
  --expiration-assets-offline: string # format: number, e.g. 365
  --expiration-assets-stale: string # format: number, e.g. 365
  --expiration-scans: string # format: number, e.g. 365
  --export-token: string # e.g. ETXXXXXXXXXXXXXXXX
  --name: string # e.g. My Organization
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --project: string # format: boolean, e.g. false
]: any -> record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/orgs")
  let body = {description: $description, expiration_assets_offline: $expiration_assets_offline, expiration_assets_stale: $expiration_assets_stale, expiration_scans: $expiration_scans, export_token: $export_token, name: $name, parent_id: $parent_id, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove this organization
#
# DELETE /account/orgs/{org_id}
# operationId: removeAccountOrganization
export def "account-orgs removeAccountOrganization" [
  org_id: string
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
  let full_url = (build-url $base $"/account/orgs/($org_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get organization details
#
# GET /account/orgs/{org_id}
# operationId: getAccountOrganization
export def "account-orgs get" [
  org_id: string
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
  let full_url = (build-url $base $"/account/orgs/($org_id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update organization details
#
# PATCH /account/orgs/{org_id}
# operationId: updateAccountOrganization
export def "account-orgs updateAccountOrganization" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Wobbly Widgets, Inc.
  --expiration-assets-offline: string # format: number, e.g. 365
  --expiration-assets-stale: string # format: number, e.g. 365
  --expiration-scans: string # format: number, e.g. 365
  --export-token: string # e.g. ETXXXXXXXXXXXXXXXX
  --name: string # e.g. My Organization
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --project: string # format: boolean, e.g. false
]: any -> record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/orgs/($org_id)")
  let body = {description: $description, expiration_assets_offline: $expiration_assets_offline, expiration_assets_stale: $expiration_assets_stale, expiration_scans: $expiration_scans, export_token: $export_token, name: $name, parent_id: $parent_id, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes the export token from the specified organization
#
# DELETE /account/orgs/{org_id}/exportToken
# operationId: deleteAccountOrganizationExportToken
export def "account-orgs-export-token delete" [
  org_id: string
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
  let full_url = (build-url $base $"/account/orgs/($org_id)/exportToken")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rotates the organization export token and returns the updated organization
#
# PATCH /account/orgs/{org_id}/exportToken/rotate
# operationId: rotateAccountOrganizationExportToken
export def "account-orgs-export-token-rotate rotateAccountOrganizationExportToken" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/orgs/($org_id)/exportToken/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sites details across all organizations
#
# GET /account/sites
# operationId: getAccountSites
export def "account-sites get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all SSO group mappings
#
# GET /account/sso/groups
# operationId: getAccountGroupMappings
export def "account-sso-groups list" [
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
  let full_url = (build-url $base "/account/sso/groups")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new SSO group mapping
#
# POST /account/sso/groups
# operationId: createAccountGroupMapping
export def "account-sso-groups createAccountGroupMapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: int # format: int64, e.g. 1576300370
  --created-by-email: string # e.g. jsmith@example.com
  --description: string # e.g. Maps basic-attribute to Viewers Group
  group_id: string # format: uuid, e.g. 2b096711-4d28-4417-8635-64af4f62c1ae
  --group-name: string # e.g. Viewers Group
  id: string # format: uuid, e.g. f6cfb91a-52ea-4a86-bf9a-5a891a26f52b
  sso_attribute: string # e.g. basic-attribute
  sso_value: string # e.g. basic-attribute-value
  --updated-at: int # format: int64, e.g. 1576300370
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/sso/groups")
  let body = {created_at: $created_at, created_by_email: $created_by_email, description: $description, group_id: $group_id, group_name: $group_name, id: $id, sso_attribute: $sso_attribute, sso_value: $sso_value, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an existing SSO group mapping
#
# PUT /account/sso/groups
# operationId: updateAccountGroupMapping
export def "account-sso-groups updateAccountGroupMapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: int # format: int64, e.g. 1576300370
  --created-by-email: string # e.g. jsmith@example.com
  --description: string # e.g. Maps basic-attribute to Viewers Group
  group_id: string # format: uuid, e.g. 2b096711-4d28-4417-8635-64af4f62c1ae
  --group-name: string # e.g. Viewers Group
  id: string # format: uuid, e.g. f6cfb91a-52ea-4a86-bf9a-5a891a26f52b
  sso_attribute: string # e.g. basic-attribute
  sso_value: string # e.g. basic-attribute-value
  --updated-at: int # format: int64, e.g. 1576300370
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/sso/groups")
  let body = {created_at: $created_at, created_by_email: $created_by_email, description: $description, group_id: $group_id, group_name: $group_name, id: $id, sso_attribute: $sso_attribute, sso_value: $sso_value, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove this SSO group mapping
#
# DELETE /account/sso/groups/{group_mapping_id}
# operationId: removeAccountGroupMapping
export def "account-sso-groups removeAccountGroupMapping" [
  group_mapping_id: string
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
  let full_url = (build-url $base $"/account/sso/groups/($group_mapping_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SSO group mapping details
#
# GET /account/sso/groups/{group_mapping_id}
# operationId: getAccountGroupMapping
export def "account-sso-groups get" [
  group_mapping_id: string
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
  let full_url = (build-url $base $"/account/sso/groups/($group_mapping_id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all task details across all organizations (up to 1000)
#
# GET /account/tasks
# operationId: getAccountTasks
export def "account-tasks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all scan templates across all organizations (up to 1000)
#
# GET /account/tasks/templates
# operationId: getAccountScanTemplates
export def "account-tasks-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/tasks/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new scan template
#
# POST /account/tasks/templates
# operationId: createAccountScanTemplate
export def "account-tasks-templates createAccountScanTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  acl: record # e.g. {e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8: user}
  --description: string # e.g. My Scan Template
  --global: oneof<nothing, bool> # e.g. false
  name: string # e.g. My Scan Template
  --params: record
]: any -> record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/tasks/templates")
  let body = {acl: $acl, description: $description, global: $global, name: $name, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update scan template
#
# PUT /account/tasks/templates
# operationId: updateAccountScanTemplate
export def "account-tasks-templates updateAccountScanTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  acl: record # e.g. {e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8: user}
  --agent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --client-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --created-at: int # format: int64, e.g. 1576300370
  --created-by: string # format: email, e.g. user@example.com
  --created-by-user-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --cruncher-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --description: string # e.g. My Scan Template
  --body-error: string # e.g. agent unavailable
  --global: oneof<nothing, bool> # e.g. false
  --grace-period: string # e.g. 4
  --hidden: oneof<nothing, bool> # e.g. false
  --hosted-zone-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --linked-task-count: int # format: int32, e.g. 1
  --name: string # e.g. My Scan Template
  --organization-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --params: record
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --recur: oneof<nothing, bool> # e.g. false
  --recur-frequency: string # e.g. hour
  --recur-last: int # format: int64, e.g. 1576300370
  --recur-last-task-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --recur-next: int # format: int64, e.g. 1576300370
  --site-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --size-data: int # format: int64, e.g. 0
  --size-results: int # format: int64, e.g. 0
  --size-site: int # format: int64, e.g. 0
  --source-id: string # e.g. 1
  --start-time: int # format: int64, e.g. 1576300370
  --stats: record
  --status: string # e.g. processed
  --template-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --type: string # e.g. scan
  --updated-at: int # format: int64, e.g. 1576300370
]: any -> record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/tasks/templates")
  let body = {acl: $acl, agent_id: $agent_id, client_id: $client_id, created_at: $created_at, created_by: $created_by, created_by_user_id: $created_by_user_id, cruncher_id: $cruncher_id, description: $description, error: $body_error, global: $global, grace_period: $grace_period, hidden: $hidden, hosted_zone_id: $hosted_zone_id, id: $id, linked_task_count: $linked_task_count, name: $name, organization_id: $organization_id, params: $params, parent_id: $parent_id, recur: $recur, recur_frequency: $recur_frequency, recur_last: $recur_last, recur_last_task_id: $recur_last_task_id, recur_next: $recur_next, site_id: $site_id, size_data: $size_data, size_results: $size_results, size_site: $size_site, source_id: $source_id, start_time: $start_time, stats: $stats, status: $status, template_id: $template_id, type: $type, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove scan template
#
# DELETE /account/tasks/templates/{scan_template_id}
# operationId: removeAccountScanTemplate
export def "account-tasks-templates removeAccountScanTemplate" [
  scan_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/tasks/templates/($scan_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get scan template details
#
# GET /account/tasks/templates/{scan_template_id}
# operationId: getAccountScanTemplate
export def "account-tasks-templates get" [
  scan_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acl: record, agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, global: bool, grace_period: string, hidden: bool, hosted_zone_id: string, id: string, linked_task_count: int, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, size_data: int, size_results: int, size_site: int, source_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/tasks/templates/($scan_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all users
#
# GET /account/users
# operationId: getAccountUsers
export def "account-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user account
#
# PUT /account/users
# operationId: createAccountUser
export def "account-users createAccountUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-admin: oneof<nothing, bool> # e.g. true
  --email: string # e.g. jsmith@example.com
  --first-name: string # e.g. James
  --last-name: string # e.g. Smith
  --org-default-role: string # e.g. admin
  --org-roles: record
]: any -> record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/users")
  let body = {client_admin: $client_admin, email: $email, first_name: $first_name, last_name: $last_name, org_default_role: $org_default_role, org_roles: $org_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new user account and send an email invite
#
# PUT /account/users/invite
# operationId: createAccountUserInvite
export def "account-users-invite createAccountUserInvite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-admin: oneof<nothing, bool> # e.g. true
  --email: string # e.g. jsmith@example.com
  --first-name: string # e.g. James
  --last-name: string # e.g. Smith
  --message: string # e.g. You have been invited to the Rumble Network Discovery platform
  --org-default-role: string # e.g. admin
  --org-roles: record
  --subject: string # e.g. Welcome to Rumble
]: any -> record<client_admin: bool, client_id: string, created_at: int, email: string, first_name: string, id: string, invite_token_expiration: int, last_login_at: int, last_login_ip: string, last_login_ua: string, last_name: string, login_failures: int, org_default_role: string, org_roles: record, reset_token_expiration: int, sso_only: bool, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/users/invite")
  let body = {client_admin: $client_admin, email: $email, first_name: $first_name, last_name: $last_name, message: $message, org_default_role: $org_default_role, org_roles: $org_roles, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove this user
#
# DELETE /account/users/{user_id}
# operationId: removeAccountUser
export def "account-users removeAccountUser" [
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
  let full_url = (build-url $base $"/account/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user details
#
# GET /account/users/{user_id}
# operationId: getAccountUser
export def "account-users get" [
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
  let full_url = (build-url $base $"/account/users/($user_id)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user's details
#
# PATCH /account/users/{user_id}
# operationId: updateAccountUser
export def "account-users updateAccountUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-admin: oneof<nothing, bool> # e.g. true
  --email: string # e.g. jsmith@example.com
  --first-name: string # e.g. James
  --last-name: string # e.g. Smith
  --org-default-role: string # e.g. admin
  --org-roles: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/users/($user_id)")
  let body = {client_admin: $client_admin, email: $email, first_name: $first_name, last_name: $last_name, org_default_role: $org_default_role, org_roles: $org_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resets the user's lockout status
#
# PATCH /account/users/{user_id}/resetLockout
# operationId: resetAccountUserLockout
export def "account-users-reset-lockout resetAccountUserLockout" [
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
  let full_url = (build-url $base $"/account/users/($user_id)/resetLockout")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resets the user's MFA tokens
#
# PATCH /account/users/{user_id}/resetMFA
# operationId: resetAccountUserMFA
export def "account-users-reset-mfa resetAccountUserMFA" [
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
  let full_url = (build-url $base $"/account/users/($user_id)/resetMFA")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends the user a password reset email
#
# PATCH /account/users/{user_id}/resetPassword
# operationId: resetAccountUserPassword
export def "account-users-reset-password resetAccountUserPassword" [
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
  let full_url = (build-url $base $"/account/users/($user_id)/resetPassword")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cisco serial number and model name export for Cisco Smart Net Total Care Service.
#
# GET /export/org/assets.cisco.csv
# operationId: exportAssetsCiscoCSV
export def "export-org-assetsciscocsv exportAssetsCiscoCSV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/assets.cisco.csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Asset inventory as CSV
#
# GET /export/org/assets.csv
# operationId: exportAssetsCSV
export def "export-org-assetscsv exportAssetsCSV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/assets.csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the asset inventory
#
# GET /export/org/assets.json
# operationId: exportAssetsJSON
export def "export-org-assetsjson exportAssetsJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/assets.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Asset inventory as JSON line-delimited
#
# GET /export/org/assets.jsonl
# operationId: exportAssetsJSONL
export def "export-org-assetsjsonl exportAssetsJSONL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/assets.jsonl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Asset inventory as Nmap-style XML
#
# GET /export/org/assets.nmap.xml
# operationId: exportAssetsNmapXML
export def "export-org-assetsnmapxml exportAssetsNmapXML" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/assets.nmap.xml" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export an asset inventory as CSV for ServiceNow integration
#
# GET /export/org/assets.servicenow.csv
# operationId: snowExportAssetsCSV
export def "export-org-assetsservicenowcsv snowExportAssetsCSV" [
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
  let full_url = (build-url $base "/export/org/assets.servicenow.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the asset inventory as JSON
#
# GET /export/org/assets.servicenow.json
# operationId: snowExportAssetsJSON
export def "export-org-assetsservicenowjson snowExportAssetsJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addresses_extra: string, addresses_scope: string, alive: bool, asset_id: string, comments: string, detected_by: string, domains: string, first_discovered: string, hw_product: string, hw_vendor: string, hw_version: string, ip_address: string, last_discovered: string, last_updated: string, lowest_rtt: int, lowest_ttl: int, mac_address: string, mac_manufacturer: string, mac_vendors: string, macs: string, name: string, newest_mac_age: string, organization: string, os_product: string, os_vendor: string, os_version: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, site: string, sys_class_name: string, tags: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/org/assets.servicenow.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the asset inventory in a sync-friendly manner using created_at as a checkpoint. Requires the Splunk entitlement.
#
# GET /export/org/assets/sync/created/assets.json
# operationId: splunkAssetSyncCreatedJSON
export def "export-org-assets-sync-created-assetsjson splunkAssetSyncCreatedJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
  --since: int # an optional unix timestamp to use as a checkpoint (format: int64, e.g. 1576300370)
]: nothing -> record<assets: table<addresses: list, addresses_extra: list, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list, macs: list, names: list, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list, service_ports_protocols: list, service_ports_tcp: list, service_ports_udp: list, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>, since: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/assets/sync/created/assets.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the asset inventory in a sync-friendly manner using updated_at as a checkpoint. Requires the Splunk entitlement.
#
# GET /export/org/assets/sync/updated/assets.json
# operationId: splunkAssetSyncUpdatedJSON
export def "export-org-assets-sync-updated-assetsjson splunkAssetSyncUpdatedJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
  --since: int # an optional unix timestamp to use as a checkpoint (format: int64, e.g. 1576300370)
]: nothing -> record<assets: table<addresses: list, addresses_extra: list, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list, macs: list, names: list, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list, service_ports_protocols: list, service_ports_tcp: list, service_ports_udp: list, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int>, since: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/assets/sync/updated/assets.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Service inventory as CSV
#
# GET /export/org/services.csv
# operationId: exportServicesCSV
export def "export-org-servicescsv exportServicesCSV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/services.csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Service inventory as JSON
#
# GET /export/org/services.json
# operationId: exportServicesJSON
export def "export-org-servicesjson exportServicesJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/services.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Service inventory as JSON line-delimited
#
# GET /export/org/services.jsonl
# operationId: exportServicesJSONL
export def "export-org-servicesjsonl exportServicesJSONL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/services.jsonl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export a service inventory as CSV for ServiceNow integration
#
# GET /export/org/services.servicenow.csv
# operationId: snowExportServicesCSV
export def "export-org-servicesservicenowcsv snowExportServicesCSV" [
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
  let full_url = (build-url $base "/export/org/services.servicenow.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Site list as CSV
#
# GET /export/org/sites.csv
# operationId: exportSitesCSV
export def "export-org-sitescsv exportSitesCSV" [
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
  let full_url = (build-url $base "/export/org/sites.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export all sites
#
# GET /export/org/sites.json
# operationId: exportSitesJSON
export def "export-org-sitesjson exportSitesJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/sites.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Site list as JSON line-delimited
#
# GET /export/org/sites.jsonl
# operationId: exportSitesJSONL
export def "export-org-sitesjsonl exportSitesJSONL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/sites.jsonl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wireless inventory as CSV
#
# GET /export/org/wireless.csv
# operationId: exportWirelessCSV
export def "export-org-wirelesscsv exportWirelessCSV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/wireless.csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wireless inventory as JSON
#
# GET /export/org/wireless.json
# operationId: exportWirelessJSON
export def "export-org-wirelessjson exportWirelessJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> table<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/wireless.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wireless inventory as JSON line-delimited
#
# GET /export/org/wireless.jsonl
# operationId: exportWirelessJSONL
export def "export-org-wirelessjsonl exportWirelessJSONL" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
  --qp-fields: string # an optional list of fields to export, comma-separated
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/export/org/wireless.jsonl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get organization details
#
# GET /org
# operationId: getOrganization
export def "org get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update organization details
#
# PATCH /org
# operationId: updateOrganization
export def "org updateOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. Wobbly Widgets, Inc.
  --expiration-assets-offline: string # format: number, e.g. 365
  --expiration-assets-stale: string # format: number, e.g. 365
  --expiration-scans: string # format: number, e.g. 365
  --export-token: string # e.g. ETXXXXXXXXXXXXXXXX
  --name: string # e.g. My Organization
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --project: string # format: boolean, e.g. false
]: any -> record<asset_count: int, client_id: string, created_at: int, deactivated_at: int, description: string, download_token: string, download_token_created_at: int, expiration_assets_offline: int, expiration_assets_stale: int, expiration_scans: int, export_token: string, export_token_counter: int, export_token_created_at: int, export_token_last_used_at: int, export_token_last_used_by: string, id: string, inactive: bool, name: string, parent_id: string, permanent: bool, project: bool, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org")
  let body = {description: $description, expiration_assets_offline: $expiration_assets_offline, expiration_assets_stale: $expiration_assets_stale, expiration_scans: $expiration_scans, export_token: $export_token, name: $name, parent_id: $parent_id, project: $project} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all agents
#
# GET /org/agents
# operationId: getAgents
export def "org-agents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/agents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove and uninstall an agent
#
# DELETE /org/agents/{agent_id}
# operationId: removeAgent
export def "org-agents removeAgent" [
  agent_id: string
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
  let full_url = (build-url $base $"/org/agents/($agent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details for a single agent
#
# GET /org/agents/{agent_id}
# operationId: getAgent
export def "org-agents get" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/agents/($agent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the site associated with agent
#
# PATCH /org/agents/{agent_id}
# operationId: updateAgentSite
export def "org-agents updateAgentSite" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  site_id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
]: any -> record<arch: string, client_id: string, connected: bool, created_at: int, deactivated_at: int, external_ip: string, host_id: string, hub_id: string, id: string, inactive: bool, internal_ip: string, last_checkin: int, name: string, organization_id: string, os: string, site_id: string, system_info: record, updated_at: int, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/agents/($agent_id)")
  let body = {site_id: $site_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Force an agent to update and restart
#
# POST /org/agents/{agent_id}/update
# operationId: upgradeAgent
export def "org-agents-update upgradeAgent" [
  agent_id: string
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
  let full_url = (build-url $base $"/org/agents/($agent_id)/update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all assets
#
# GET /org/assets
# operationId: getAssets
export def "org-assets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/org/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear all tags across multiple assets based on a search query
#
# POST /org/assets/bulk/clearTags
# operationId: clearBulkAssetTags
export def "org-assets-bulk-clear-tags clearBulkAssetTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  search: string # e.g. alive:true and os:windows
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/assets/bulk/clearTags")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update tags across multiple assets based on a search query
#
# PATCH /org/assets/bulk/tags
# operationId: updateBulkAssetTags
export def "org-assets-bulk-tags updateBulkAssetTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  search: string # e.g. alive:true and os:windows
  tags: string # e.g. ThisTag=Value -OldTag
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/assets/bulk/tags")
  let body = {search: $search, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Top asset hardware products as CSV
#
# GET /org/assets/top.hw.csv
# operationId: exportAssetTopHWCSV
export def "org-assets-tophwcsv exportAssetTopHWCSV" [
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
  let full_url = (build-url $base "/org/assets/top.hw.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top asset operating systems as CSV
#
# GET /org/assets/top.os.csv
# operationId: exportAssetTopOSCSV
export def "org-assets-toposcsv exportAssetTopOSCSV" [
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
  let full_url = (build-url $base "/org/assets/top.os.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top asset tags as CSV
#
# GET /org/assets/top.tags.csv
# operationId: exportAssetTopTagsCSV
export def "org-assets-toptagscsv exportAssetTopTagsCSV" [
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
  let full_url = (build-url $base "/org/assets/top.tags.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top asset types as CSV
#
# GET /org/assets/top.types.csv
# operationId: exportAssetTopTypesCSV
export def "org-assets-toptypescsv exportAssetTopTypesCSV" [
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
  let full_url = (build-url $base "/org/assets/top.types.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an asset
#
# DELETE /org/assets/{asset_id}
# operationId: removeAsset
export def "org-assets removeAsset" [
  asset_id: string
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
  let full_url = (build-url $base $"/org/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get asset details
#
# GET /org/assets/{asset_id}
# operationId: getAsset
export def "org-assets get" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/assets/($asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update asset comments
#
# PATCH /org/assets/{asset_id}/comments
# operationId: updateAssetComments
export def "org-assets-comments updateAssetComments" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  comments: string # e.g. Sales Laptop
]: any -> record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/assets/($asset_id)/comments")
  let body = {comments: $comments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update asset tags
#
# PATCH /org/assets/{asset_id}/tags
# operationId: updateAssetTags
export def "org-assets-tags updateAssetTags" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tags: string # e.g. ThisTag=Value -OldTag
]: any -> record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/assets/($asset_id)/tags")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove the current API key
#
# DELETE /org/key
# operationId: removeKey
export def "org-key removeKey" [
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
  let full_url = (build-url $base "/org/key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get API key details
#
# GET /org/key
# operationId: getKey
export def "org-key get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rotate the API key secret and return the updated key
#
# PATCH /org/key/rotate
# operationId: rotateKey
export def "org-key-rotate rotateKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client_id: string, comment: string, counter: int, created_at: int, created_by: string, id: string, inactive: bool, last_used_at: int, last_used_ip: string, last_used_ua: string, organization_id: string, token: string, type: string, usage_limit: int, usage_today: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/key/rotate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all services
#
# GET /org/services
# operationId: getServices
export def "org-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/org/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subnet utilization statistics as as CSV
#
# GET /org/services/subnet.stats.csv
# operationId: exportSubnetUtilizationStatsCSV
export def "org-services-subnetstatscsv exportSubnetUtilizationStatsCSV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mask: string # an optional subnet mask size (ex:24)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mask" $mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/org/services/subnet.stats.csv" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top service products as CSV
#
# GET /org/services/top.products.csv
# operationId: exportServicesTopProductsCSV
export def "org-services-topproductscsv exportServicesTopProductsCSV" [
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
  let full_url = (build-url $base "/org/services/top.products.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top service protocols as CSV
#
# GET /org/services/top.protocols.csv
# operationId: exportServicesTopProtocolsCSV
export def "org-services-topprotocolscsv exportServicesTopProtocolsCSV" [
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
  let full_url = (build-url $base "/org/services/top.protocols.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top TCP services as CSV
#
# GET /org/services/top.tcp.csv
# operationId: exportServicesTopTCPCSV
export def "org-services-toptcpcsv exportServicesTopTCPCSV" [
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
  let full_url = (build-url $base "/org/services/top.tcp.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top UDP services as CSV
#
# GET /org/services/top.udp.csv
# operationId: exportServicesTopUDPCSV
export def "org-services-topudpcsv exportServicesTopUDPCSV" [
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
  let full_url = (build-url $base "/org/services/top.udp.csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a service
#
# DELETE /org/services/{service_id}
# operationId: removeService
export def "org-services removeService" [
  service_id: string
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
  let full_url = (build-url $base $"/org/services/($service_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get service details
#
# GET /org/services/{service_id}
# operationId: getService
export def "org-services get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addresses: list<string>, addresses_extra: list<string>, agent_name: string, alive: bool, attributes: record, comments: string, created_at: int, credentials: record, detected_by: string, domains: list<string>, first_seen: int, hw: string, id: string, last_agent_id: string, last_seen: int, last_task_id: string, lowest_rtt: int, lowest_ttl: int, mac_vendors: list<string>, macs: list<string>, names: list<string>, newest_mac: string, newest_mac_age: int, newest_mac_vendor: string, org_name: string, organization_id: string, os: string, os_version: string, rtts: record, service_address: string, service_asset_id: string, service_count: int, service_count_arp: int, service_count_icmp: int, service_count_tcp: int, service_count_udp: int, service_created_at: int, service_data: record, service_id: string, service_link: string, service_port: string, service_ports_products: list<string>, service_ports_protocols: list<string>, service_ports_tcp: list<string>, service_ports_udp: list<string>, service_protocol: string, service_screenshot_link: string, service_summary: string, service_transport: string, service_updated_at: int, service_vhost: string, services: record, site_id: string, site_name: string, tags: record, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/services/($service_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sites
#
# GET /org/sites
# operationId: getSites
export def "org-sites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/sites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new site
#
# PUT /org/sites
# operationId: createSite
export def "org-sites createSite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. County Office
  --excludes: string # e.g. 192.168.10.1
  name: string # e.g. New Site
  --scope: string # e.g. 192.168.10.0/24
]: any -> record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/sites")
  let body = {description: $description, excludes: $excludes, name: $name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a site and associated assets
#
# DELETE /org/sites/{site_id}
# operationId: removeSite
export def "org-sites removeSite" [
  site_id: string
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
  let full_url = (build-url $base $"/org/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get site details
#
# GET /org/sites/{site_id}
# operationId: getSite
export def "org-sites get" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/sites/($site_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a site definition
#
# PATCH /org/sites/{site_id}
# operationId: updateSite
export def "org-sites updateSite" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. County Office
  --excludes: string # e.g. 192.168.10.1
  name: string # e.g. New Site
  --scope: string # e.g. 192.168.10.0/24
]: any -> record<created_at: int, description: string, excludes: string, id: string, name: string, permanent: bool, scope: string, subnets: record, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/sites/($site_id)")
  let body = {description: $description, excludes: $excludes, name: $name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Import a scan data file into a site
#
# PUT /org/sites/{site_id}/import
# operationId: importScanData
export def "org-sites-import importScanData" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/sites/($site_id)/import")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Import a Nessus scan data file into a site
#
# PUT /org/sites/{site_id}/import/nessus
# operationId: importNessusScanData
export def "org-sites-import-nessus importNessusScanData" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/sites/($site_id)/import/nessus")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Create a scan task for a given site
#
# PUT /org/sites/{site_id}/scan
# operationId: createScan
export def "org-sites-scan createScan" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/sites/($site_id)/scan")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/json" $body
}

# Get all tasks (last 1000)
#
# GET /org/tasks
# operationId: getTasks
export def "org-tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # an optional status string for filtering results
  --search: string # an optional search string for filtering results
]: nothing -> table<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/org/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task details
#
# GET /org/tasks/{task_id}
# operationId: getTask
export def "org-tasks get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update task parameters
#
# PATCH /org/tasks/{task_id}
# operationId: updateTask
export def "org-tasks updateTask" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --client-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --created-at: int # format: int64, e.g. 1576300370
  --created-by: string # format: email, e.g. user@example.com
  --created-by-user-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --cruncher-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --description: string # e.g. Scan the headquarters hourly
  --body-error: string # e.g. agent unavailable
  --hidden: oneof<nothing, bool> # e.g. false
  id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --name: string # e.g. Hourly Scan
  --organization-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --params: record
  --parent-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --recur: oneof<nothing, bool> # e.g. false
  --recur-frequency: string # e.g. hour
  --recur-last: int # format: int64, e.g. 1576300370
  --recur-last-task-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --recur-next: int # format: int64, e.g. 1576300370
  --site-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --start-time: int # format: int64, e.g. 1576300370
  --stats: record
  --status: string # e.g. processed
  --template-id: string # format: uuid, e.g. e77602e0-3fb8-4734-aef9-fbc6fdcb0fa8
  --type: string # e.g. scan
  --updated-at: int # format: int64, e.g. 1576300370
]: any -> record<agent_id: string, client_id: string, created_at: int, created_by: string, created_by_user_id: string, cruncher_id: string, description: string, error: string, hidden: bool, id: string, name: string, organization_id: string, params: record, parent_id: string, recur: bool, recur_frequency: string, recur_last: int, recur_last_task_id: string, recur_next: int, site_id: string, start_time: int, stats: record, status: string, template_id: string, type: string, updated_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/tasks/($task_id)")
  let body = {agent_id: $agent_id, client_id: $client_id, created_at: $created_at, created_by: $created_by, created_by_user_id: $created_by_user_id, cruncher_id: $cruncher_id, description: $description, error: $body_error, hidden: $hidden, id: $id, name: $name, organization_id: $organization_id, params: $params, parent_id: $parent_id, recur: $recur, recur_frequency: $recur_frequency, recur_last: $recur_last, recur_last_task_id: $recur_last_task_id, recur_next: $recur_next, site_id: $site_id, start_time: $start_time, stats: $stats, status: $status, template_id: $template_id, type: $type, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a temporary task change report data url
#
# GET /org/tasks/{task_id}/changes
# operationId: getTaskChangeReport
export def "org-tasks-changes get" [
  task_id: string
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
  let full_url = (build-url $base $"/org/tasks/($task_id)/changes")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a temporary task scan data url
#
# GET /org/tasks/{task_id}/data
# operationId: getTaskScanData
export def "org-tasks-data get" [
  task_id: string
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
  let full_url = (build-url $base $"/org/tasks/($task_id)/data")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Signal that a completed task should be hidden
#
# POST /org/tasks/{task_id}/hide
# operationId: hideTask
export def "org-tasks-hide hideTask" [
  task_id: string
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
  let full_url = (build-url $base $"/org/tasks/($task_id)/hide")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a temporary task log data url
#
# GET /org/tasks/{task_id}/log
# operationId: getTaskLog
export def "org-tasks-log get" [
  task_id: string
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
  let full_url = (build-url $base $"/org/tasks/($task_id)/log")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Signal that a task should be stopped or canceledThis will also remove recurring and scheduled tasks
#
# POST /org/tasks/{task_id}/stop
# operationId: stopTask
export def "org-tasks-stop stopTask" [
  task_id: string
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
  let full_url = (build-url $base $"/org/tasks/($task_id)/stop")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all wireless LANs
#
# GET /org/wireless
# operationId: getWirelessLANs
export def "org-wireless list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # an optional search string for filtering results
]: nothing -> table<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/org/wireless" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a wireless LAN
#
# DELETE /org/wireless/{wireless_id}
# operationId: removeWirelessLAN
export def "org-wireless removeWirelessLAN" [
  wireless_id: string
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
  let full_url = (build-url $base $"/org/wireless/($wireless_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get wireless LAN details
#
# GET /org/wireless/{wireless_id}
# operationId: getWirelessLAN
export def "org-wireless get" [
  wireless_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<agent_name: string, authentication: string, bssid: string, channels: string, created_at: int, data: record, encryption: string, essid: string, family: string, id: string, interface: string, last_agent_id: string, last_seen: int, last_task_id: string, org_name: string, organization_id: string, signal: int, site_id: string, site_name: string, type: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/wireless/($wireless_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns latest agent version
#
# GET /releases/agent/version
# operationId: getLatestAgentVersion
export def "releases-agent-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/releases/agent/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns latest platform version
#
# GET /releases/platform/version
# operationId: getLatestPlatformVersion
export def "releases-platform-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/releases/platform/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns latest scanner version
#
# GET /releases/scanner/version
# operationId: getLatestScannerVersion
export def "releases-scanner-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/releases/scanner/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
