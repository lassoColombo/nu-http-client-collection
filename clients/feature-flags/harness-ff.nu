# Auto-generated client for Harness feature flag service client apis v1.0.0
# Source: https://raw.githubusercontent.com/harness/ff-php-server-sdk/main/api.yaml
# Auth: --token flag or $env.HARNESS_FEATURE_FLAG_SERVICE_CLIENT_APIS_TOKEN

const BASE_URL = "http://localhost/api/1.0"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HARNESS_FEATURE_FLAG_SERVICE_CLIENT_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {api-key: $token_val}, query: ""} }
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
def base-url-completer [] { ["http://localhost/api/1.0" "http://localhost:3000/api/1.0"] }
def auth-scheme-completer [] { ["api-key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "client-env-feature-configs GetFeatureConfig" } } | get name | first)
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

# Get all feature flags activations
#
# GET /client/env/{environmentUUID}/feature-configs
# operationId: GetFeatureConfig
export def "client-env-feature-configs GetFeatureConfig" [
  environmentUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster: string # Unique identifier for the cluster for the account
]: nothing -> table<project: string, environment: string, feature: string, state: string, kind: string, variations: list<record>, rules: list<record>, defaultServe: record<distribution: record, variation: string>, offVariation: string, prerequisites: list<record>, variationToTargetMap: list<record>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cluster" $cluster "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/client/env/($environmentUUID)/feature-configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get feature config
#
# GET /client/env/{environmentUUID}/feature-configs/{identifier}
# operationId: GetFeatureConfigByIdentifier
export def "client-env-feature-configs GetFeatureConfigByIdentifier" [
  identifier: string
  environmentUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster: string # Unique identifier for the cluster for the account
]: nothing -> record<project: string, environment: string, feature: string, state: string, kind: string, variations: table<identifier: string, value: string, name: string, description: string>, rules: table<ruleId: string, priority: int, clauses: list, serve: record>, defaultServe: record<distribution: record<bucketBy: string, variations: list>, variation: string>, offVariation: string, prerequisites: table<feature: string, variations: list>, variationToTargetMap: table<variation: string, targets: list, targetSegments: list>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cluster" $cluster "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/client/env/($environmentUUID)/feature-configs/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all segments.
#
# GET /client/env/{environmentUUID}/target-segments
# operationId: GetAllSegments
export def "client-env-target-segments GetAllSegments" [
  environmentUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster: string # Unique identifier for the cluster for the account
]: nothing -> table<identifier: string, name: string, environment: string, tags: list<record>, included: list<record>, excluded: list<record>, rules: list<record>, createdAt: int, modifiedAt: int, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cluster" $cluster "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/client/env/($environmentUUID)/target-segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a segment by identifier
#
# GET /client/env/{environmentUUID}/target-segments/{identifier}
# operationId: GetSegmentByIdentifier
export def "client-env-target-segments GetSegmentByIdentifier" [
  identifier: string
  environmentUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster: string # Unique identifier for the cluster for the account
]: nothing -> record<identifier: string, name: string, environment: string, tags: table<name: string, value: string>, included: table<identifier: string, account: string, org: string, environment: string, project: string, name: string, anonymous: bool, attributes: record, createdAt: int, segments: list>, excluded: table<identifier: string, account: string, org: string, environment: string, project: string, name: string, anonymous: bool, attributes: record, createdAt: int, segments: list>, rules: table<id: string, attribute: string, op: string, values: list, negate: bool>, createdAt: int, modifiedAt: int, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cluster" $cluster "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/client/env/($environmentUUID)/target-segments/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate with the admin server.
#
# POST /client/auth
# operationId: Authenticate
# --target shape: {identifier: string, name?: string, anonymous?: bool, attributes?: record}
export def "client-auth Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  apiKey: string # e.g. 896045f3-42ee-4e73-9154-086644768b96
  --target: record # shape: {identifier: string, name?: string, anonymous?: bool, attributes?: record}
]: any -> record<authToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client/auth")
  let body = {apiKey: $apiKey, target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get feature evaluations for target
#
# GET /client/env/{environmentUUID}/target/{target}/evaluations
# operationId: GetEvaluations
export def "client-env-target-evaluations GetEvaluations" [
  environmentUUID: string
  target: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster: string # Unique identifier for the cluster for the account
]: nothing -> table<flag: string, value: string, kind: string, identifier: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cluster" $cluster "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/client/env/($environmentUUID)/target/($target)/evaluations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get feature evaluations for target
#
# GET /client/env/{environmentUUID}/target/{target}/evaluations/{feature}
# operationId: GetEvaluationByIdentifier
export def "client-env-target-evaluations GetEvaluationByIdentifier" [
  environmentUUID: string
  feature: string
  target: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster: string # Unique identifier for the cluster for the account
]: nothing -> record<flag: string, value: string, kind: string, identifier: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cluster" $cluster "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/client/env/($environmentUUID)/target/($target)/evaluations/($feature)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send metrics to the Analytics server.
#
# POST /metrics/{environment}
# operationId: postMetrics
# --targetData item shape: {identifier: string, name: string, attributes: list}
# --metricsData item shape: {timestamp: int, count: int, metricsType: "FFMETRICS", attributes: list}
export def "metrics post" [
  environment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster: string # Unique identifier for the cluster for the account
  --targetData: list # item shape: {identifier: string, name: string, attributes: list}
  --metricsData: list # item shape: {timestamp: int, count: int, metricsType: "FFMETRICS", attributes: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cluster" $cluster "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/metrics/($environment)" $qp)
  let body = {targetData: $targetData, metricsData: $metricsData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stream endpoint.
#
# GET /stream
# operationId: Stream
export def "stream Stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cluster: string # Unique identifier for the cluster for the account
  --API-Key: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cluster" $cluster "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stream" $qp)
  let extra_headers = {"API-Key": $API_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
