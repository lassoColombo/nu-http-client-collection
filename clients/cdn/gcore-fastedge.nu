# Auto-generated client for Gcore OpenAPI – FastEdge API v6519d648325b
# Source: https://gcore.com/docs/api-reference/services_docs_mintlify/fastedge_api.yaml
# Auth: --token flag or $env.GCORE_OPENAPI_FASTEDGE_API_TOKEN

const BASE_URL = "https://api.gcore.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GCORE_OPENAPI_FASTEDGE_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://api.gcore.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-type-completer [] { ["proxy-wasm" "wasi-http"] }
def ordering-completer [] { ["-binary" "-id" "-name" "-plan" "-status" "-template" "binary" "id" "name" "plan" "status" "template"] }
def log-completer [] { ["kafka" "none"] }
def sort-completer [] { ["asc" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "fastedge-apps listApps" } } | get name | first)
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

# List client's apps
#
# GET /fastedge/v1/apps
# operationId: listApps
export def "fastedge-apps listApps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Filter by application name (case-insensitive partial match)
  --api-type: string@api-type-completer # API type:   wasi-http - WASI with HTTP entry point   proxy-wasm - Proxy-Wasm app, callable from CDN (e.g. wasi-http)
  --status: int # Status code:   0 - draft (inactive)   1 - enabled   2 - disabled   3 - hourly call limit exceeded   4 - daily call limit exceeded   5 - suspended (e.g. 1)
  --template: int # Filter by template ID (shows apps created from this template) (format: int64)
  --binary: int # Filter by binary ID (shows apps using this binary) (format: int64)
  --plan: int # Filter by plan ID (format: int64)
  --limit: int # Maximum number of results to return (e.g. 50)
  --offset: int # Number of results to skip for pagination (default: 0, e.g. 0)
  --ordering: string@ordering-completer # Sort order. Use - prefix for descending (e.g., -name sorts by name descending) (e.g. id)
]: nothing -> record<apps: table<id: int, name: string, url: string, status: int, binary: int, comment: string, api_type: string, debug_until: string, debug: bool, template: int, template_name: string, networks: list, upgradeable_to: int, plan_id: int, plan: string>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "api_type" $api_type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "template" $template "scalar") (serialize-qp "binary" $binary "scalar") (serialize-qp "plan" $plan "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fastedge/v1/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new app
#
# POST /fastedge/v1/apps
# operationId: addApp
@deprecated --flag log
export def "fastedge-apps addApp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Unique application name (alphanumeric, hyphens allowed) (e.g. my-edge-app)
  --binary: int # ID of the WebAssembly binary to deploy (format: int64, e.g. 12345)
  --template: int # Template ID (format: int64)
  --status: int # Status code:   0 - draft (inactive)   1 - enabled   2 - disabled   5 - suspended (e.g. 1)
  --env: record # Environment variables (e.g. {var1: value1, var2: value2})
  --rsp-headers: record # Extra headers to add to the response (e.g. {header1: value1, header2: value2})
  --log: string@log-completer # DEPRECATED, nullable
  --debug: string@bool-completer # Enable verbose debug logging for 30 minutes. Automatically expires to prevent performance impact. (default: false, e.g. false)
  --comment: string # Optional human-readable description of the application's purpose (e.g. Production API gateway for customer portal)
  --secrets: record # Application secrets
  --stores: record # Application edge stores
]: any -> record<id: int, name: string, url: string, status: int, binary: int, comment: string, api_type: string, debug_until: string, debug: bool, template: int, template_name: string, networks: list<string>, upgradeable_to: int, plan_id: int, plan: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fastedge/v1/apps")
  let body = {name: $name, binary: $binary, template: $template, status: $status, env: $env, rsp_headers: $rsp_headers, log: $log, debug: $debug, comment: $comment, secrets: $secrets, stores: $stores} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete app
