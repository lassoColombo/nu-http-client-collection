# Auto-generated client for Seldon External API v0.1
# Source: https://api.apis.guru/v2/specs/seldon.local/engine/0.1/openapi.json
# Auth: --token flag or $env.SELDON_EXTERNAL_API_TOKEN

const BASE_URL = "http://seldon.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SELDON_EXTERNAL_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://seldon.local" "https://localhost:80" "https://localhost:8002"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "seldon-v10-feedback send" } } | get name | first)
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

# POST /seldon/{namespace}/{deployment}/api/v1.0/feedback
#
# operationId: SendFeedback
# --request shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
# --response shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
# --truth shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
export def "seldon-v10-feedback send" [
  namespace: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --request: record # shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
  --response: record # shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
  --reward: float # format: float
  --truth: record # shape: {binData?: string, data?: record, meta?: record, status?: record, strData?: string}
]: any -> record<binData: string, data: record<names: list<string>, ndarray: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({namespace: $namespace, deployment: $deployment} | format pattern "/seldon/{namespace}/{deployment}/api/v1.0/feedback"))
  let body = {"request": $request, "response": $response, "reward": $reward, "truth": $truth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /seldon/{namespace}/{deployment}/api/v1.0/predictions
#
# operationId: Predict
# --data shape: {names?: list, ndarray?: list, tensor?: record, tftensor?: record}
# --meta shape: {metrics?: list, puid?: string, requestPath?: record, routing?: record, tags?: record}
# --status shape: {code?: int, info?: string, reason?: string, status?: "SUCCESS"|"FAILURE"}
export def "seldon-v10-predictions post" [
  namespace: string
  deployment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bin-data: string # format: byte
  --data: record # shape: {names?: list, ndarray?: list, tensor?: record, tftensor?: record}
  --meta: record # shape: {metrics?: list, puid?: string, requestPath?: record, routing?: record, tags?: record}
  --status: record # shape: {code?: int, info?: string, reason?: string, status?: "SUCCESS"|"FAILURE"}
  --str-data: string
]: any -> record<binData: string, data: record<names: list<string>, ndarray: list<any>, tensor: record<shape: list, values: list>, tftensor: record<bool_val: list, dcomplex_val: list, double_val: list, dtype: string, float_val: list, half_val: list, int64_val: list, int_val: list, resource_handle_val: list, scomplex_val: list, string_val: list, tensor_content: string, tensor_shape: record, uint32_val: list, uint64_val: list, variant_val: list, version_number: int>>, meta: record<metrics: list<record>, puid: string, requestPath: record, routing: record, tags: record>, status: record<code: int, info: string, reason: string, status: string>, strData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({namespace: $namespace, deployment: $deployment} | format pattern "/seldon/{namespace}/{deployment}/api/v1.0/predictions"))
  let body = {"binData": $bin_data, "data": $data, "meta": $meta, "status": $status, "strData": $str_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
