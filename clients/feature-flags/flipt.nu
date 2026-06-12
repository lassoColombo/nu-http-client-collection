# Auto-generated client for api v1.47.0
# Source: https://raw.githubusercontent.com/flipt-io/flipt/main/openapi.yaml
# Auth: --token flag or $env.API_TOKEN

const BASE_URL = "http://localhost:8080"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "jwt" => { {headers: {Authorization: $"Jwt ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost:8080"] }
def auth-scheme-completer [] { ["bearer" "jwt"] }

# Completers for enum parameters
def type-completer [] { ["BOOLEAN_FLAG_TYPE" "VARIANT_FLAG_TYPE"] }
def segmentOperator-completer [] { ["AND_SEGMENT_OPERATOR" "OR_SEGMENT_OPERATOR"] }
def matchType-completer [] { ["ALL_MATCH_TYPE" "ANY_MATCH_TYPE"] }
def type-completer-1 [] { ["BOOLEAN_COMPARISON_TYPE" "DATETIME_COMPARISON_TYPE" "ENTITY_ID_COMPARISON_TYPE" "NUMBER_COMPARISON_TYPE" "STRING_COMPARISON_TYPE" "UNKNOWN_COMPARISON_TYPE"] }
def method-completer [] { ["METHOD_CLOUD" "METHOD_GITHUB" "METHOD_JWT" "METHOD_KUBERNETES" "METHOD_NONE" "METHOD_OIDC" "METHOD_TOKEN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "namespaces listNamespaces" } } | get name | first)
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

# GET /api/v1/namespaces
#
# operationId: listNamespaces
export def "namespaces listNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --offset: int # format: int32
  --pageToken: string
  --reference: string
]: nothing -> record<namespaces: table<key: string, name: string, description: string, protected: bool, createdAt: string, updatedAt: string>, nextPageToken: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/namespaces
#
# operationId: createNamespace
export def "namespaces createNamespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string
  name: string
  --description: string
]: any -> record<key: string, name: string, description: string, protected: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/namespaces")
  let body = {key: $key, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/namespaces/{key}
#
# operationId: getNamespace
export def "namespaces get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reference: string
]: nothing -> record<key: string, name: string, description: string, protected: bool, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/namespaces/{key}
#
# operationId: updateNamespace
export def "namespaces updateNamespace" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-key: string
  name: string
  --description: string
]: any -> record<key: string, name: string, description: string, protected: bool, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($key)")
  let body = {key: $body_key, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/namespaces/{key}
#
# operationId: deleteNamespace
export def "namespaces delete" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/namespaces/{namespaceKey}/flags
#
# operationId: listFlags
export def "namespaces-flags listFlags" [
  namespaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --offset: int # format: int32
  --pageToken: string
  --reference: string
]: nothing -> record<flags: table<key: string, name: string, description: string, enabled: bool, createdAt: string, updatedAt: string, variants: list, namespaceKey: string, type: string, defaultVariant: record, metadata: record>, nextPageToken: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/namespaces/{namespaceKey}/flags
#
# operationId: createFlag
export def "namespaces-flags createFlag" [
  namespaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string
  name: string
  --description: string
  --enabled: oneof<nothing, bool>
  --body-namespaceKey: string
  type: string@type-completer # format: enum
  --metadata: record
]: any -> record<key: string, name: string, description: string, enabled: bool, createdAt: string, updatedAt: string, variants: table<id: string, flagKey: string, key: string, name: string, description: string, createdAt: string, updatedAt: string, attachment: string, namespaceKey: string>, namespaceKey: string, type: string, defaultVariant: record<id: string, flagKey: string, key: string, name: string, description: string, createdAt: string, updatedAt: string, attachment: string, namespaceKey: string>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags")
  let body = {key: $key, name: $name, description: $description, enabled: $enabled, namespaceKey: $body_namespaceKey, type: $type, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rollouts
#
# operationId: listRollouts
export def "namespaces-flags-rollouts listRollouts" [
  namespaceKey: string
  flagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --pageToken: string
  --reference: string
]: nothing -> record<rules: table<id: string, namespaceKey: string, flagKey: string, type: string, rank: int, description: string, createdAt: string, updatedAt: string, segment: record, threshold: record>, nextPageToken: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rollouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rollouts
#
# operationId: createRollout
# --segment shape: {segmentKey?: string, value?: bool, segmentKeys?: list, segmentOperator?: "OR_SEGMENT_OPERATOR"|"AND_SEGMENT_OPERATOR"}
# --threshold shape: {percentage?: float, value?: bool}
export def "namespaces-flags-rollouts createRollout" [
  namespaceKey: string
  flagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespaceKey: string
  --body-flagKey: string
  rank: int # format: int32
  --description: string
  --segment: record # shape: {segmentKey?: string, value?: bool, segmentKeys?: list, segmentOperator?: "OR_SEGMENT_OPERATOR"|"AND_SEGMENT_OPERATOR"}
  --threshold: record # shape: {percentage?: float, value?: bool}
]: any -> record<id: string, namespaceKey: string, flagKey: string, type: string, rank: int, description: string, createdAt: string, updatedAt: string, segment: record<segmentKey: string, value: bool, segmentKeys: list<string>, segmentOperator: string>, threshold: record<percentage: float, value: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rollouts")
  let body = {namespaceKey: $body_namespaceKey, flagKey: $body_flagKey, rank: $rank, description: $description, segment: $segment, threshold: $threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rollouts/order
#
# operationId: orderRollouts
export def "namespaces-flags-rollouts-order orderRollouts" [
  namespaceKey: string
  flagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-flagKey: string
  --body-namespaceKey: string
  rolloutIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rollouts/order")
  let body = {flagKey: $body_flagKey, namespaceKey: $body_namespaceKey, rolloutIds: $rolloutIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rollouts/{id}
#
# operationId: getRollout
export def "namespaces-flags-rollouts get" [
  namespaceKey: string
  flagKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reference: string
]: nothing -> record<id: string, namespaceKey: string, flagKey: string, type: string, rank: int, description: string, createdAt: string, updatedAt: string, segment: record<segmentKey: string, value: bool, segmentKeys: list<string>, segmentOperator: string>, threshold: record<percentage: float, value: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rollouts/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rollouts/{id}
#
# operationId: updateRollout
# --segment shape: {segmentKey?: string, value?: bool, segmentKeys?: list, segmentOperator?: "OR_SEGMENT_OPERATOR"|"AND_SEGMENT_OPERATOR"}
# --threshold shape: {percentage?: float, value?: bool}
export def "namespaces-flags-rollouts updateRollout" [
  namespaceKey: string
  flagKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --body-namespaceKey: string
  --body-flagKey: string
  --description: string
  --segment: record # shape: {segmentKey?: string, value?: bool, segmentKeys?: list, segmentOperator?: "OR_SEGMENT_OPERATOR"|"AND_SEGMENT_OPERATOR"}
  --threshold: record # shape: {percentage?: float, value?: bool}
]: any -> record<id: string, namespaceKey: string, flagKey: string, type: string, rank: int, description: string, createdAt: string, updatedAt: string, segment: record<segmentKey: string, value: bool, segmentKeys: list<string>, segmentOperator: string>, threshold: record<percentage: float, value: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rollouts/($id)")
  let body = {id: $body_id, namespaceKey: $body_namespaceKey, flagKey: $body_flagKey, description: $description, segment: $segment, threshold: $threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rollouts/{id}
#
# operationId: deleteRollout
export def "namespaces-flags-rollouts delete" [
  namespaceKey: string
  flagKey: string
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
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rollouts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules
#
# operationId: listRules
export def "namespaces-flags-rules listRules" [
  namespaceKey: string
  flagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --offset: int # format: int32
  --pageToken: string
  --reference: string
]: nothing -> record<rules: table<id: string, flagKey: string, segmentKey: string, distributions: list, rank: int, createdAt: string, updatedAt: string, namespaceKey: string, segmentKeys: list, segmentOperator: string>, nextPageToken: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules
#
# operationId: createRule
export def "namespaces-flags-rules createRule" [
  namespaceKey: string
  flagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-flagKey: string
  --segmentKey: string
  rank: int # format: int32
  --body-namespaceKey: string
  --segmentKeys: list
  --segmentOperator: string@segmentOperator-completer # format: enum
]: any -> record<id: string, flagKey: string, segmentKey: string, distributions: table<id: string, ruleId: string, variantId: string, rollout: float, createdAt: string, updatedAt: string>, rank: int, createdAt: string, updatedAt: string, namespaceKey: string, segmentKeys: list<string>, segmentOperator: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules")
  let body = {flagKey: $body_flagKey, segmentKey: $segmentKey, rank: $rank, namespaceKey: $body_namespaceKey, segmentKeys: $segmentKeys, segmentOperator: $segmentOperator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules/order
#
# operationId: orderRules
export def "namespaces-flags-rules-order orderRules" [
  namespaceKey: string
  flagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-flagKey: string
  ruleIds: list
  --body-namespaceKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules/order")
  let body = {flagKey: $body_flagKey, ruleIds: $ruleIds, namespaceKey: $body_namespaceKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules/{id}
#
# operationId: getRule
export def "namespaces-flags-rules get" [
  namespaceKey: string
  flagKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reference: string
]: nothing -> record<id: string, flagKey: string, segmentKey: string, distributions: table<id: string, ruleId: string, variantId: string, rollout: float, createdAt: string, updatedAt: string>, rank: int, createdAt: string, updatedAt: string, namespaceKey: string, segmentKeys: list<string>, segmentOperator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules/{id}
#
# operationId: updateRule
export def "namespaces-flags-rules updateRule" [
  namespaceKey: string
  flagKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --body-flagKey: string
  --segmentKey: string
  --body-namespaceKey: string
  --segmentKeys: list
  --segmentOperator: string@segmentOperator-completer # format: enum
]: any -> record<id: string, flagKey: string, segmentKey: string, distributions: table<id: string, ruleId: string, variantId: string, rollout: float, createdAt: string, updatedAt: string>, rank: int, createdAt: string, updatedAt: string, namespaceKey: string, segmentKeys: list<string>, segmentOperator: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules/($id)")
  let body = {id: $body_id, flagKey: $body_flagKey, segmentKey: $segmentKey, namespaceKey: $body_namespaceKey, segmentKeys: $segmentKeys, segmentOperator: $segmentOperator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules/{id}
#
# operationId: deleteRule
export def "namespaces-flags-rules delete" [
  namespaceKey: string
  flagKey: string
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
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules/{ruleId}/distributions
#
# operationId: createDistribution
export def "namespaces-flags-rules-distributions createDistribution" [
  namespaceKey: string
  flagKey: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-flagKey: string
  --body-ruleId: string
  variantId: string
  rollout: float # format: float
  --body-namespaceKey: string
]: any -> record<id: string, ruleId: string, variantId: string, rollout: float, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules/($ruleId)/distributions")
  let body = {flagKey: $body_flagKey, ruleId: $body_ruleId, variantId: $variantId, rollout: $rollout, namespaceKey: $body_namespaceKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules/{ruleId}/distributions/{id}
#
# operationId: updateDistribution
export def "namespaces-flags-rules-distributions updateDistribution" [
  namespaceKey: string
  flagKey: string
  ruleId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --body-flagKey: string
  --body-ruleId: string
  variantId: string
  rollout: float # format: float
  --body-namespaceKey: string
]: any -> record<id: string, ruleId: string, variantId: string, rollout: float, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules/($ruleId)/distributions/($id)")
  let body = {id: $body_id, flagKey: $body_flagKey, ruleId: $body_ruleId, variantId: $variantId, rollout: $rollout, namespaceKey: $body_namespaceKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/rules/{ruleId}/distributions/{id}
#
# operationId: deleteDistribution
export def "namespaces-flags-rules-distributions delete" [
  namespaceKey: string
  flagKey: string
  ruleId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --variantId: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variantId" $variantId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/rules/($ruleId)/distributions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/variants
#
# operationId: createVariant
export def "namespaces-flags-variants createVariant" [
  namespaceKey: string
  flagKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-flagKey: string
  key: string
  --name: string
  --description: string
  --attachment: string
  --body-namespaceKey: string
]: any -> record<id: string, flagKey: string, key: string, name: string, description: string, createdAt: string, updatedAt: string, attachment: string, namespaceKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/variants")
  let body = {flagKey: $body_flagKey, key: $key, name: $name, description: $description, attachment: $attachment, namespaceKey: $body_namespaceKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/variants/{id}
#
# operationId: updateVariant
export def "namespaces-flags-variants updateVariant" [
  namespaceKey: string
  flagKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --body-flagKey: string
  key: string
  --name: string
  --description: string
  --attachment: string
  --body-namespaceKey: string
]: any -> record<id: string, flagKey: string, key: string, name: string, description: string, createdAt: string, updatedAt: string, attachment: string, namespaceKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/variants/($id)")
  let body = {id: $body_id, flagKey: $body_flagKey, key: $key, name: $name, description: $description, attachment: $attachment, namespaceKey: $body_namespaceKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/namespaces/{namespaceKey}/flags/{flagKey}/variants/{id}
#
# operationId: deleteVariant
export def "namespaces-flags-variants delete" [
  namespaceKey: string
  flagKey: string
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
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($flagKey)/variants/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/namespaces/{namespaceKey}/flags/{key}
#
# operationId: getFlag
export def "namespaces-flags get" [
  namespaceKey: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reference: string
]: nothing -> record<key: string, name: string, description: string, enabled: bool, createdAt: string, updatedAt: string, variants: table<id: string, flagKey: string, key: string, name: string, description: string, createdAt: string, updatedAt: string, attachment: string, namespaceKey: string>, namespaceKey: string, type: string, defaultVariant: record<id: string, flagKey: string, key: string, name: string, description: string, createdAt: string, updatedAt: string, attachment: string, namespaceKey: string>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/namespaces/{namespaceKey}/flags/{key}
#
# operationId: updateFlag
export def "namespaces-flags updateFlag" [
  namespaceKey: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-key: string
  name: string
  --description: string
  --enabled: oneof<nothing, bool>
  --body-namespaceKey: string
  --defaultVariantId: string
  --metadata: record
]: any -> record<key: string, name: string, description: string, enabled: bool, createdAt: string, updatedAt: string, variants: table<id: string, flagKey: string, key: string, name: string, description: string, createdAt: string, updatedAt: string, attachment: string, namespaceKey: string>, namespaceKey: string, type: string, defaultVariant: record<id: string, flagKey: string, key: string, name: string, description: string, createdAt: string, updatedAt: string, attachment: string, namespaceKey: string>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($key)")
  let body = {key: $body_key, name: $name, description: $description, enabled: $enabled, namespaceKey: $body_namespaceKey, defaultVariantId: $defaultVariantId, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/namespaces/{namespaceKey}/flags/{key}
#
# operationId: deleteFlag
export def "namespaces-flags delete" [
  namespaceKey: string
  key: string
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
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/flags/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/namespaces/{namespaceKey}/segments
#
# operationId: listSegments
export def "namespaces-segments listSegments" [
  namespaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --offset: int # format: int32
  --pageToken: string
  --reference: string
]: nothing -> record<segments: table<key: string, name: string, description: string, createdAt: string, updatedAt: string, constraints: list, matchType: string, namespaceKey: string>, nextPageToken: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/namespaces/{namespaceKey}/segments
#
# operationId: createSegment
export def "namespaces-segments createSegment" [
  namespaceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string
  name: string
  --description: string
  matchType: string@matchType-completer # format: enum
  --body-namespaceKey: string
]: any -> record<key: string, name: string, description: string, createdAt: string, updatedAt: string, constraints: table<id: string, segmentKey: string, type: string, property: string, operator: string, value: string, createdAt: string, updatedAt: string, namespaceKey: string, description: string>, matchType: string, namespaceKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/segments")
  let body = {key: $key, name: $name, description: $description, matchType: $matchType, namespaceKey: $body_namespaceKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/namespaces/{namespaceKey}/segments/{key}
#
# operationId: getSegment
export def "namespaces-segments get" [
  namespaceKey: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reference: string
]: nothing -> record<key: string, name: string, description: string, createdAt: string, updatedAt: string, constraints: table<id: string, segmentKey: string, type: string, property: string, operator: string, value: string, createdAt: string, updatedAt: string, namespaceKey: string, description: string>, matchType: string, namespaceKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reference" $reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/segments/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/namespaces/{namespaceKey}/segments/{key}
#
# operationId: updateSegment
export def "namespaces-segments updateSegment" [
  namespaceKey: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-key: string
  name: string
  --description: string
  matchType: string@matchType-completer # format: enum
  --body-namespaceKey: string
]: any -> record<key: string, name: string, description: string, createdAt: string, updatedAt: string, constraints: table<id: string, segmentKey: string, type: string, property: string, operator: string, value: string, createdAt: string, updatedAt: string, namespaceKey: string, description: string>, matchType: string, namespaceKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/segments/($key)")
  let body = {key: $body_key, name: $name, description: $description, matchType: $matchType, namespaceKey: $body_namespaceKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/namespaces/{namespaceKey}/segments/{key}
#
# operationId: deleteSegment
export def "namespaces-segments delete" [
  namespaceKey: string
  key: string
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
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/segments/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/namespaces/{namespaceKey}/segments/{segmentKey}/constraints
#
# operationId: createConstraint
export def "namespaces-segments-constraints createConstraint" [
  namespaceKey: string
  segmentKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-segmentKey: string
  type: string@type-completer-1 # format: enum
  property: string
  operator: string
  --value: string
  --body-namespaceKey: string
  --description: string
]: any -> record<id: string, segmentKey: string, type: string, property: string, operator: string, value: string, createdAt: string, updatedAt: string, namespaceKey: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/segments/($segmentKey)/constraints")
  let body = {segmentKey: $body_segmentKey, type: $type, property: $property, operator: $operator, value: $value, namespaceKey: $body_namespaceKey, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/namespaces/{namespaceKey}/segments/{segmentKey}/constraints/{id}
#
# operationId: updateConstraint
export def "namespaces-segments-constraints updateConstraint" [
  namespaceKey: string
  segmentKey: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --body-segmentKey: string
  type: string@type-completer-1 # format: enum
  property: string
  operator: string
  --value: string
  --body-namespaceKey: string
  --description: string
]: any -> record<id: string, segmentKey: string, type: string, property: string, operator: string, value: string, createdAt: string, updatedAt: string, namespaceKey: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/segments/($segmentKey)/constraints/($id)")
  let body = {id: $body_id, segmentKey: $body_segmentKey, type: $type, property: $property, operator: $operator, value: $value, namespaceKey: $body_namespaceKey, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/namespaces/{namespaceKey}/segments/{segmentKey}/constraints/{id}
#
# operationId: deleteConstraint
export def "namespaces-segments-constraints delete" [
  namespaceKey: string
  segmentKey: string
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
  let full_url = (build-url $base $"/api/v1/namespaces/($namespaceKey)/segments/($segmentKey)/constraints/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /auth/v1/method/kubernetes/serviceaccount
#
# operationId: kubernetesVerifyServiceAccount
export def "auth-method-kubernetes-serviceaccount kubernetesVerifyServiceAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --serviceAccountToken: string
]: any -> record<clientToken: string, authentication: record<id: string, method: string, expiresAt: string, createdAt: string, updatedAt: string, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/v1/method/kubernetes/serviceaccount")
  let body = {serviceAccountToken: $serviceAccountToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /auth/v1/method/oidc/{provider}/authorize
#
# operationId: oidcAuthorizeURL
export def "auth-method-oidc-authorize oidcAuthorizeURL" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string
]: nothing -> record<authorizeUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/auth/v1/method/oidc/($provider)/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /auth/v1/method/oidc/{provider}/callback
#
# operationId: oidcCallback
export def "auth-method-oidc-callback oidcCallback" [
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --state: string
]: nothing -> record<clientToken: string, authentication: record<id: string, method: string, expiresAt: string, createdAt: string, updatedAt: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/auth/v1/method/oidc/($provider)/callback" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /auth/v1/method/token
#
# operationId: createMethodToken
export def "auth-method-token createMethodToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --expiresAt: string # format: date-time
  --namespaceKey: string
  --metadata: record
]: any -> record<clientToken: string, authentication: record<id: string, method: string, expiresAt: string, createdAt: string, updatedAt: string, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/v1/method/token")
  let body = {name: $name, description: $description, expiresAt: $expiresAt, namespaceKey: $namespaceKey, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /auth/v1/self
#
# operationId: getAuthSelf
export def "auth-self get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, method: string, expiresAt: string, createdAt: string, updatedAt: string, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/v1/self")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /auth/v1/self/expire
#
# operationId: expireAuthSelf
export def "auth-self-expire expireAuthSelf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiresAt: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiresAt" $expiresAt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/auth/v1/self/expire" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /auth/v1/tokens
#
# operationId: listAuthTokens
export def "auth-tokens listAuthTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string@method-completer # format: enum
  --limit: int # format: int32
  --pageToken: string
]: nothing -> record<authentications: table<id: string, method: string, expiresAt: string, createdAt: string, updatedAt: string, metadata: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/auth/v1/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /auth/v1/tokens/{id}
#
# operationId: getAuthToken
export def "auth-tokens get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, method: string, expiresAt: string, createdAt: string, updatedAt: string, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/auth/v1/tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /auth/v1/tokens/{id}
#
# operationId: deleteAuthToken
export def "auth-tokens delete" [
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
  let full_url = (build-url $base $"/auth/v1/tokens/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /evaluate/v1/batch
#
# operationId: evaluateBatch
# --requests item shape: {requestId?: string, namespaceKey: string, flagKey: string, entityId: string, context: record, reference?: string}
export def "evaluate-batch evaluateBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requestId: string
  requests: list # item shape: {requestId?: string, namespaceKey: string, flagKey: string, entityId: string, context: record, reference?: string}
  --reference: string
]: any -> record<requestId: string, responses: table<type: string, booleanResponse: record, variantResponse: record, errorResponse: record>, requestDurationMillis: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/evaluate/v1/batch")
  let body = {requestId: $requestId, requests: $requests, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /evaluate/v1/boolean
#
# operationId: evaluateBoolean
export def "evaluate-boolean evaluateBoolean" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requestId: string
  namespaceKey: string
  flagKey: string
  entityId: string
  context: record
  --reference: string
]: any -> record<enabled: bool, reason: string, requestId: string, requestDurationMillis: float, timestamp: string, flagKey: string, segmentKeys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/evaluate/v1/boolean")
  let body = {requestId: $requestId, namespaceKey: $namespaceKey, flagKey: $flagKey, entityId: $entityId, context: $context, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /evaluate/v1/variant
#
# operationId: evaluateVariant
export def "evaluate-variant evaluateVariant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --requestId: string
  namespaceKey: string
  flagKey: string
  entityId: string
  context: record
  --reference: string
]: any -> record<match: bool, segmentKeys: list<string>, reason: string, variantKey: string, variantAttachment: string, requestId: string, requestDurationMillis: float, timestamp: string, flagKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/evaluate/v1/variant")
  let body = {requestId: $requestId, namespaceKey: $namespaceKey, flagKey: $flagKey, entityId: $entityId, context: $context, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OFREP provider configuration
#
# GET /ofrep/v1/configuration
# operationId: ofrep.configuration
export def "ofrep-configuration ofrepconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, capabilities: record<cacheInvalidation: record<polling: record>, flagEvaluation: record<supportedTypes: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ofrep/v1/configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OFREP bulk flag evaluation
#
# POST /ofrep/v1/evaluate/flags
# operationId: ofrep.evaluateBulk
export def "ofrep-evaluate-flags ofrepevaluateBulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --context: record
]: any -> record<flags: table<key: string, reason: string, variant: string, metadata: record, value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ofrep/v1/evaluate/flags")
  let body = {context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OFREP single flag evaluation
#
# POST /ofrep/v1/evaluate/flags/{key}
# operationId: ofrep.evaluateFlag
export def "ofrep-evaluate-flags ofrepevaluateFlag" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-key: string
  --context: record
]: any -> record<key: string, reason: string, variant: string, metadata: record, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ofrep/v1/evaluate/flags/($key)")
  let body = {key: $body_key, context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