#
# DELETE /fastedge/v1/apps/{app_id}
# operationId: delApp
export def "fastedge-apps delApp" [
  app_id: int
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
  let full_url = (build-url $base $"/fastedge/v1/apps/($app_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get app details
#
# GET /fastedge/v1/apps/{app_id}
# operationId: getApp
export def "fastedge-apps get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, url: string, binary: int, template: int, template_name: string, status: int, plan_id: int, plan: string, env: record, rsp_headers: record, log: string, debug: bool, debug_until: string, comment: string, api_type: string, networks: list<string>, secrets: record, stores: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/apps/($app_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update app
#
# PATCH /fastedge/v1/apps/{app_id}
# operationId: patchApp
@deprecated --flag log
export def "fastedge-apps patch" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Unique application name (alphanumeric, hyphens allowed) (e.g. my-edge-app)
  --binary: int # ID of the WebAssembly binary to deploy (format: int64, e.g. 12345)
  --template: int # Template ID (format: int64)
  --status: int # Status code:   0 - draft (inactive)   1 - enabled   2 - disabled   5 - suspended (e.g. 1)
  --env: record # Environment variables (e.g. {var1: value1, var2: value2})
  --rsp-headers: record # Extra headers to add to the response (e.g. {header1: value1, header2: value2})
  --log: string@log-completer # DEPRECATED, nullable
  --debug: string@bool-completer # Enable verbose debug logging for 30 minutes. Automatically expires to prevent performance impact. (default: false, e.g. false)
  --comment: string # Optional human-readable description of the application's purpose (e.g. Production API gateway for customer portal)
  --secrets: record # Application secrets
  --stores: record # Application edge stores
]: any -> record<id: int, name: string, url: string, status: int, binary: int, comment: string, api_type: string, debug_until: string, debug: bool, template: int, template_name: string, networks: list<string>, upgradeable_to: int, plan_id: int, plan: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/apps/($app_id)")
  let body = {name: $name, binary: $binary, template: $template, status: $status, env: $env, rsp_headers: $rsp_headers, log: $log, debug: $debug, comment: $comment, secrets: $secrets, stores: $stores} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an app
#
# PUT /fastedge/v1/apps/{app_id}
# operationId: updateApp
@deprecated --flag log
export def "fastedge-apps updateApp" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Unique application name (alphanumeric, hyphens allowed) (e.g. my-edge-app)
  binary: int # ID of the WebAssembly binary to deploy (format: int64, e.g. 12345)
  --template: int # Template ID (format: int64)
  status: int # Status code:   0 - draft (inactive)   1 - enabled   2 - disabled   5 - suspended (e.g. 1)
  --env: record # Environment variables (e.g. {var1: value1, var2: value2})
  --rsp-headers: record # Extra headers to add to the response (e.g. {header1: value1, header2: value2})
  --log: string@log-completer # DEPRECATED, nullable
  --debug: string@bool-completer # Enable verbose debug logging for 30 minutes. Automatically expires to prevent performance impact. (default: false, e.g. false)
  --comment: string # Optional human-readable description of the application's purpose (e.g. Production API gateway for customer portal)
  --secrets: record # Application secrets
  --stores: record # Application edge stores
]: any -> record<id: int, name: string, url: string, status: int, binary: int, comment: string, api_type: string, debug_until: string, debug: bool, template: int, template_name: string, networks: list<string>, upgradeable_to: int, plan_id: int, plan: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/apps/($app_id)")
  let body = {name: $name, binary: $binary, template: $template, status: $status, env: $env, rsp_headers: $rsp_headers, log: $log, debug: $debug, comment: $comment, secrets: $secrets, stores: $stores} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List application logs
