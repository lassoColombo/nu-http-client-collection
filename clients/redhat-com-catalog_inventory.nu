# Auto-generated client for Catalog Inventory v1.0.0
# Source: https://api.apis.guru/v2/specs/redhat.com/catalog_inventory/1.0.0/openapi.json
# Auth: --token flag or $env.CATALOG_INVENTORY_TOKEN

const BASE_URL = "https://cloud.redhat.com//api/catalog-inventory/v1.0"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CATALOG_INVENTORY_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://cloud.redhat.com//api/catalog-inventory/v1.0" "http://localhost:3000//api/catalog-inventory/v1.0"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def state-completer [] { ["completed" "pending" "queued" "running" "timedout"] }
def status-completer [] { ["error" "ok" "unchanged" "warn"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "graphql create" } } | get name | first)
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

# Perform a GraphQL Query
#
# POST /graphql
# operationId: postGraphQL
export def "graphql create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation-name: string # If the Query contains several named operations, the operationName controls which one should be executed (default: )
  query: string # The GraphQL query (default: {})
  --variables: record # Optional Query variables (nullable)
]: any -> record<data: record, errors: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/graphql")
  let body = {"operationName": $operation_name, "query": $query, "variables": $variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return this API document in JSON format
#
# GET /openapi.json
# operationId: getDocumentation
export def "openapijson get-documentation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openapi.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceCredentialTypes
#
# GET /service_credential_types
# operationId: listServiceCredentialTypes
export def "service-credential-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, description: string, id: string, kind: string, last_seen_at: string, name: string, namespace: string, refresh_state_part_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/service_credential_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing ServiceCredentialType
#
# GET /service_credential_types/{id}
# operationId: showServiceCredentialType
export def "service-credential-types showServiceCredentialType" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, created_at: string, description: string, id: string, kind: string, last_seen_at: string, name: string, namespace: string, refresh_state_part_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_credential_types/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceCredentials
#
# GET /service_credentials
# operationId: listServiceCredentials
export def "service-credentials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, description: string, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, service_credential_type_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, type_name: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/service_credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing ServiceCredential
#
# GET /service_credentials/{id}
# operationId: showServiceCredential
export def "service-credentials showServiceCredential" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, created_at: string, description: string, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, service_credential_type_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, type_name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_credentials/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceInstances
#
# GET /service_instances
# operationId: listServiceInstances
export def "service-instances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, external_url: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, root_service_instance_id: string, service_inventory_id: string, service_offering_id: string, service_plan_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/service_instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing ServiceInstance
#
# GET /service_instances/{id}
# operationId: showServiceInstance
export def "service-instances showServiceInstance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, created_at: string, external_url: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, root_service_instance_id: string, service_inventory_id: string, service_offering_id: string, service_plan_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_instances/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceInventories
#
# GET /service_inventories
# operationId: listServiceInventories
export def "service-inventories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, description: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/service_inventories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing ServiceInventory
#
# GET /service_inventories/{id}
# operationId: showServiceInventory
export def "service-inventories showServiceInventory" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, created_at: string, description: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_inventories/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tag a ServiceInventory
#
# POST /service_inventories/{id}/tag
# operationId: tagServiceInventory
export def "service-inventories-tag tag-service-inventory" [
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
]: any -> table<tag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_inventories/{id}/tag"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Tags for ServiceInventory
#
# GET /service_inventories/{id}/tags
# operationId: listServiceInventoryTags
export def "service-inventories-tags list-service-inventory" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<tag: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/service_inventories/{id}/tags") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Untag a ServiceInventory
#
# POST /service_inventories/{id}/untag
# operationId: untagServiceInventory
export def "service-inventories-untag untag-service-inventory" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_inventories/{id}/untag"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List ServiceOfferingNodes
#
# GET /service_offering_nodes
# operationId: listServiceOfferingNodes
export def "service-offering-nodes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, root_service_offering_id: string, service_inventory_id: string, service_offering_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/service_offering_nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing ServiceOfferingNode
#
# GET /service_offering_nodes/{id}
# operationId: showServiceOfferingNode
export def "service-offering-nodes showServiceOfferingNode" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, created_at: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, root_service_offering_id: string, service_inventory_id: string, service_offering_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_offering_nodes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceOfferings
#
# GET /service_offerings
# operationId: listServiceOfferings
export def "service-offerings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, description: string, display_name: string, distributor: string, documentation_url: string, extra: record, id: string, last_seen_at: string, long_description: string, name: string, refresh_state_part_id: string, service_inventory_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, support_url: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/service_offerings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing ServiceOffering
#
# GET /service_offerings/{id}
# operationId: showServiceOffering
export def "service-offerings showServiceOffering" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, created_at: string, description: string, display_name: string, distributor: string, documentation_url: string, extra: record, id: string, last_seen_at: string, long_description: string, name: string, refresh_state_part_id: string, service_inventory_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, support_url: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_offerings/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invokes computing of ServiceInventories tags for given ServiceOffering
#
# POST /service_offerings/{id}/applied_inventories_tags
# operationId: appliedInventoriesTagsForServiceOffering
export def "service-offerings-applied-inventories-tags appliedInventoriesTagsForServiceOffering" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-parameters: record # The provider specific parameters needed to compute list of used service inventories
]: any -> table<tag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_offerings/{id}/applied_inventories_tags"))
  let body = {"service_parameters": $service_parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order an existing ServiceOffering
#
# POST /service_offerings/{id}/order
# operationId: orderServiceOffering
export def "service-offerings-order orderServiceOffering" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-control-parameters: record # The provider specific parameters needed to provision this service. This might include namespaces, special keys
  --service-parameters: record # JSON object with provisioning parameters
]: any -> record<task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_offerings/{id}/order"))
  let body = {"provider_control_parameters": $provider_control_parameters, "service_parameters": $service_parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List ServiceInstances for ServiceOffering
#
# GET /service_offerings/{id}/service_instances
# operationId: listServiceOfferingServiceInstances
export def "service-offerings-service-instances list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, external_url: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, root_service_instance_id: string, service_inventory_id: string, service_offering_id: string, service_plan_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/service_offerings/{id}/service_instances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceOfferingNodes for ServiceOffering
#
# GET /service_offerings/{id}/service_offering_nodes
# operationId: listServiceOfferingServiceOfferingNodes
export def "service-offerings-service-offering-nodes list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, root_service_offering_id: string, service_inventory_id: string, service_offering_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/service_offerings/{id}/service_offering_nodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServicePlans for ServiceOffering
#
# GET /service_offerings/{id}/service_plans
# operationId: listServiceOfferingServicePlans
export def "service-offerings-service-plans list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, create_json_schema: record, created_at: string, description: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, resource_version: string, service_offering_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, update_json_schema: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/service_offerings/{id}/service_plans") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServicePlans
#
# GET /service_plans
# operationId: listServicePlans
export def "service-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, create_json_schema: record, created_at: string, description: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, resource_version: string, service_offering_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, update_json_schema: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/service_plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing ServicePlan
#
# GET /service_plans/{id}
# operationId: showServicePlan
export def "service-plans showServicePlan" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, create_json_schema: record, created_at: string, description: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, resource_version: string, service_offering_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, update_json_schema: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/service_plans/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Sources
#
# GET /sources
# operationId: listSources
export def "sources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, availability_message: string, availability_status: string, cloud_connector_id: string, created_at: string, enabled: bool, id: string, info: record, last_available_at: string, last_checked_at: string, last_refresh_message: string, last_successful_refresh_at: string, name: string, previous_sha: string, previous_size: int, refresh_finished_at: string, refresh_started_at: string, refresh_state: string, refresh_task_id: string, uid: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing Source
#
# GET /sources/{id}
# operationId: showSource
export def "sources showSource" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, availability_message: string, availability_status: string, cloud_connector_id: string, created_at: string, enabled: bool, id: string, info: record, last_available_at: string, last_checked_at: string, last_refresh_message: string, last_successful_refresh_at: string, name: string, previous_sha: string, previous_size: int, refresh_finished_at: string, refresh_started_at: string, refresh_state: string, refresh_task_id: string, uid: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Incremental Refresh an existing Source
#
# PATCH /sources/{id}/incremental_refresh
# operationId: incrementalRefreshSource
export def "sources-incremental-refresh incrementalRefreshSource" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}/incremental_refresh"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Refresh an existing Source
#
# PATCH /sources/{id}/refresh
# operationId: refreshSource
export def "sources-refresh refresh" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}/refresh"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceInstances for Source
#
# GET /sources/{id}/service_instances
# operationId: listSourceServiceInstances
export def "sources-service-instances list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, external_url: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, root_service_instance_id: string, service_inventory_id: string, service_offering_id: string, service_plan_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}/service_instances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceInventories for Source
#
# GET /sources/{id}/service_inventories
# operationId: listSourceServiceInventories
export def "sources-service-inventories list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, description: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}/service_inventories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceOfferingNodes for Source
#
# GET /sources/{id}/service_offering_nodes
# operationId: listSourceServiceOfferingNodes
export def "sources-service-offering-nodes list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, root_service_offering_id: string, service_inventory_id: string, service_offering_id: string, source_created_at: string, source_id: string, source_ref: string, source_updated_at: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}/service_offering_nodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServiceOfferings for Source
#
# GET /sources/{id}/service_offerings
# operationId: listSourceServiceOfferings
export def "sources-service-offerings list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, created_at: string, description: string, display_name: string, distributor: string, documentation_url: string, extra: record, id: string, last_seen_at: string, long_description: string, name: string, refresh_state_part_id: string, service_inventory_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, support_url: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}/service_offerings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ServicePlans for Source
#
# GET /sources/{id}/service_plans
# operationId: listSourceServicePlans
export def "sources-service-plans list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, create_json_schema: record, created_at: string, description: string, extra: record, id: string, last_seen_at: string, name: string, refresh_state_part_id: string, resource_version: string, service_offering_id: string, source_created_at: string, source_deleted_at: string, source_id: string, source_ref: string, update_json_schema: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}/service_plans") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Tasks for Source
#
# GET /sources/{id}/tasks
# operationId: listSourceTasks
export def "sources-tasks list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, child_task_id: string, completed_at: string, controller_message_id: string, created_at: string, id: string, input: record, message: string, name: string, output: record, owner: string, source_id: string, state: string, status: string, target_source_ref: string, target_type: string, type: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/sources/{id}/tasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Tags
#
# GET /tags
# operationId: listTags
export def "tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<tag: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Tasks
#
# GET /tasks
# operationId: listTasks
export def "tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return per page. (default: 100)
  --offset: int # The number of items to skip before starting to collect the result set. (default: 0)
  --filter: record # Filter for querying collections.
  --sort-by: record # The list of attribute and order to sort the result set by.
]: nothing -> record<data: table<archived_at: string, child_task_id: string, completed_at: string, controller_message_id: string, created_at: string, id: string, input: record, message: string, name: string, output: record, owner: string, source_id: string, state: string, status: string, target_source_ref: string, target_type: string, type: string, updated_at: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<count: int, limit: int, offset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort_by" $sort_by "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show an existing Task
#
# GET /tasks/{id}
# operationId: showTask
export def "tasks showTask" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived_at: string, child_task_id: string, completed_at: string, controller_message_id: string, created_at: string, id: string, input: record, message: string, name: string, output: record, owner: string, source_id: string, state: string, status: string, target_source_ref: string, target_type: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/tasks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing Task
#
# PATCH /tasks/{id}
# operationId: updateTask
export def "tasks update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --completed-at: string # format: date-time
  --message: string # e.g. received message starting inventory collection
  --name: string # e.g. Order Service Plan
  --output: record # e.g. Result of Task Execution
  --state: string@state-completer # e.g. running
  --status: string@status-completer # e.g. error
  --target-source-ref: string
  --target-type: string
  --type: string # e.g. CloudConnectorTask
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/tasks/{id}"))
  let body = {"completed_at": $completed_at, "message": $message, "name": $name, "output": $output, "state": $state, "status": $status, "target_source_ref": $target_source_ref, "target_type": $target_type, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
