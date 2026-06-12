# Auto-generated client for chroma-frontend v1.0.0
# Source: https://docs.trychroma.com/openapi.json
# Auth: --token flag or $env.CHROMA_FRONTEND_TOKEN

const BASE_URL = "https://api.trychroma.com"
const DEFAULT_AUTH = "x-chroma-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CHROMA_FRONTEND_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-chroma-token" => { {headers: {x-chroma-token: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.trychroma.com"] }
def auth-scheme-completer [] { ["x-chroma-token"] }

# Completers for enum parameters
def read-level-completer [] { ["index_and_wal" "index_only"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-identity identity" } } | get name | first)
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

# Get user identity
#
# GET /api/v2/auth/identity
# operationId: get_user_identity
export def "auth-identity identity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<databases: list<string>, tenant: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/auth/identity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get collection by CRN
#
# GET /api/v2/collections/{crn}
# operationId: get_collection_by_crn
export def "collections crn" [
  crn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<configuration_json: record<embedding_function: any, hnsw: any, spann: any>, database: string, dimension: int, id: string, log_position: int, metadata: any, name: string, schema: any, tenant: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/collections/($crn)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Healthcheck
#
# GET /api/v2/healthcheck
# operationId: healthcheck
export def "healthcheck healthcheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/healthcheck")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Heartbeat
#
# GET /api/v2/heartbeat
# operationId: heartbeat
export def "heartbeat heartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<nanosecond_heartbeat: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/heartbeat")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pre-flight checks
#
# GET /api/v2/pre-flight-checks
# operationId: pre_flight_checks
export def "pre-flight-checks checks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<max_batch_size: int, supports_base64_encoding: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/pre-flight-checks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset database
#
# POST /api/v2/reset
# operationId: reset
export def "reset reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/reset")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create tenant
#
# POST /api/v2/tenants
# operationId: create_tenant
export def "tenants tenant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/tenants")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get tenant
#
# GET /api/v2/tenants/{tenant_name}
# operationId: get_tenant
export def "tenants tenant-by-tenant_name" [
  tenant_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, resource_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update tenant
#
# PATCH /api/v2/tenants/{tenant_name}
# operationId: update_tenant
export def "tenants tenant-by-tenant_name-1" [
  tenant_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  resource_name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant_name)")
  let body = {resource_name: $resource_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List databases
#
# GET /api/v2/tenants/{tenant}/databases
# operationId: list_databases
export def "tenants-databases databases" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for pagination (format: int32, e.g. 10)
  --offset: int # Offset for pagination (format: int32, e.g. 0)
]: nothing -> table<configuration_json: record<embedding_function: any, hnsw: any, spann: any>, database: string, dimension: int, id: string, log_position: int, metadata: any, name: string, schema: any, tenant: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create database
#
# POST /api/v2/tenants/{tenant}/databases
# operationId: create_database
export def "tenants-databases database-by-tenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get database
#
# GET /api/v2/tenants/{tenant}/databases/{database}
# operationId: get_database
export def "tenants-databases database-by-tenant-database" [
  tenant: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, tenant: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete database
#
# DELETE /api/v2/tenants/{tenant}/databases/{database}
# operationId: delete_database
export def "tenants-databases database-by-tenant-database-1" [
  tenant: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List collections
#
# GET /api/v2/tenants/{tenant}/databases/{database}/collections
# operationId: list_collections
export def "tenants-databases-collections collections" [
  tenant: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for pagination (format: int32, e.g. 10)
  --offset: int # Offset for pagination (format: int32, e.g. 0)
]: nothing -> table<configuration_json: record<embedding_function: any, hnsw: any, spann: any>, database: string, dimension: int, id: string, log_position: int, metadata: any, name: string, schema: any, tenant: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create collection
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections
# operationId: create_collection
export def "tenants-databases-collections collection-by-tenant-database" [
  tenant: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration: any
  --get-or-create: oneof<nothing, bool>
  --metadata: any
  name: string
  --schema: any
]: any -> record<configuration_json: record<embedding_function: any, hnsw: any, spann: any>, database: string, dimension: int, id: string, log_position: int, metadata: any, name: string, schema: any, tenant: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections")
  let body = {configuration: $configuration, get_or_create: $get_or_create, metadata: $metadata, name: $name, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get collection
#
# GET /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}
# operationId: get_collection
export def "tenants-databases-collections collection-by-tenant-database-collection_id" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<configuration_json: record<embedding_function: any, hnsw: any, spann: any>, database: string, dimension: int, id: string, log_position: int, metadata: any, name: string, schema: any, tenant: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update collection
#
# PUT /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}
# operationId: update_collection
export def "tenants-databases-collections collection-by-tenant-database-collection_id-1" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-configuration: any
  --new-metadata: any
  --new-name: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)")
  let body = {new_configuration: $new_configuration, new_metadata: $new_metadata, new_name: $new_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete collection
#
# DELETE /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}
# operationId: delete_collection
export def "tenants-databases-collections collection-by-tenant-database-collection_id-2" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add records
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/add
# operationId: collection_add
export def "tenants-databases-collections-add add" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # nullable
  embeddings: any
  ids: list # Unique identifiers for each record.
  --metadatas: list # nullable
  --uris: list # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/add")
  let body = {documents: $documents, embeddings: $embeddings, ids: $ids, metadatas: $metadatas, uris: $uris} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Detach function
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/attached_functions/{name}/detach
# operationId: detach_function
export def "tenants-databases-collections-attached-functions-detach function" [
  tenant: string
  database: string
  collection_id: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-output: oneof<nothing, bool> # Whether to delete the output collection as well when detaching the function.
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/attached_functions/($name)/detach")
  let body = {delete_output: $delete_output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get number of records
#
# GET /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/count
# operationId: collection_count
export def "tenants-databases-collections-count count" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete records
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/delete
# operationId: collection_delete
export def "tenants-databases-collections-delete delete" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-where: any
  --where-document: any
  --ids: list # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/delete")
  let body = {where: $body_where, where_document: $where_document, ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fork collection
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/fork
# operationId: fork_collection
export def "tenants-databases-collections-fork collection" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_name: string
]: any -> record<configuration_json: record<embedding_function: any, hnsw: any, spann: any>, database: string, dimension: int, id: string, log_position: int, metadata: any, name: string, schema: any, tenant: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/fork")
  let body = {new_name: $new_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Attach function
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/functions/attach
# operationId: attach_function
export def "tenants-databases-collections-functions-attach function" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  function_id: string
  name: string
  output_collection: string
  --params: any
]: any -> record<attached_function: record<function_name: string, id: string, name: string>, created: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/functions/attach")
  let body = {function_id: $function_id, name: $name, output_collection: $output_collection, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get attached function
#
# GET /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/functions/{function_name}
# operationId: get_attached_function
export def "tenants-databases-collections-functions function" [
  tenant: string
  database: string
  collection_id: string
  function_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attached_function: record<completion_offset: int, database_id: string, function_name: string, id: string, input_collection_id: string, min_records_for_invocation: int, name: string, output_collection: string, output_collection_id: any, params: string, tenant_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/functions/($function_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get records
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/get
# operationId: collection_get
export def "tenants-databases-collections-get get" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-where: any
  --where-document: any
  --ids: list # nullable
  --include: list
  --limit: int # nullable, format: int32
  --offset: int # nullable, format: int32
]: any -> record<documents: list<string>, embeddings: list<list<float>>, ids: list<string>, include: list<string>, metadatas: list<any>, uris: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/get")
  let body = {where: $body_where, where_document: $where_document, ids: $ids, include: $include, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get indexing status
#
# GET /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/indexing_status
# operationId: indexing_status
export def "tenants-databases-collections-indexing-status status" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<num_indexed_ops: int, num_unindexed_ops: int, op_indexing_progress: float, total_ops: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/indexing_status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query collection
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/query
# operationId: collection_query
export def "tenants-databases-collections-query query" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit for pagination (format: int32, e.g. 10)
  --offset: int # Offset for pagination (format: int32, e.g. 0)
  --body-where: any
  --where-document: any
  --ids: list # nullable
  --include: list
  --n-results: int # nullable, format: int32
  query_embeddings: list
]: any -> record<distances: list<list<float>>, documents: list<list<string>>, embeddings: list<list<list>>, ids: list<list<string>>, include: list<string>, metadatas: list<list<any>>, uris: list<list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/query" $qp)
  let body = {where: $body_where, where_document: $where_document, ids: $ids, include: $include, n_results: $n_results, query_embeddings: $query_embeddings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search records
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/search
# operationId: collection_search
# --searches item shape: {filter?: record, group_by?: record, limit?: record, rank?: record, select?: record}
export def "tenants-databases-collections-search search" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --read-level: string@read-level-completer
  searches: list # item shape: {filter?: record, group_by?: record, limit?: record, rank?: record, select?: record}
]: any -> record<documents: list<list<string>>, embeddings: list<list<list>>, ids: list<list<string>>, metadatas: list<list<any>>, scores: list<list<float>>, select: list<list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/search")
  let body = {read_level: $read_level, searches: $searches} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update records
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/update
# operationId: collection_update
export def "tenants-databases-collections-update update" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # nullable
  --embeddings: any
  ids: list
  --metadatas: list # nullable
  --uris: list # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/update")
  let body = {documents: $documents, embeddings: $embeddings, ids: $ids, metadatas: $metadatas, uris: $uris} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upsert records
#
# POST /api/v2/tenants/{tenant}/databases/{database}/collections/{collection_id}/upsert
# operationId: collection_upsert
export def "tenants-databases-collections-upsert upsert" [
  tenant: string
  database: string
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # nullable
  embeddings: any
  ids: list
  --metadatas: list # nullable
  --uris: list # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections/($collection_id)/upsert")
  let body = {documents: $documents, embeddings: $embeddings, ids: $ids, metadatas: $metadatas, uris: $uris} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get number of collections
#
# GET /api/v2/tenants/{tenant}/databases/{database}/collections_count
# operationId: count_collections
export def "tenants-databases-collections-count collections" [
  tenant: string
  database: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/tenants/($tenant)/databases/($database)/collections_count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get version
#
# GET /api/v2/version
# operationId: version
export def "version version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-chroma-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/version")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
