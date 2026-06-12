# Auto-generated client for Seldon External API v0.1
# Source: https://api.apis.guru/v2/specs/seldon.local/core/0.1/openapi.json
# Auth: --token flag or $env.SELDON_EXTERNAL_API_TOKEN

const BASE_URL = "http://seldon.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SELDON_EXTERNAL_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://seldon.local" "http://localhost:80" "http://localhost:8002"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "aggregate Aggregate" } } | get name | first)
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

# GET /aggregate
#
# operationId: Aggregate
export def "aggregate Aggregate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-body: record
]: nothing -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "body" $qp_body "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /aggregate
#
# operationId: Aggregate2
# --json shape: {seldonMessages?: list}
export def "aggregate Aggregate2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record # shape: {seldonMessages?: list}
]: any -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aggregate")
  let body = {json: $json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /predict
#
# operationId: TransformInput4
export def "predict TransformInput4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record # e.g. {json: {"data":{"names" : ["feature1"],"tensor" : {"shape": [1,1],"values": [1]}}}}
]: nothing -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json" $json "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/predict" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /predict
#
# operationId: TransformInput3
# --json shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
export def "predict TransformInput3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record # shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
]: any -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/predict")
  let body = {json: $json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /route
#
# operationId: Route2
export def "route Route2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record
]: nothing -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json" $json "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/route" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /route
#
# operationId: Route
# --json shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
export def "route Route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record # shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
]: any -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/route")
  let body = {json: $json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /send-feedback
#
# operationId: SendFeedback2
export def "send-feedback SendFeedback2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record
]: nothing -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json" $json "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/send-feedback" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /send-feedback
#
# operationId: SendFeedback
# --json shape: {request?: record, response?: record, reward?: float, truth?: record}
export def "send-feedback SendFeedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record # shape: {request?: record, response?: record, reward?: float, truth?: record}
]: any -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/send-feedback")
  let body = {json: $json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /transform-input
#
# operationId: TransformInput2
export def "transform-input TransformInput2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record
]: nothing -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json" $json "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/transform-input" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /transform-input
#
# operationId: TransformInput
# --json shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
export def "transform-input TransformInput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record # shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
]: any -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transform-input")
  let body = {json: $json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /transform-output
#
# operationId: TransformOutput2
export def "transform-output TransformOutput2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record
]: nothing -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json" $json "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/transform-output" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /transform-output
#
# operationId: TransformOutput
# --json shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
export def "transform-output TransformOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: record # shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
]: any -> record<binData: string, data: record<names: list<string>, ndarry: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transform-output")
  let body = {json: $json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
