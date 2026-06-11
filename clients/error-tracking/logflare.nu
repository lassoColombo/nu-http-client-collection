# Auto-generated client for logflare v1.43.4
# Source: https://logflare.app/api/openapi
# Auth: --token flag or $env.LOGFLARE_API_KEY

const BASE_URL = "https://api.logflare.app"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LOGFLARE_API_KEY | default "" }
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
def base-url-completer [] { ["https://api.logflare.app" "https://logflare.app"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-tokens LogflareWebApiAccessTokenControllerindex" } } | get name | first)
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

# List access tokens
#
# GET /api/access-tokens
# operationId: LogflareWeb.Api.AccessTokenController.index
export def "access-tokens LogflareWebApiAccessTokenControllerindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<description: string, id: int, inserted_at: string, scopes: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/access-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create access token
#
# POST /api/access-tokens
# operationId: LogflareWeb.Api.AccessTokenController.create
export def "access-tokens LogflareWebApiAccessTokenControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --id: int
  --inserted-at: string # format: date-time
  --scopes: string
  --body-token: string
]: any -> record<description: string, id: int, inserted_at: string, scopes: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/access-tokens")
  let body = {description: $description, id: $id, inserted_at: $inserted_at, scopes: $scopes, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete access token
#
# DELETE /api/access-tokens/{token}
# operationId: LogflareWeb.Api.AccessTokenController.delete
export def "access-tokens LogflareWebApiAccessTokenControllerdelete" [
  token: string
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
  let full_url = (build-url $base $"/api/access-tokens/($token)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List backends. Default managed backends are not included.
#
# GET /api/backends
# operationId: LogflareWeb.Api.BackendController.index
export def "backends LogflareWebApiBackendControllerindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<config: record, default_ingest_: bool, id: int, inserted_at: string, metadata: record, name: string, token: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/backends")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create backend
#
# POST /api/backends
# operationId: LogflareWeb.Api.BackendController.create
export def "backends LogflareWebApiBackendControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record
  --default-ingest?: string@bool-completer
  --id: int
  --inserted-at: string # format: date-time
  --metadata: record
  name: string
  --body-token: string
  --updated-at: string # format: date-time
]: any -> record<config: record, default_ingest_: bool, id: int, inserted_at: string, metadata: record, name: string, token: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/backends")
  let body = {config: $config, default_ingest?: $default_ingest?, id: $id, inserted_at: $inserted_at, metadata: $metadata, name: $name, token: $body_token, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete backend
#
# DELETE /api/backends/{token}
# operationId: LogflareWeb.Api.BackendController.delete
export def "backends LogflareWebApiBackendControllerdelete" [
  token: string
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
  let full_url = (build-url $base $"/api/backends/($token)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch backend
#
# GET /api/backends/{token}
# operationId: LogflareWeb.Api.BackendController.show
export def "backends LogflareWebApiBackendControllershow" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<config: record, default_ingest_: bool, id: int, inserted_at: string, metadata: record, name: string, token: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/backends/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update backend
#
# PATCH /api/backends/{token}
# operationId: LogflareWeb.Api.BackendController.update (2)
export def "backends LogflareWebApiBackendControllerupdate-2" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --config: record
  --default-ingest?: string@bool-completer
  --id: int
  --inserted-at: string # format: date-time
  --metadata: record
  name: string
  --body-token: string
  --updated-at: string # format: date-time
]: any -> record<config: record, default_ingest_: bool, id: int, inserted_at: string, metadata: record, name: string, token: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/backends/($token)")
  let body = {config: $config, default_ingest?: $default_ingest?, id: $id, inserted_at: $inserted_at, metadata: $metadata, name: $name, token: $body_token, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update backend
#
# PUT /api/backends/{token}
# operationId: LogflareWeb.Api.BackendController.update
export def "backends LogflareWebApiBackendControllerupdate" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --config: record
  --default-ingest?: string@bool-completer
  --id: int
  --inserted-at: string # format: date-time
  --metadata: record
  name: string
  --body-token: string
  --updated-at: string # format: date-time
]: any -> record<config: record, default_ingest_: bool, id: int, inserted_at: string, metadata: record, name: string, token: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/backends/($token)")
  let body = {config: $config, default_ingest?: $default_ingest?, id: $id, inserted_at: $inserted_at, metadata: $metadata, name: $name, token: $body_token, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test backend connection
#
# POST /api/backends/{token}/test
# operationId: LogflareWeb.Api.BackendController.test_connection
export def "backends-test connection" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connected_: bool, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/backends/($token)/test")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List endpoints
#
# GET /api/endpoints
# operationId: LogflareWeb.Api.EndpointController.index
export def "endpoints LogflareWebApiEndpointControllerindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<cache_duration_seconds: int, description: string, enable_auth: bool, id: int, max_limit: int, name: string, proactive_requerying_seconds: int, query: string, sandboxable: bool, source_mapping: record, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create endpoint
#
# POST /api/endpoints
# operationId: LogflareWeb.Api.EndpointController.create
export def "endpoints LogflareWebApiEndpointControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cache-duration-seconds: int
  --description: string # nullable
  --enable-auth: string@bool-completer
  --id: int
  --max-limit: int
  name: string
  --proactive-requerying-seconds: int
  --body-query: string
  --sandboxable: string@bool-completer # nullable
  --source-mapping: record # nullable
  --body-token: string
]: any -> record<cache_duration_seconds: int, description: string, enable_auth: bool, id: int, max_limit: int, name: string, proactive_requerying_seconds: int, query: string, sandboxable: bool, source_mapping: record, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/endpoints")
  let body = {cache_duration_seconds: $cache_duration_seconds, description: $description, enable_auth: $enable_auth, id: $id, max_limit: $max_limit, name: $name, proactive_requerying_seconds: $proactive_requerying_seconds, query: $body_query, sandboxable: $sandboxable, source_mapping: $source_mapping, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query a Logflare Endpoint
#
# GET /api/endpoints/query/name/{name}
# operationId: LogflareWeb.EndpointsController.query
export def "endpoints-query-name LogflareWebEndpointsControllerquery" [
  token_or_name: string
  name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: any, result: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoints/query/name/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query a Logflare Endpoint
#
# GET /api/endpoints/query/{token_or_name}
# operationId: LogflareWeb.EndpointsController.query (2)
export def "endpoints-query LogflareWebEndpointsControllerquery-2" [
  token_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: any, result: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoints/query/($token_or_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query a Logflare Endpoint
#
# POST /api/endpoints/query/{token_or_name}
# operationId: LogflareWeb.EndpointsController.query (3)
export def "endpoints-query LogflareWebEndpointsControllerquery-3" [
  token_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: any, result: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoints/query/($token_or_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete endpoint
#
# DELETE /api/endpoints/{token}
# operationId: LogflareWeb.Api.EndpointController.delete
export def "endpoints LogflareWebApiEndpointControllerdelete" [
  token: string
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
  let full_url = (build-url $base $"/api/endpoints/($token)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch endpoint
#
# GET /api/endpoints/{token}
# operationId: LogflareWeb.Api.EndpointController.show
export def "endpoints LogflareWebApiEndpointControllershow" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cache_duration_seconds: int, description: string, enable_auth: bool, id: int, max_limit: int, name: string, proactive_requerying_seconds: int, query: string, sandboxable: bool, source_mapping: record, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoints/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update endpoint
#
# PATCH /api/endpoints/{token}
# operationId: LogflareWeb.Api.EndpointController.update (2)
export def "endpoints LogflareWebApiEndpointControllerupdate-2" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --cache-duration-seconds: int
  --description: string # nullable
  --enable-auth: string@bool-completer
  --id: int
  --max-limit: int
  name: string
  --proactive-requerying-seconds: int
  --body-query: string
  --sandboxable: string@bool-completer # nullable
  --source-mapping: record # nullable
  --body-token: string
]: any -> record<cache_duration_seconds: int, description: string, enable_auth: bool, id: int, max_limit: int, name: string, proactive_requerying_seconds: int, query: string, sandboxable: bool, source_mapping: record, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoints/($token)")
  let body = {cache_duration_seconds: $cache_duration_seconds, description: $description, enable_auth: $enable_auth, id: $id, max_limit: $max_limit, name: $name, proactive_requerying_seconds: $proactive_requerying_seconds, query: $body_query, sandboxable: $sandboxable, source_mapping: $source_mapping, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update endpoint
#
# PUT /api/endpoints/{token}
# operationId: LogflareWeb.Api.EndpointController.update
export def "endpoints LogflareWebApiEndpointControllerupdate" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --cache-duration-seconds: int
  --description: string # nullable
  --enable-auth: string@bool-completer
  --id: int
  --max-limit: int
  name: string
  --proactive-requerying-seconds: int
  --body-query: string
  --sandboxable: string@bool-completer # nullable
  --source-mapping: record # nullable
  --body-token: string
]: any -> record<cache_duration_seconds: int, description: string, enable_auth: bool, id: int, max_limit: int, name: string, proactive_requerying_seconds: int, query: string, sandboxable: bool, source_mapping: record, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/endpoints/($token)")
  let body = {cache_duration_seconds: $cache_duration_seconds, description: $description, enable_auth: $enable_auth, id: $id, max_limit: $max_limit, name: $name, proactive_requerying_seconds: $proactive_requerying_seconds, query: $body_query, sandboxable: $sandboxable, source_mapping: $source_mapping, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create log event
#
# OPTIONS /api/events
# operationId: LogflareWeb.LogController.create
export def "events LogflareWebLogControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source UUID (e.g. a040ae88-3e27-448b-9ee6-622278b23193)
  --source-name: string # Source name (e.g. MyApp.MySource)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "source_name" $source_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create log event
#
# POST /api/events
# operationId: LogflareWeb.LogController.create (2)
export def "events LogflareWebLogControllercreate-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source UUID (e.g. a040ae88-3e27-448b-9ee6-622278b23193)
  --source-name: string # Source name (e.g. MyApp.MySource)
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "source_name" $source_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk delete key-value pairs by keys or by accessor path into values
#
# DELETE /api/key-values
# operationId: LogflareWeb.Api.KeyValueController.delete
export def "key-values LogflareWebApiKeyValueControllerdelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessor: string # Dot-path or JSONPath into the JSONB value (required with values)
  --keys: list
  --values: list
]: any -> record<deleted_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/key-values")
  let body = {accessor: $accessor, keys: $keys, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List key-value pairs
#
# GET /api/key-values
# operationId: LogflareWeb.Api.KeyValueController.index
export def "key-values LogflareWebApiKeyValueControllerindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # Filter by key (exact match)
]: nothing -> table<id: int, key: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/key-values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk upsert key-value pairs
#
# POST /api/key-values
# operationId: LogflareWeb.Api.KeyValueController.create
export def "key-values LogflareWebApiKeyValueControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, key: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/key-values")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create log event
#
# OPTIONS /api/logs
# operationId: LogflareWeb.LogController.create (3)
export def "logs LogflareWebLogControllercreate-3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source UUID (e.g. a040ae88-3e27-448b-9ee6-622278b23193)
  --source-name: string # Source name (e.g. MyApp.MySource)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "source_name" $source_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create log event
#
# POST /api/logs
# operationId: LogflareWeb.LogController.create (4)
export def "logs LogflareWebLogControllercreate-4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-source: string # Source UUID (e.g. a040ae88-3e27-448b-9ee6-622278b23193)
  --source-name: string # Source name (e.g. MyApp.MySource)
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar") (serialize-qp "source_name" $source_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Execute a query
#
# GET /api/query
# operationId: LogflareWeb.Api.QueryController.query
export def "query LogflareWebApiQueryControllerquery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sql: string # BigQuery SQL string, alias for bq_sql
  --bq-sql: string # BigQuery SQL string (e.g. select current_timestamp() as 'test')
  --ch-sql: string # ClickHouse SQL string (e.g. select now() as 'test')
  --pg-sql: string # PostgresSQL string (e.g. select current_date() as 'test')
]: nothing -> table<errors: any, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sql" $sql "scalar") (serialize-qp "bq_sql" $bq_sql "scalar") (serialize-qp "ch_sql" $ch_sql "scalar") (serialize-qp "pg_sql" $pg_sql "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Parses a query
#
# GET /api/query/parse
# operationId: LogflareWeb.Api.QueryController.parse
export def "query-parse LogflareWebApiQueryControllerparse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sql: string # BigQuery SQL string, alias for bq_sql (allows empty value)
  --bq-sql: string # BigQuery SQL string (e.g. select current_timestamp() as 'test')
  --ch-sql: string # ClickHouse SQL string (e.g. select now() as 'test')
]: nothing -> record<errors: any, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sql" $sql "scalar") (serialize-qp "bq_sql" $bq_sql "scalar") (serialize-qp "ch_sql" $ch_sql "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/query/parse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List rules
#
# GET /api/rules
# operationId: LogflareWeb.Api.RuleController.index
export def "rules LogflareWebApiRuleControllerindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<backend_id: int, id: int, inserted_at: string, lql_string: string, source_id: int, token: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create rule. Allows batch creation if as a list.
#
# POST /api/rules
# operationId: LogflareWeb.Api.RuleController.create
export def "rules LogflareWebApiRuleControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --backend-id: int
  --id: int
  --inserted-at: string # format: date-time
  --lql-string: string
  --source-id: int
  --body-token: string
  --updated-at: string # format: date-time
]: any -> record<backend_id: int, id: int, inserted_at: string, lql_string: string, source_id: int, token: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rules")
  let body = {backend_id: $backend_id, id: $id, inserted_at: $inserted_at, lql_string: $lql_string, source_id: $source_id, token: $body_token, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete rule
#
# DELETE /api/rules/{token}
# operationId: LogflareWeb.Api.RuleController.delete
export def "rules LogflareWebApiRuleControllerdelete" [
  token: string
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
  let full_url = (build-url $base $"/api/rules/($token)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch rule
#
# GET /api/rules/{token}
# operationId: LogflareWeb.Api.RuleController.show
export def "rules LogflareWebApiRuleControllershow" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<backend_id: int, id: int, inserted_at: string, lql_string: string, source_id: int, token: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rules/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update rule
#
# PATCH /api/rules/{token}
# operationId: LogflareWeb.Api.RuleController.update (2)
export def "rules LogflareWebApiRuleControllerupdate-2" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --backend-id: int
  --id: int
  --inserted-at: string # format: date-time
  --lql-string: string
  --source-id: int
  --body-token: string
  --updated-at: string # format: date-time
]: any -> record<backend_id: int, id: int, inserted_at: string, lql_string: string, source_id: int, token: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rules/($token)")
  let body = {backend_id: $backend_id, id: $id, inserted_at: $inserted_at, lql_string: $lql_string, source_id: $source_id, token: $body_token, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update rule
#
# PUT /api/rules/{token}
# operationId: LogflareWeb.Api.RuleController.update
export def "rules LogflareWebApiRuleControllerupdate" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --backend-id: int
  --id: int
  --inserted-at: string # format: date-time
  --lql-string: string
  --source-id: int
  --body-token: string
  --updated-at: string # format: date-time
]: any -> record<backend_id: int, id: int, inserted_at: string, lql_string: string, source_id: int, token: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rules/($token)")
  let body = {backend_id: $backend_id, id: $id, inserted_at: $inserted_at, lql_string: $lql_string, source_id: $source_id, token: $body_token, updated_at: $updated_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List sources
#
# GET /api/sources
# operationId: LogflareWeb.Api.SourceController.index
export def "sources LogflareWebApiSourceControllerindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<api_quota: int, bigquery_table_ttl: int, bq_table_id: string, custom_event_message_keys: string, default_ingest_backend_enabled_: bool, description: string, favorite: bool, has_rejected_events: bool, id: int, inserted_at: string, metrics: record, name: string, notifications: record, public_token: string, slack_hook_url: string, token: string, updated_at: string, webhook_notification_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/sources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create source
#
# POST /api/sources
# operationId: LogflareWeb.Api.SourceController.create
export def "sources LogflareWebApiSourceControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-quota: int
  --bigquery-table-ttl: int
  --bq-table-id: string
  --custom-event-message-keys: string
  --default-ingest-backend-enabled?: string@bool-completer
  --description: string # nullable
  --favorite: string@bool-completer
  --has-rejected-events: string@bool-completer
  --id: int
  --inserted-at: string # format: date-time
  --metrics: record
  name: string
  --notifications: record
  --public-token: string
  --slack-hook-url: string
  --body-token: string
  --updated-at: string # format: date-time
  --webhook-notification-url: string
]: any -> record<api_quota: int, bigquery_table_ttl: int, bq_table_id: string, custom_event_message_keys: string, default_ingest_backend_enabled_: bool, description: string, favorite: bool, has_rejected_events: bool, id: int, inserted_at: string, metrics: record, name: string, notifications: record, public_token: string, slack_hook_url: string, token: string, updated_at: string, webhook_notification_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/sources")
  let body = {api_quota: $api_quota, bigquery_table_ttl: $bigquery_table_ttl, bq_table_id: $bq_table_id, custom_event_message_keys: $custom_event_message_keys, default_ingest_backend_enabled?: $default_ingest_backend_enabled?, description: $description, favorite: $favorite, has_rejected_events: $has_rejected_events, id: $id, inserted_at: $inserted_at, metrics: $metrics, name: $name, notifications: $notifications, public_token: $public_token, slack_hook_url: $slack_hook_url, token: $body_token, updated_at: $updated_at, webhook_notification_url: $webhook_notification_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove source backend
#
# DELETE /api/sources/{source_token}/backends/{backend_token}
# operationId: LogflareWeb.Api.SourceController.remove_backend
export def "sources-backends backend-by-source_token-backend_token" [
  source_token: string
  backend_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_quota: int, bigquery_table_ttl: int, bq_table_id: string, custom_event_message_keys: string, default_ingest_backend_enabled_: bool, description: string, favorite: bool, has_rejected_events: bool, id: int, inserted_at: string, metrics: record, name: string, notifications: record, public_token: string, slack_hook_url: string, token: string, updated_at: string, webhook_notification_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/sources/($source_token)/backends/($backend_token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add source backend
#
# POST /api/sources/{source_token}/backends/{backend_token}
# operationId: LogflareWeb.Api.SourceController.add_backend
export def "sources-backends backend-by-source_token-backend_token-1" [
  source_token: string
  backend_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_quota: int, bigquery_table_ttl: int, bq_table_id: string, custom_event_message_keys: string, default_ingest_backend_enabled_: bool, description: string, favorite: bool, has_rejected_events: bool, id: int, inserted_at: string, metrics: record, name: string, notifications: record, public_token: string, slack_hook_url: string, token: string, updated_at: string, webhook_notification_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/sources/($source_token)/backends/($backend_token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recent events in a source
#
# GET /api/sources/{source_token}/recent
# operationId: LogflareWeb.Api.SourceController.recent
export def "sources-recent LogflareWebApiSourceControllerrecent" [
  source_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<event_message: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/sources/($source_token)/recent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show source schema
#
# GET /api/sources/{source_token}/schema
# operationId: LogflareWeb.Api.SourceController.show_schema
export def "sources-schema schema" [
  source_token: string
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
  let full_url = (build-url $base $"/api/sources/($source_token)/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete source
#
# DELETE /api/sources/{token}
# operationId: LogflareWeb.Api.SourceController.delete
export def "sources LogflareWebApiSourceControllerdelete" [
  token: string
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
  let full_url = (build-url $base $"/api/sources/($token)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch source
#
# GET /api/sources/{token}
# operationId: LogflareWeb.Api.SourceController.show
export def "sources LogflareWebApiSourceControllershow" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_quota: int, bigquery_table_ttl: int, bq_table_id: string, custom_event_message_keys: string, default_ingest_backend_enabled_: bool, description: string, favorite: bool, has_rejected_events: bool, id: int, inserted_at: string, metrics: record, name: string, notifications: record, public_token: string, slack_hook_url: string, token: string, updated_at: string, webhook_notification_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/sources/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update source
#
# PATCH /api/sources/{token}
# operationId: LogflareWeb.Api.SourceController.update (2)
export def "sources LogflareWebApiSourceControllerupdate-2" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-quota: int
  --bigquery-table-ttl: int
  --bq-table-id: string
  --custom-event-message-keys: string
  --default-ingest-backend-enabled?: string@bool-completer
  --description: string # nullable
  --favorite: string@bool-completer
  --has-rejected-events: string@bool-completer
  --id: int
  --inserted-at: string # format: date-time
  --metrics: record
  name: string
  --notifications: record
  --public-token: string
  --slack-hook-url: string
  --body-token: string
  --updated-at: string # format: date-time
  --webhook-notification-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/sources/($token)")
  let body = {api_quota: $api_quota, bigquery_table_ttl: $bigquery_table_ttl, bq_table_id: $bq_table_id, custom_event_message_keys: $custom_event_message_keys, default_ingest_backend_enabled?: $default_ingest_backend_enabled?, description: $description, favorite: $favorite, has_rejected_events: $has_rejected_events, id: $id, inserted_at: $inserted_at, metrics: $metrics, name: $name, notifications: $notifications, public_token: $public_token, slack_hook_url: $slack_hook_url, token: $body_token, updated_at: $updated_at, webhook_notification_url: $webhook_notification_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update source
#
# PUT /api/sources/{token}
# operationId: LogflareWeb.Api.SourceController.update
export def "sources LogflareWebApiSourceControllerupdate" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-quota: int
  --bigquery-table-ttl: int
  --bq-table-id: string
  --custom-event-message-keys: string
  --default-ingest-backend-enabled?: string@bool-completer
  --description: string # nullable
  --favorite: string@bool-completer
  --has-rejected-events: string@bool-completer
  --id: int
  --inserted-at: string # format: date-time
  --metrics: record
  name: string
  --notifications: record
  --public-token: string
  --slack-hook-url: string
  --body-token: string
  --updated-at: string # format: date-time
  --webhook-notification-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/sources/($token)")
  let body = {api_quota: $api_quota, bigquery_table_ttl: $bigquery_table_ttl, bq_table_id: $bq_table_id, custom_event_message_keys: $custom_event_message_keys, default_ingest_backend_enabled?: $default_ingest_backend_enabled?, description: $description, favorite: $favorite, has_rejected_events: $has_rejected_events, id: $id, inserted_at: $inserted_at, metrics: $metrics, name: $name, notifications: $notifications, public_token: $public_token, slack_hook_url: $slack_hook_url, token: $body_token, updated_at: $updated_at, webhook_notification_url: $webhook_notification_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List teams
#
# GET /api/teams
# operationId: LogflareWeb.Api.TeamController.index
export def "teams LogflareWebApiTeamControllerindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, team_users: list<record>, token: string, user: record<api_key: string, api_quota: int, bigquery_dataset_id: string, bigquery_dataset_location: string, bigquery_project_id: string, company: string, email: string, email_me_product: bool, email_preferred: string, image: string, name: string, phone: string, provider: string, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Team
#
# POST /api/teams
# operationId: LogflareWeb.Api.TeamController.create
# --team_users item shape: {email: string, name: string}
# --user shape: {api_key: string, api_quota?: int, bigquery_dataset_id?: string, bigquery_dataset_location?: string, bigquery_project_id?: string, company?: string, email: string, email_me_product?: bool, email_preferred?: string, image?: string, name?: string, phone?: string, provider: string, token: string}
export def "teams LogflareWebApiTeamControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --team-users: list # item shape: {email: string, name: string}
  --body-token: string
  --user: record # shape: {api_key: string, api_quota?: int, bigquery_dataset_id?: string, bigquery_dataset_location?: string, bigquery_project_id?: string, company?: string, email: string, email_me_product?: bool, email_preferred?: string, image?: string, name?: string, phone?: string, provider: string, token: string}
]: any -> record<name: string, team_users: table<email: string, name: string>, token: string, user: record<api_key: string, api_quota: int, bigquery_dataset_id: string, bigquery_dataset_location: string, bigquery_project_id: string, company: string, email: string, email_me_product: bool, email_preferred: string, image: string, name: string, phone: string, provider: string, token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/teams")
  let body = {name: $name, team_users: $team_users, token: $body_token, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Team
#
# DELETE /api/teams/{token}
# operationId: LogflareWeb.Api.TeamController.delete
export def "teams LogflareWebApiTeamControllerdelete" [
  token: string
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
  let full_url = (build-url $base $"/api/teams/($token)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch team
#
# GET /api/teams/{token}
# operationId: LogflareWeb.Api.TeamController.show
export def "teams LogflareWebApiTeamControllershow" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, team_users: table<email: string, name: string>, token: string, user: record<api_key: string, api_quota: int, bigquery_dataset_id: string, bigquery_dataset_location: string, bigquery_project_id: string, company: string, email: string, email_me_product: bool, email_preferred: string, image: string, name: string, phone: string, provider: string, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/teams/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update team
#
# PATCH /api/teams/{token}
# operationId: LogflareWeb.Api.TeamController.update (2)
# --team_users item shape: {email: string, name: string}
# --user shape: {api_key: string, api_quota?: int, bigquery_dataset_id?: string, bigquery_dataset_location?: string, bigquery_project_id?: string, company?: string, email: string, email_me_product?: bool, email_preferred?: string, image?: string, name?: string, phone?: string, provider: string, token: string}
export def "teams LogflareWebApiTeamControllerupdate-2" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string
  --team-users: list # item shape: {email: string, name: string}
  --body-token: string
  --user: record # shape: {api_key: string, api_quota?: int, bigquery_dataset_id?: string, bigquery_dataset_location?: string, bigquery_project_id?: string, company?: string, email: string, email_me_product?: bool, email_preferred?: string, image?: string, name?: string, phone?: string, provider: string, token: string}
]: any -> record<name: string, team_users: table<email: string, name: string>, token: string, user: record<api_key: string, api_quota: int, bigquery_dataset_id: string, bigquery_dataset_location: string, bigquery_project_id: string, company: string, email: string, email_me_product: bool, email_preferred: string, image: string, name: string, phone: string, provider: string, token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/teams/($token)")
  let body = {name: $name, team_users: $team_users, token: $body_token, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update team
#
# PUT /api/teams/{token}
# operationId: LogflareWeb.Api.TeamController.update
# --team_users item shape: {email: string, name: string}
# --user shape: {api_key: string, api_quota?: int, bigquery_dataset_id?: string, bigquery_dataset_location?: string, bigquery_project_id?: string, company?: string, email: string, email_me_product?: bool, email_preferred?: string, image?: string, name?: string, phone?: string, provider: string, token: string}
export def "teams LogflareWebApiTeamControllerupdate" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string
  --team-users: list # item shape: {email: string, name: string}
  --body-token: string
  --user: record # shape: {api_key: string, api_quota?: int, bigquery_dataset_id?: string, bigquery_dataset_location?: string, bigquery_project_id?: string, company?: string, email: string, email_me_product?: bool, email_preferred?: string, image?: string, name?: string, phone?: string, provider: string, token: string}
]: any -> record<name: string, team_users: table<email: string, name: string>, token: string, user: record<api_key: string, api_quota: int, bigquery_dataset_id: string, bigquery_dataset_location: string, bigquery_project_id: string, company: string, email: string, email_me_product: bool, email_preferred: string, image: string, name: string, phone: string, provider: string, token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/teams/($token)")
  let body = {name: $name, team_users: $team_users, token: $body_token, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