#
# GET /fastedge/v1/apps/{app_id}/logs
# operationId: listLogs
export def "fastedge-apps-logs listLogs" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start of log retrieval period in RFC3339 format. Defaults to 1 hour ago if not specified. (format: date-time, e.g. 2023-12-31T23:59:59Z)
  --qp-to: string # Reporting period end time, RFC3339 format. Default current time in UTC. (format: date-time, e.g. 2026-01-31T23:59:59Z)
  --edge: string # Edge name (format: string)
  --search: string # Search string (format: string)
  --client-ip: string # Search by client IP address
  --request-id: string # Search by request ID
  --qp-sort: string@sort-completer # Sort order (default desc) (format: string)
  --limit: int # Limit for pagination (format: int32)
  --offset: int # Offset for pagination (format: int32)
]: nothing -> record<count: int, logs: table<id: string, app_name: string, timestamp: string, log: string, edge: string, client_ip: string, request_id: string>, offset: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "edge" $edge "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "client_ip" $client_ip "scalar") (serialize-qp "request_id" $request_id "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fastedge/v1/apps/($app_id)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get app id by app name
#
# GET /fastedge/v1/apps/by-name/{name}
# DEPRECATED
# operationId: getAppIdByName
@deprecated
export def "fastedge-apps-by-name get" [
  name: string
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
  let full_url = (build-url $base $"/fastedge/v1/apps/by-name/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List binaries
#
# GET /fastedge/v1/binaries
# operationId: listBinaries
export def "fastedge-binaries listBinaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<binaries: table<id: int, status: int, unref_since: string, api_type: string, checksum: string, source: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fastedge/v1/binaries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a binary
#
# DELETE /fastedge/v1/binaries/{binary_id}
# operationId: delBinary
export def "fastedge-binaries delBinary" [
  binary_id: int
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
  let full_url = (build-url $base $"/fastedge/v1/binaries/($binary_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get binary
#
# GET /fastedge/v1/binaries/{binary_id}
# operationId: getBinary
export def "fastedge-binaries get" [
  binary_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, status: int, source: int, unref_since: string, api_type: string, checksum: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/binaries/($binary_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Store compiled WASM binary
#
# POST /fastedge/v1/binaries/raw
# operationId: storeBinary
export def "fastedge-binaries-raw storeBinary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, status: int, unref_since: string, api_type: string, checksum: string, source: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fastedge/v1/binaries/raw")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# List available edge stores
#
# GET /fastedge/v1/kv
# operationId: listStores
export def "fastedge-kv listStores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-id: int # Filter stores by application ID. Returns only stores associated with this app. (format: int64)
  --limit: int # Maximum number of stores to return per page (default: 50, e.g. 50)
  --offset: int # Number of stores to skip for pagination (default: 0, e.g. 0)
]: nothing -> record<count: int, stores: table<id: int, name: string, comment: string, app_count: int, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fastedge/v1/kv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new edge store
#
# POST /fastedge/v1/kv
# operationId: addStore
# --byod shape: {url: string, prefix: string}
export def "fastedge-kv addStore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A name of the store
  --comment: string # A description of the store
  --byod: record # BYOD (Bring Your Own Data) settings — shape: {url: string, prefix: string}
]: any -> record<name: string, comment: string, app_count: int, byod: record<url: string, prefix: string>, size: int, revision: int, updated_at: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fastedge/v1/kv")
  let body = {name: $name, comment: $comment, byod: $byod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a store
#
# DELETE /fastedge/v1/kv/{store_id}
# operationId: delStore
export def "fastedge-kv delStore" [
  store_id: int
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
  let full_url = (build-url $base $"/fastedge/v1/kv/($store_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get edge store details
#
# GET /fastedge/v1/kv/{store_id}
# operationId: getStore
export def "fastedge-kv get" [
  store_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, comment: string, app_count: int, byod: record<url: string, prefix: string>, size: int, revision: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/kv/($store_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an edge store
#
# PUT /fastedge/v1/kv/{store_id}
# operationId: updateStore
# --byod shape: {url: string, prefix: string}
export def "fastedge-kv updateStore" [
  store_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A name of the store
  --comment: string # A description of the store
  --byod: record # BYOD (Bring Your Own Data) settings — shape: {url: string, prefix: string}
]: any -> record<name: string, comment: string, app_count: int, byod: record<url: string, prefix: string>, size: int, revision: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/kv/($store_id)")
  let body = {name: $name, comment: $comment, byod: $byod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get edge store data entries
#
# GET /fastedge/v1/kv/{store_id}/data
# operationId: getStoreData
export def "fastedge-kv-data list" [
  store_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data-type: list # Data type filter
  --search: string # Key prefix to search for
  --min-score: float # Minimum score for sorted set (format: double)
  --max-score: float # Maximum score for sorted set (format: double)
  --limit: int # Limit for pagination (default: 50)
  --offset: int # Offset for pagination (default: 0, e.g. 0)
]: nothing -> record<count: int, entries: table<key: string, datatype: string, payload: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data_type" $data_type "multi") (serialize-qp "search" $search "scalar") (serialize-qp "min_score" $min_score "scalar") (serialize-qp "max_score" $max_score "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fastedge/v1/kv/($store_id)/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify data in store
#
# PUT /fastedge/v1/kv/{store_id}/data
# operationId: modifyStoreData
export def "fastedge-kv-data modifyStoreData" [
  store_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string@bool-completer # Force data type change (default: false)
  --body: record
]: any -> record<del_count: int, revision: int, store_size: int, write_count: int, write_size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fastedge/v1/kv/($store_id)/data" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get edge store key value
#
# GET /fastedge/v1/kv/{store_id}/data/{key}
# operationId: getStoreDataKey
export def "fastedge-kv-data get" [
  store_id: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Value prefix to search for
  --hash: string # Value hash to search for
  --min-score: float # Minimum score for sorted set (format: double)
  --max-score: float # Maximum score for sorted set (format: double)
  --limit: int # Limit for pagination (default: 50, e.g. 50)
  --offset: int # Offset for pagination (default: 0, e.g. 0)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "hash" $hash "scalar") (serialize-qp "min_score" $min_score "scalar") (serialize-qp "max_score" $max_score "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fastedge/v1/kv/($store_id)/data/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get status and limits for the client
#
# GET /fastedge/v1/me
# operationId: getClientMe
export def "fastedge-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: int, hourly_consumption: int, daily_consumption: int, app_count: int, monthly_consumption: int, networks: table<name: string, is_default: bool>, plan_id: int, plan: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fastedge/v1/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available secrets
#
# GET /fastedge/v1/secrets
# operationId: listSecrets
export def "fastedge-secrets listSecrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-id: int # App ID (format: int64)
  --secret-name: string # Secret name
]: nothing -> record<count: int, secrets: table<id: int, name: string, comment: string, app_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar") (serialize-qp "secret_name" $secret_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fastedge/v1/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new secret
#
# POST /fastedge/v1/secrets
# operationId: addSecret
# --secret_slots item shape: {slot: int, value?: string}
export def "fastedge-secrets addSecret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The unique name of the secret.
  --comment: string # A description or comment about the secret.
  --secret-slots: list # A list of secret slots associated with this secret. — item shape: {slot: int, value?: string}
]: any -> record<name: string, comment: string, app_count: int, secret_slots: table<slot: int, value: string, checksum: string>, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fastedge/v1/secrets")
  let body = {name: $name, comment: $comment, secret_slots: $secret_slots} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a secret
#
# DELETE /fastedge/v1/secrets/{secret_id}
# operationId: deleteSecret
export def "fastedge-secrets delete" [
  secret_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string@bool-completer # When true, deletes secret even if used by applications. Defaults to false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fastedge/v1/secrets/($secret_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get secret details
#
# GET /fastedge/v1/secrets/{secret_id}
# operationId: getSecret
export def "fastedge-secrets get" [
  secret_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, comment: string, app_count: int, secret_slots: table<slot: int, value: string, checksum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/secrets/($secret_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a secret
#
# PATCH /fastedge/v1/secrets/{secret_id}
# operationId: patchSecret
# --secret_slots item shape: {slot: int, value?: string}
export def "fastedge-secrets patch" [
  secret_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The unique name of the secret.
  --comment: string # A description or comment about the secret.
  --secret-slots: list # A list of secret slots associated with this secret. — item shape: {slot: int, value?: string}
]: any -> record<name: string, comment: string, app_count: int, secret_slots: table<slot: int, value: string, checksum: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/secrets/($secret_id)")
  let body = {name: $name, comment: $comment, secret_slots: $secret_slots} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a secret
#
# PUT /fastedge/v1/secrets/{secret_id}
# operationId: updateSecret
# --secret_slots item shape: {slot: int, value?: string}
export def "fastedge-secrets updateSecret" [
  secret_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The unique name of the secret.
  --comment: string # A description or comment about the secret.
  --secret-slots: list # A list of secret slots associated with this secret. — item shape: {slot: int, value?: string}
]: any -> record<name: string, comment: string, app_count: int, secret_slots: table<slot: int, value: string, checksum: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/secrets/($secret_id)")
  let body = {name: $name, comment: $comment, secret_slots: $secret_slots} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Execution duration statistics
#
# GET /fastedge/v1/stats/app_duration
# operationId: StatsDuration
export def "fastedge-stats-app-duration StatsDuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # Filter statistics by specific application ID (format: int64)
  --qp-from: string # Reporting period start time in RFC3339 format (format: date-time, e.g. 2026-01-01T00:00:00Z)
  --qp-to: string # Reporting period end time in RFC3339 format (exclusive) (format: date-time, e.g. 2026-01-31T23:59:59Z)
  --step: int # Reporting time granularity in seconds. Common values are 60 (1 minute), 300 (5 minutes), 3600 (1 hour). (default: 60, e.g. 300)
  --network: string # Filter statistics by edge network name (format: string, e.g. gcore)
]: nothing -> record<stats: table<time: string, min: int, max: int, avg: int, median: int, perc75: int, perc90: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "step" $step "scalar") (serialize-qp "network" $network "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fastedge/v1/stats/app_duration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Call statistics
#
# GET /fastedge/v1/stats/calls
# operationId: StatsCalls
export def "fastedge-stats-calls StatsCalls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Reporting period start time in RFC3339 format (format: date-time, e.g. 2026-01-01T00:00:00Z)
  --qp-to: string # Reporting period end time in RFC3339 format (exclusive) (format: date-time, e.g. 2026-01-31T23:59:59Z)
  --step: int # Reporting time granularity in seconds. Common values are 60 (1 minute), 300 (5 minutes), 3600 (1 hour). (default: 60, e.g. 300)
  --id: int # Filter statistics by specific application ID (format: int64)
  --network: string # Filter statistics by edge network name (format: string, e.g. gcore)
]: nothing -> record<stats: table<time: string, count_by_status: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "step" $step "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "network" $network "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fastedge/v1/stats/calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edge storage statistics
#
# GET /fastedge/v1/stats/kv_store
# operationId: StatsKVStore
export def "fastedge-stats-kv-store StatsKVStore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Reporting period start time in RFC3339 format (format: date-time, e.g. 2026-01-01T00:00:00Z)
  --qp-to: string # Reporting period end time in RFC3339 format (exclusive) (format: date-time, e.g. 2026-01-31T23:59:59Z)
]: nothing -> record<stats: table<time: string, read_count: int, write_size: int, storage_size: float, del_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fastedge/v1/stats/kv_store" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List app templates
#
# GET /fastedge/v1/template
# operationId: listTemplates
export def "fastedge-template listTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-type: string@api-type-completer # API type:   wasi-http - WASI with HTTP entry point   proxy-wasm - Proxy-Wasm app, callable from CDN (e.g. wasi-http)
  --only-mine: string@bool-completer # When true, returns only templates created by the client. When false, includes shared templates. (default: false, e.g. false)
  --limit: int # Maximum number of results to return (default: 50, e.g. 50)
  --offset: int # Number of results to skip for pagination (default: 0, e.g. 0)
]: nothing -> record<count: int, templates: table<id: int, name: string, short_descr: string, long_descr: string, api_type: string, owned: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_type" $api_type "scalar") (serialize-qp "only_mine" $only_mine "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fastedge/v1/template" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add template
#
# POST /fastedge/v1/template
# operationId: addTemplate
# --params item shape: {name: string, data_type: "string"|"number"|"date"|"time"|"secret"|"store"|"bool"|"json"|"enum", mandatory: bool, descr?: string, metadata?: string}
export def "fastedge-template addTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  binary_id: int # ID of the WebAssembly binary to use for this template (format: int64, e.g. 12345)
  name: string # Unique name for the template (used for identification and searching) (e.g. api-gateway-template)
  --short-descr: string # Brief one-line description displayed in template listings (e.g. HTTP API gateway with authentication)
  --long-descr: string # Detailed markdown description explaining template features and usage (e.g. Complete API gateway solution with JWT authentication, rate limiting, and request transformation capabilities.)
  --owned: string@bool-completer # Is the template owned by user?
  params: list # Parameters — item shape: {name: string, data_type: "string"|"number"|"date"|"time"|"secret"|"store"|"bool"|"json"|"enum", mandatory: bool, descr?: string, metadata?: string}
]: any -> record<id: int, name: string, short_descr: string, long_descr: string, api_type: string, owned: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fastedge/v1/template")
  let body = {binary_id: $binary_id, name: $name, short_descr: $short_descr, long_descr: $long_descr, owned: $owned, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete template
#
# DELETE /fastedge/v1/template/{template_id}
# operationId: delTemplate
export def "fastedge-template delTemplate" [
  template_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string@bool-completer # When true, deletes template even if shared with groups. Defaults to false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fastedge/v1/template/($template_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get template details
#
# GET /fastedge/v1/template/{template_id}
# operationId: getTemplate
export def "fastedge-template get" [
  template_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<binary_id: int, name: string, short_descr: string, long_descr: string, api_type: string, owned: bool, params: table<name: string, data_type: string, mandatory: bool, descr: string, metadata: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/template/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template
#
# PUT /fastedge/v1/template/{template_id}
# operationId: updateTemplate
# --params item shape: {name: string, data_type: "string"|"number"|"date"|"time"|"secret"|"store"|"bool"|"json"|"enum", mandatory: bool, descr?: string, metadata?: string}
export def "fastedge-template updateTemplate" [
  template_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  binary_id: int # ID of the WebAssembly binary to use for this template (format: int64, e.g. 12345)
  name: string # Unique name for the template (used for identification and searching) (e.g. api-gateway-template)
  --short-descr: string # Brief one-line description displayed in template listings (e.g. HTTP API gateway with authentication)
  --long-descr: string # Detailed markdown description explaining template features and usage (e.g. Complete API gateway solution with JWT authentication, rate limiting, and request transformation capabilities.)
  --owned: string@bool-completer # Is the template owned by user?
  params: list # Parameters — item shape: {name: string, data_type: "string"|"number"|"date"|"time"|"secret"|"store"|"bool"|"json"|"enum", mandatory: bool, descr?: string, metadata?: string}
]: any -> record<id: int, name: string, short_descr: string, long_descr: string, api_type: string, owned: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fastedge/v1/template/($template_id)")
  let body = {binary_id: $binary_id, name: $name, short_descr: $short_descr, long_descr: $long_descr, owned: $owned, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
