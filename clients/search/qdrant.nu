# Auto-generated client for Qdrant API vmaster
# Source: https://raw.githubusercontent.com/qdrant/qdrant/master/docs/redoc/master/openapi.json
# Auth: --token flag or $env.QDRANT_API_TOKEN

const BASE_URL = "http://localhost:6333"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o QDRANT_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost:6333" "https://localhost:6333"] }
def auth-scheme-completer [] { ["api-key" "bearer"] }

# Completers for enum parameters
def ordering-completer [] { ["medium" "strong" "weak"] }
def priority-completer [] { ["no_sync" "replica" "snapshot"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "collections-shards key" } } | get name | first)
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

# Create shard key
#
# PUT /collections/{collection_name}/shards
# operationId: create_shard_key
export def "collections-shards key" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  shard_key: any
  --shards-number: int # How many shards to create for this key If not specified, will use the default value from config (nullable, format: uint32)
  --replication-factor: int # How many replicas to create for each shard If not specified, will use the default value from config (nullable, format: uint32)
  --placement: list # Placement of shards for this key List of peer ids, that can be used to place shards for this key If not specified, will be randomly placed among all peers (nullable)
  --initial-state: any # Initial state of the shards for this key If not specified, will be `Initializing` first and then `Active` Warning: do not change this unless you know what you are doing
]: any -> record<usage: any, time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/shards" $qp)
  let body = {shard_key: $shard_key, shards_number: $shards_number, replication_factor: $replication_factor, placement: $placement, initial_state: $initial_state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List shard keys
#
# GET /collections/{collection_name}/shards
# operationId: list_shard_keys
export def "collections-shards keys" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: record<shard_keys: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/shards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete shard key
#
# POST /collections/{collection_name}/shards/delete
# operationId: delete_shard_key
export def "collections-shards-delete key" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  shard_key: any
]: any -> record<usage: any, time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/shards/delete" $qp)
  let body = {shard_key: $shard_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns information about the running Qdrant instance
#
# GET /
# operationId: root
export def "service root" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<title: string, version: string, commit: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Collect telemetry data
#
# GET /telemetry
# operationId: telemetry
export def "telemetry telemetry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anonymize: oneof<nothing, bool> # If true, anonymize result
  --details-level: int # Level of details in telemetry data. Minimal level is 0, maximal is infinity
  --per-collection: oneof<nothing, bool> # If true, include per-collection request statistics in the response
  --timeout: int # Timeout for this request (default: 60)
]: nothing -> record<usage: any, time: float, status: string, result: record<id: string, app: any, collections: record<number_of_collections: int, max_collections: int, collections: list, snapshots: list>, cluster: any, requests: any, memory: any, hardware: any, search_pool: any>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "anonymize" $anonymize "scalar") (serialize-qp "details_level" $details_level "scalar") (serialize-qp "per_collection" $per_collection "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telemetry" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Collect Prometheus metrics data
#
# GET /metrics
# operationId: metrics
export def "metrics metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anonymize: oneof<nothing, bool> # If true, anonymize result
  --per-collection: oneof<nothing, bool> # If true, include per-collection request metrics with a collection label instead of global request metrics
  --timeout: int # Timeout for this request (default: 60)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "anonymize" $anonymize "scalar") (serialize-qp "per_collection" $per_collection "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kubernetes healthz endpoint
#
# GET /healthz
# operationId: healthz
export def "healthz healthz" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/healthz")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kubernetes livez endpoint
#
# GET /livez
# operationId: livez
export def "livez livez" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/livez")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kubernetes readyz endpoint
#
# GET /readyz
# operationId: readyz
export def "readyz readyz" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/readyz")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get issues
#
# GET /issues
# operationId: get_issues
export def "issues issues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/issues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clear issues
#
# DELETE /issues
# operationId: clear_issues
export def "issues issues-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/issues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cluster status info
#
# GET /cluster
# operationId: cluster_status
export def "cluster status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Collect cluster telemetry data
#
# GET /cluster/telemetry
# operationId: cluster_telemetry
export def "cluster-telemetry telemetry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --details-level: int # The level of detail to include in the response
  --timeout: int # Timeout for this request (default: 60)
]: nothing -> record<usage: any, time: float, status: string, result: record<collections: record, cluster: any>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details_level" $details_level "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cluster/telemetry" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tries to recover current peer Raft state.
#
# POST /cluster/recover
# operationId: recover_current_peer
export def "cluster-recover peer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove peer from the cluster
#
# DELETE /cluster/peer/{peer_id}
# operationId: remove_peer
export def "cluster-peer peer" [
  peer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  --force: oneof<nothing, bool> # If true - removes peer even if it has shards/replicas on it. (default: false)
]: nothing -> record<usage: any, time: float, status: string, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cluster/peer/($peer_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List collections
#
# GET /collections
# operationId: get_collections
export def "collections collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: record<collections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Collection info
#
# GET /collections/{collection_name}
# operationId: get_collection
export def "collections collection-by-collection_name" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: record<status: string, optimizer_status: any, warnings: list<record>, indexed_vectors_count: int, points_count: int, segments_count: int, config: record<params: record, hnsw_config: record, optimizer_config: record, wal_config: any, quantization_config: any, strict_mode_config: any, metadata: any>, payload_schema: record, update_queue: any>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create collection
#
# PUT /collections/{collection_name}
# operationId: create_collection
export def "collections collection-by-collection_name-1" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  --vectors: any # Vector params separator for single and multiple vector modes Single mode:  { "size": 128, "distance": "Cosine" }  or multiple mode:  { "default": { "size": 128, "distance": "Cosine" } }
  --shard-number: int # For auto sharding: Number of shards in collection. - Default is 1 for standalone, otherwise equal to the number of nodes - Minimum is 1  For custom sharding: Number of shards in collection per shard group. - Default is 1, meaning that each shard key will be mapped to a single shard - Minimum is 1 (nullable, format: uint32)
  --sharding-method: any # Sharding method Default is Auto - points are distributed across all available shards Custom - points are distributed across shards according to shard key
  --replication-factor: int # Number of shards replicas. Default is 1 Minimum is 1 (nullable, format: uint32)
  --write-consistency-factor: int # Defines how many replicas should apply the operation for us to consider it successful. Increasing this number will make the collection more resilient to inconsistencies, but will also make it fail if not enough replicas are available. Does not have any performance impact. (nullable, format: uint32)
  --on-disk-payload: oneof<nothing, bool> # If true - point's payload will not be stored in memory. It will be read from the disk every time it is requested. This setting saves RAM by (slightly) increasing the response time. Note: those payload values that are involved in filtering and are indexed - remain in RAM.  Default: true (nullable)
  --hnsw-config: any # Custom params for HNSW index. If none - values from service configuration file are used.
  --wal-config: any # Custom params for WAL. If none - values from service configuration file are used.
  --optimizers-config: any # Custom params for Optimizers.  If none - values from service configuration file are used.
  --quantization-config: any # Quantization parameters. If none - quantization is disabled.
  --sparse-vectors: record # Sparse vector data config. (nullable)
  --strict-mode-config: any # Strict-mode config.
  --metadata: any # Arbitrary JSON metadata for the collection This can be used to store application-specific information such as creation time, migration data, inference model info, etc.
]: any -> record<usage: any, time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)" $qp)
  let body = {vectors: $vectors, shard_number: $shard_number, sharding_method: $sharding_method, replication_factor: $replication_factor, write_consistency_factor: $write_consistency_factor, on_disk_payload: $on_disk_payload, hnsw_config: $hnsw_config, wal_config: $wal_config, optimizers_config: $optimizers_config, quantization_config: $quantization_config, sparse_vectors: $sparse_vectors, strict_mode_config: $strict_mode_config, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update collection parameters
#
# PATCH /collections/{collection_name}
# operationId: update_collection
export def "collections collection-by-collection_name-2" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  --vectors: any # Map of vector data parameters to update for each named vector. To update parameters in a collection having a single unnamed vector, use an empty string as name.
  --optimizers-config: any # Custom params for Optimizers.  If none - it is left unchanged. This operation is blocking, it will only proceed once all current optimizations are complete
  --params: any # Collection base params. If none - it is left unchanged.
  --hnsw-config: any # HNSW parameters to update for the collection index. If none - it is left unchanged.
  --quantization-config: any # Quantization parameters to update. If none - it is left unchanged.
  --sparse-vectors: any # Map of sparse vector data parameters to update for each sparse vector.
  --strict-mode-config: any
  --metadata: any # Metadata to update for the collection. If provided, this will merge with existing metadata. To remove metadata, set it to an empty object.
]: any -> record<usage: any, time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)" $qp)
  let body = {vectors: $vectors, optimizers_config: $optimizers_config, params: $params, hnsw_config: $hnsw_config, quantization_config: $quantization_config, sparse_vectors: $sparse_vectors, strict_mode_config: $strict_mode_config, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete collection
#
# DELETE /collections/{collection_name}
# operationId: delete_collection
export def "collections collection-by-collection_name-3" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
]: nothing -> record<usage: any, time: float, status: string, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update aliases of the collections
#
# POST /collections/aliases
# operationId: update_aliases
export def "collections-aliases aliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  actions: list
]: any -> record<usage: any, time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/collections/aliases" $qp)
  let body = {actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create index for field in collection
#
# PUT /collections/{collection_name}/index
# operationId: create_field_index
export def "collections-index index-by-collection_name" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  field_name: string
  --field-schema: any
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/index" $qp)
  let body = {field_name: $field_name, field_schema: $field_schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check the existence of a collection
#
# GET /collections/{collection_name}/exists
# operationId: collection_exists
export def "collections-exists exists" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: record<exists: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete index for field in collection
#
# DELETE /collections/{collection_name}/index/{field_name}
# operationId: delete_field_index
export def "collections-index index-by-collection_name-field_name" [
  collection_name: string
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
]: nothing -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/index/($field_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create named vector
#
# PUT /collections/{collection_name}/vectors/{vector_name}
# operationId: create_vector_name
# --dense shape: {size: int, distance: "Cosine"|"Euclid"|"Dot"|"Manhattan", multivector_config?: any, datatype?: any}
# --sparse shape: {modifier?: any, datatype?: any}
export def "collections-vectors name-by-collection_name-vector_name" [
  collection_name: string
  vector_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  --dense: record # Configuration for creating a new dense named vector.  Only includes properties that define the vector space and cannot be changed after creation. Storage type, index type, and quantization are inferred. — shape: {size: int, distance: "Cosine"|"Euclid"|"Dot"|"Manhattan", multivector_config?: any, datatype?: any}
  --sparse: record # Configuration for creating a new sparse named vector.  Only includes properties that define the vector space and cannot be changed after creation. — shape: {modifier?: any, datatype?: any}
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/vectors/($vector_name)" $qp)
  let body = {dense: $dense, sparse: $sparse} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete named vector
#
# DELETE /collections/{collection_name}/vectors/{vector_name}
# operationId: delete_vector_name
export def "collections-vectors name-by-collection_name-vector_name-1" [
  collection_name: string
  vector_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
]: nothing -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/vectors/($vector_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Collection cluster info
#
# GET /collections/{collection_name}/cluster
# operationId: collection_cluster_info
export def "collections-cluster info" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: record<peer_id: int, shard_count: int, local_shards: list<record>, remote_shards: list<record>, shard_transfers: list<record>, resharding_operations: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/cluster")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update collection cluster setup
#
# POST /collections/{collection_name}/cluster
# operationId: update_collection_cluster
# --move_shard shape: {shard_id: int, to_peer_id: int, from_peer_id: int, method?: any}
# --replicate_shard shape: {shard_id: int, to_peer_id: int, from_peer_id: int, method?: any}
# --abort_transfer shape: {shard_id: int, to_peer_id: int, from_peer_id: int}
# --drop_replica shape: {shard_id: int, peer_id: int}
# --create_sharding_key shape: {shard_key: any, shards_number?: int, replication_factor?: int, placement?: list, initial_state?: any}
# --drop_sharding_key shape: {shard_key: any}
# --restart_transfer shape: {shard_id: int, from_peer_id: int, to_peer_id: int, method: "stream_records"|"snapshot"|"wal_delta"|"resharding_stream_records"}
# --start_resharding shape: {direction: "up"|"down", peer_id?: int, shard_key?: any}
# --replicate_points shape: {filter?: any, from_shard_key: any, to_shard_key: any}
export def "collections-cluster cluster" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  --move-shard: record # shape: {shard_id: int, to_peer_id: int, from_peer_id: int, method?: any}
  --replicate-shard: record # shape: {shard_id: int, to_peer_id: int, from_peer_id: int, method?: any}
  --abort-transfer: record # shape: {shard_id: int, to_peer_id: int, from_peer_id: int}
  --drop-replica: record # shape: {shard_id: int, peer_id: int}
  --create-sharding-key: record # shape: {shard_key: any, shards_number?: int, replication_factor?: int, placement?: list, initial_state?: any}
  --drop-sharding-key: record # shape: {shard_key: any}
  --restart-transfer: record # shape: {shard_id: int, from_peer_id: int, to_peer_id: int, method: "stream_records"|"snapshot"|"wal_delta"|"resharding_stream_records"}
  --start-resharding: record # shape: {direction: "up"|"down", peer_id?: int, shard_key?: any}
  --abort-resharding: record
  --replicate-points: record # shape: {filter?: any, from_shard_key: any, to_shard_key: any}
]: any -> record<usage: any, time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/cluster" $qp)
  let body = {move_shard: $move_shard, replicate_shard: $replicate_shard, abort_transfer: $abort_transfer, drop_replica: $drop_replica, create_sharding_key: $create_sharding_key, drop_sharding_key: $drop_sharding_key, restart_transfer: $restart_transfer, start_resharding: $start_resharding, abort_resharding: $abort_resharding, replicate_points: $replicate_points} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get optimization progress
#
# GET /collections/{collection_name}/optimizations
# operationId: get_optimizations
export def "collections-optimizations optimizations" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with: string # Comma-separated list of optional fields to include in the response. Possible values: queued, completed, idle_segments.
  --completed-limit: int # Maximum number of completed optimizations to return. Ignored if `completed` is not in the `with` parameter. (default: 16)
]: nothing -> record<usage: any, time: float, status: string, result: record<summary: record<queued_optimizations: int, queued_segments: int, queued_points: int, idle_segments: int>, running: list<record>, queued: list<record>, completed: list<record>, idle_segments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with" $with "scalar") (serialize-qp "completed_limit" $completed_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/optimizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List aliases for collection
#
# GET /collections/{collection_name}/aliases
# operationId: get_collection_aliases
export def "collections-aliases aliases-by-collection_name" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: record<aliases: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/aliases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List collections aliases
#
# GET /aliases
# operationId: get_collections_aliases
export def "aliases aliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: record<aliases: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aliases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover from an uploaded snapshot
#
# POST /collections/{collection_name}/snapshots/upload
# operationId: recover_from_uploaded_snapshot
export def "collections-snapshots-upload snapshot" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
  --priority: string@priority-completer # Defines source of truth for snapshot recovery
  --checksum: string # Optional SHA256 checksum to verify snapshot integrity before recovery.
  --snapshot: string # format: binary
]: any -> record<time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/snapshots/upload" $qp)
  let body = {snapshot: $snapshot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Recover from a snapshot
#
# PUT /collections/{collection_name}/snapshots/recover
# operationId: recover_from_snapshot
export def "collections-snapshots-recover snapshot" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
  location: string # Examples: - URL `http://localhost:8080/collections/my_collection/snapshots/my_snapshot` - Local path `file:///qdrant/snapshots/test_collection-2022-08-04-10-49-10.snapshot` (format: uri)
  --priority: any # Defines which data should be used as a source of truth if there are other replicas in the cluster. If set to `Snapshot`, the snapshot will be used as a source of truth, and the current state will be overwritten. If set to `Replica`, the current state will be used as a source of truth, and after recovery if will be synchronized with the snapshot.
  --checksum: string # Optional SHA256 checksum to verify snapshot integrity before recovery. (nullable)
  --api-key: string # Optional API key used when fetching the snapshot from a remote URL. (nullable)
]: any -> record<time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/snapshots/recover" $qp)
  let body = {location: $location, priority: $priority, checksum: $checksum, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List collection snapshots
#
# GET /collections/{collection_name}/snapshots
# operationId: list_snapshots
export def "collections-snapshots snapshots" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: table<name: string, creation_time: string, size: int, checksum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create collection snapshot
#
# POST /collections/{collection_name}/snapshots
# operationId: create_snapshot
export def "collections-snapshots snapshot-by-collection_name" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
]: nothing -> record<time: float, status: string, result: record<name: string, creation_time: string, size: int, checksum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete collection snapshot
#
# DELETE /collections/{collection_name}/snapshots/{snapshot_name}
# operationId: delete_snapshot
export def "collections-snapshots snapshot-by-collection_name-snapshot_name" [
  collection_name: string
  snapshot_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
]: nothing -> record<time: float, status: string, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/snapshots/($snapshot_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download collection snapshot
#
# GET /collections/{collection_name}/snapshots/{snapshot_name}
# operationId: get_snapshot
export def "collections-snapshots snapshot-by-collection_name-snapshot_name-1" [
  collection_name: string
  snapshot_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<time: float, status: record<error: string>, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/snapshots/($snapshot_name)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of storage snapshots
#
# GET /snapshots
# operationId: list_full_snapshots
export def "snapshots snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: table<name: string, creation_time: string, size: int, checksum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create storage snapshot
#
# POST /snapshots
# operationId: create_full_snapshot
export def "snapshots snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
]: nothing -> record<time: float, status: string, result: record<name: string, creation_time: string, size: int, checksum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete storage snapshot
#
# DELETE /snapshots/{snapshot_name}
# operationId: delete_full_snapshot
export def "snapshots snapshot-by-snapshot_name" [
  snapshot_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
]: nothing -> record<time: float, status: string, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/snapshots/($snapshot_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download storage snapshot
#
# GET /snapshots/{snapshot_name}
# operationId: get_full_snapshot
export def "snapshots snapshot-by-snapshot_name-1" [
  snapshot_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<time: float, status: record<error: string>, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snapshots/($snapshot_name)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download shard snapshot
#
# GET /collections/{collection_name}/shards/{shard_id}/snapshot
# operationId: stream_shard_snapshot
export def "collections-shards-snapshot snapshot" [
  collection_name: string
  shard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<time: float, status: record<error: string>, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/shards/($shard_id)/snapshot")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover shard from an uploaded snapshot
#
# POST /collections/{collection_name}/shards/{shard_id}/snapshots/upload
# operationId: recover_shard_from_uploaded_snapshot
export def "collections-shards-snapshots-upload snapshot" [
  collection_name: string
  shard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
  --priority: string@priority-completer # Defines source of truth for snapshot recovery
  --checksum: string # Optional SHA256 checksum to verify snapshot integrity before recovery.
  --snapshot: string # format: binary
]: any -> record<time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/shards/($shard_id)/snapshots/upload" $qp)
  let body = {snapshot: $snapshot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Recover from a snapshot
#
# PUT /collections/{collection_name}/shards/{shard_id}/snapshots/recover
# operationId: recover_shard_from_snapshot
export def "collections-shards-snapshots-recover snapshot" [
  collection_name: string
  shard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
  location: any
  --priority: any
  --checksum: string # Optional SHA256 checksum to verify snapshot integrity before recovery. (nullable)
  --api-key: string # Optional API key used when fetching the snapshot from a remote URL. (nullable)
]: any -> record<time: float, status: string, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/shards/($shard_id)/snapshots/recover" $qp)
  let body = {location: $location, priority: $priority, checksum: $checksum, api_key: $api_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List shards snapshots for a collection
#
# GET /collections/{collection_name}/shards/{shard_id}/snapshots
# operationId: list_shard_snapshots
export def "collections-shards-snapshots snapshots" [
  collection_name: string
  shard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<usage: any, time: float, status: string, result: table<name: string, creation_time: string, size: int, checksum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/shards/($shard_id)/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create shard snapshot
#
# POST /collections/{collection_name}/shards/{shard_id}/snapshots
# operationId: create_shard_snapshot
export def "collections-shards-snapshots snapshot-by-collection_name-shard_id" [
  collection_name: string
  shard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
]: nothing -> record<time: float, status: string, result: record<name: string, creation_time: string, size: int, checksum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/shards/($shard_id)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete shard snapshot
#
# DELETE /collections/{collection_name}/shards/{shard_id}/snapshots/{snapshot_name}
# operationId: delete_shard_snapshot
export def "collections-shards-snapshots snapshot-by-collection_name-shard_id-snapshot_name" [
  collection_name: string
  shard_id: int
  snapshot_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen. If false - let changes happen in background. Default is true.
]: nothing -> record<time: float, status: string, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/shards/($shard_id)/snapshots/($snapshot_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download collection snapshot
#
# GET /collections/{collection_name}/shards/{shard_id}/snapshots/{snapshot_name}
# operationId: get_shard_snapshot
export def "collections-shards-snapshots snapshot-by-collection_name-shard_id-snapshot_name-1" [
  collection_name: string
  shard_id: int
  snapshot_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<time: float, status: record<error: string>, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)/shards/($shard_id)/snapshots/($snapshot_name)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get point
#
# GET /collections/{collection_name}/points/{id}
# operationId: get_point
export def "collections-points point" [
  collection_name: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
]: nothing -> record<usage: any, time: float, status: string, result: record<id: any, payload: any, vector: any, shard_key: any, order_value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get points
#
# POST /collections/{collection_name}/points
# operationId: get_points
export def "collections-points points-by-collection_name" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  ids: list # Look for points with ids
  --with-payload: any # Select which payload to return with the response. Default is true.
  --with-vector: any # Options for specifying which vector to include
]: any -> record<usage: any, time: float, status: string, result: table<id: any, payload: any, vector: any, shard_key: any, order_value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points" $qp)
  let body = {shard_key: $shard_key, ids: $ids, with_payload: $with_payload, with_vector: $with_vector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert points
#
# PUT /collections/{collection_name}/points
# operationId: upsert_points
# --batch shape: {ids: list, vectors: any, payloads?: list}
# --points item shape: {id: any, vector: any, payload?: any}
export def "collections-points points-by-collection_name-1" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  --batch: record # shape: {ids: list, vectors: any, payloads?: list}
  --shard-key: any
  --update-filter: any # Filter to apply when updating existing points. Only points matching this filter will be updated. Points that don't match will keep their current state. New points will be inserted regardless of the filter.
  --update-mode: any # Mode of the upsert operation: insert_only, upsert (default), update_only
  --points: list # item shape: {id: any, vector: any, payload?: any}
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points" $qp)
  let body = {batch: $batch, shard_key: $shard_key, update_filter: $update_filter, update_mode: $update_mode, points: $points} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete points
#
# POST /collections/{collection_name}/points/delete
# operationId: delete_points
# --filter shape: {should?: any, min_should?: any, must?: any, must_not?: any}
export def "collections-points-delete points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  --points: list
  --shard-key: any
  --filter: record # shape: {should?: any, min_should?: any, must?: any, must_not?: any}
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/delete" $qp)
  let body = {points: $points, shard_key: $shard_key, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update vectors
#
# PUT /collections/{collection_name}/points/vectors
# operationId: update_vectors
# --points item shape: {id: any, vector: any}
export def "collections-points-vectors vectors" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  points: list # Points with named vectors — item shape: {id: any, vector: any}
  --shard-key: any
  --update-filter: any
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/vectors" $qp)
  let body = {points: $points, shard_key: $shard_key, update_filter: $update_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete vectors
#
# POST /collections/{collection_name}/points/vectors/delete
# operationId: delete_vectors
export def "collections-points-vectors-delete vectors" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  --points: list # Deletes values from each point in this list (nullable)
  --filter: any # Deletes values from points that satisfy this filter condition
  vector: list # Vector names
  --shard-key: any
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/vectors/delete" $qp)
  let body = {points: $points, filter: $filter, vector: $vector, shard_key: $shard_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set payload
#
# POST /collections/{collection_name}/points/payload
# operationId: set_payload
export def "collections-points-payload payload-by-collection_name" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  payload: record # e.g. {city: London, color: green}
  --points: list # Assigns payload to each point in this list (nullable)
  --filter: any # Assigns payload to each point that satisfy this filter condition
  --shard-key: any
  --key: string # Assigns payload to each point that satisfy this path of property (nullable)
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/payload" $qp)
  let body = {payload: $payload, points: $points, filter: $filter, shard_key: $shard_key, key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Overwrite payload
#
# PUT /collections/{collection_name}/points/payload
# operationId: overwrite_payload
export def "collections-points-payload payload-by-collection_name-1" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  payload: record # e.g. {city: London, color: green}
  --points: list # Assigns payload to each point in this list (nullable)
  --filter: any # Assigns payload to each point that satisfy this filter condition
  --shard-key: any
  --key: string # Assigns payload to each point that satisfy this path of property (nullable)
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/payload" $qp)
  let body = {payload: $payload, points: $points, filter: $filter, shard_key: $shard_key, key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete payload
#
# POST /collections/{collection_name}/points/payload/delete
# operationId: delete_payload
export def "collections-points-payload-delete payload" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  keys: list # List of payload keys to remove from payload
  --points: list # Deletes values from each point in this list (nullable)
  --filter: any # Deletes values from points that satisfy this filter condition
  --shard-key: any
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/payload/delete" $qp)
  let body = {keys: $keys, points: $points, filter: $filter, shard_key: $shard_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clear payload
#
# POST /collections/{collection_name}/points/payload/clear
# operationId: clear_payload
# --filter shape: {should?: any, min_should?: any, must?: any, must_not?: any}
export def "collections-points-payload-clear payload" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  --points: list
  --shard-key: any
  --filter: record # shape: {should?: any, min_should?: any, must?: any, must_not?: any}
]: any -> record<usage: any, time: float, status: string, result: record<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/payload/clear" $qp)
  let body = {points: $points, shard_key: $shard_key, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch update points
#
# POST /collections/{collection_name}/points/batch
# operationId: batch_update
export def "collections-points-batch update" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool> # If true, wait for changes to actually happen
  --ordering: string@ordering-completer # define ordering guarantees for the operation
  --timeout: int # Timeout for the operation
  operations: list
]: any -> record<usage: any, time: float, status: string, result: table<operation_id: int, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/batch" $qp)
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Scroll points
#
# POST /collections/{collection_name}/points/scroll
# operationId: scroll_points
export def "collections-points-scroll points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  --offset: any # Start ID to read points from.
  --limit: int # Page size. Default: 10 (nullable, format: uint)
  --filter: any # Look only for points which satisfies this conditions. If not provided - all points.
  --with-payload: any # Select which payload to return with the response. Default is true.
  --with-vector: any # Options for specifying which vector to include
  --order-by: any # Order the records by a payload field.
]: any -> record<usage: any, time: float, status: string, result: record<points: list<record>, next_page_offset: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/scroll" $qp)
  let body = {shard_key: $shard_key, offset: $offset, limit: $limit, filter: $filter, with_payload: $with_payload, with_vector: $with_vector, order_by: $order_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search points
#
# POST /collections/{collection_name}/points/search
# DEPRECATED
# operationId: search_points
@deprecated
export def "collections-points-search points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  vector: any # Vector data separator for named and unnamed modes Unnamed mode:  { "vector": [1.0, 2.0, 3.0] }  or named mode:  { "vector": { "vector": [1.0, 2.0, 3.0], "name": "image-embeddings" } }
  --filter: any # Look only for points which satisfies this conditions
  --params: any # Additional search params
  limit: int # Max number of result to return (format: uint)
  --offset: int # Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues. (nullable, format: uint)
  --with-payload: any # Select which payload to return with the response. Default is false.
  --with-vector: any # Options for specifying which vectors to include into response. Default is false.
  --score-threshold: float # Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned. (nullable, format: float)
]: any -> record<usage: any, time: float, status: string, result: table<id: any, version: int, score: float, payload: any, vector: any, shard_key: any, order_value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/search" $qp)
  let body = {shard_key: $shard_key, vector: $vector, filter: $filter, params: $params, limit: $limit, offset: $offset, with_payload: $with_payload, with_vector: $with_vector, score_threshold: $score_threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search batch points
#
# POST /collections/{collection_name}/points/search/batch
# DEPRECATED
# operationId: search_batch_points
# --searches item shape: {shard_key?: any, vector: any, filter?: any, params?: any, limit: int, offset?: int, with_payload?: any, with_vector?: any, score_threshold?: float}
@deprecated
export def "collections-points-search-batch points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  searches: list # item shape: {shard_key?: any, vector: any, filter?: any, params?: any, limit: int, offset?: int, with_payload?: any, with_vector?: any, score_threshold?: float}
]: any -> record<usage: any, time: float, status: string, result: list<list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/search/batch" $qp)
  let body = {searches: $searches} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search point groups
#
# POST /collections/{collection_name}/points/search/groups
# DEPRECATED
# operationId: search_point_groups
@deprecated
export def "collections-points-search-groups groups" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  vector: any # Vector data separator for named and unnamed modes Unnamed mode:  { "vector": [1.0, 2.0, 3.0] }  or named mode:  { "vector": { "vector": [1.0, 2.0, 3.0], "name": "image-embeddings" } }
  --filter: any # Look only for points which satisfies this conditions
  --params: any # Additional search params
  --with-payload: any # Select which payload to return with the response. Default is false.
  --with-vector: any # Options for specifying which vectors to include into response. Default is false.
  --score-threshold: float # Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned. (nullable, format: float)
  group_by: string # Payload field to group by, must be a string or number field. If the field contains more than 1 value, all values will be used for grouping. One point can be in multiple groups.
  group_size: int # Maximum amount of points to return per group (format: uint32)
  limit: int # Maximum amount of groups to return (format: uint32)
  --with-lookup: any # Look for points in another collection using the group ids
]: any -> record<usage: any, time: float, status: string, result: record<groups: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/search/groups" $qp)
  let body = {shard_key: $shard_key, vector: $vector, filter: $filter, params: $params, with_payload: $with_payload, with_vector: $with_vector, score_threshold: $score_threshold, group_by: $group_by, group_size: $group_size, limit: $limit, with_lookup: $with_lookup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recommend points
#
# POST /collections/{collection_name}/points/recommend
# DEPRECATED
# operationId: recommend_points
@deprecated
export def "collections-points-recommend points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  --positive: list # Look for vectors closest to those (default: [])
  --negative: list # Try to avoid vectors like this (default: [])
  --strategy: any # How to use positive and negative examples to find the results
  --filter: any # Look only for points which satisfies this conditions
  --params: any # Additional search params
  limit: int # Max number of result to return (format: uint)
  --offset: int # Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues. (nullable, format: uint)
  --with-payload: any # Select which payload to return with the response. Default is false.
  --with-vector: any # Options for specifying which vectors to include into response. Default is false.
  --score-threshold: float # Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned. (nullable, format: float)
  --using: any # Define which vector to use for recommendation, if not specified - try to use default vector
  --lookup-from: any # The location used to lookup vectors. If not specified - use current collection. Note: the other collection should have the same vector size as the current collection
]: any -> record<usage: any, time: float, status: string, result: table<id: any, version: int, score: float, payload: any, vector: any, shard_key: any, order_value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/recommend" $qp)
  let body = {shard_key: $shard_key, positive: $positive, negative: $negative, strategy: $strategy, filter: $filter, params: $params, limit: $limit, offset: $offset, with_payload: $with_payload, with_vector: $with_vector, score_threshold: $score_threshold, using: $using, lookup_from: $lookup_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recommend batch points
#
# POST /collections/{collection_name}/points/recommend/batch
# DEPRECATED
# operationId: recommend_batch_points
# --searches item shape: {shard_key?: any, positive?: list, negative?: list, strategy?: any, filter?: any, params?: any, limit: int, offset?: int, with_payload?: any, with_vector?: any, score_threshold?: float, using?: any, lookup_from?: any}
@deprecated
export def "collections-points-recommend-batch points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  searches: list # item shape: {shard_key?: any, positive?: list, negative?: list, strategy?: any, filter?: any, params?: any, limit: int, offset?: int, with_payload?: any, with_vector?: any, score_threshold?: float, using?: any, lookup_from?: any}
]: any -> record<usage: any, time: float, status: string, result: list<list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/recommend/batch" $qp)
  let body = {searches: $searches} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recommend point groups
#
# POST /collections/{collection_name}/points/recommend/groups
# DEPRECATED
# operationId: recommend_point_groups
@deprecated
export def "collections-points-recommend-groups groups" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  --positive: list # Look for vectors closest to those (default: [])
  --negative: list # Try to avoid vectors like this (default: [])
  --strategy: any # How to use positive and negative examples to find the results
  --filter: any # Look only for points which satisfies this conditions
  --params: any # Additional search params
  --with-payload: any # Select which payload to return with the response. Default is false.
  --with-vector: any # Options for specifying which vectors to include into response. Default is false.
  --score-threshold: float # Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned. (nullable, format: float)
  --using: any # Define which vector to use for recommendation, if not specified - try to use default vector
  --lookup-from: any # The location used to lookup vectors. If not specified - use current collection. Note: the other collection should have the same vector size as the current collection
  group_by: string # Payload field to group by, must be a string or number field. If the field contains more than 1 value, all values will be used for grouping. One point can be in multiple groups.
  group_size: int # Maximum amount of points to return per group (format: uint32)
  limit: int # Maximum amount of groups to return (format: uint32)
  --with-lookup: any # Look for points in another collection using the group ids
]: any -> record<usage: any, time: float, status: string, result: record<groups: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/recommend/groups" $qp)
  let body = {shard_key: $shard_key, positive: $positive, negative: $negative, strategy: $strategy, filter: $filter, params: $params, with_payload: $with_payload, with_vector: $with_vector, score_threshold: $score_threshold, using: $using, lookup_from: $lookup_from, group_by: $group_by, group_size: $group_size, limit: $limit, with_lookup: $with_lookup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Discover points
#
# POST /collections/{collection_name}/points/discover
# DEPRECATED
# operationId: discover_points
# --context item shape: {positive: any, negative: any}
@deprecated
export def "collections-points-discover points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  --target: any # Look for vectors closest to this.  When using the target (with or without context), the integer part of the score represents the rank with respect to the context, while the decimal part of the score relates to the distance to the target.
  --context: list # Pairs of { positive, negative } examples to constrain the search.  When using only the context (without a target), a special search - called context search - is performed where pairs of points are used to generate a loss that guides the search towards the zone where most positive examples overlap. This means that the score minimizes the scenario of finding a point closer to a negative than to a positive part of a pair.  Since the score of a context relates to loss, the maximum score a point can get is 0.0, and it becomes normal that many points can have a score of 0.0.  For discovery search (when including a target), the context part of the score for each pair is calculated +1 if the point is closer to a positive than to a negative part of a pair, and -1 otherwise. (nullable) — item shape: {positive: any, negative: any}
  --filter: any # Look only for points which satisfies this conditions
  --params: any # Additional search params
  limit: int # Max number of result to return (format: uint)
  --offset: int # Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues. (nullable, format: uint)
  --with-payload: any # Select which payload to return with the response. Default is false.
  --with-vector: any # Options for specifying which vectors to include into response. Default is false.
  --using: any # Define which vector to use for recommendation, if not specified - try to use default vector
  --lookup-from: any # The location used to lookup vectors. If not specified - use current collection. Note: the other collection should have the same vector size as the current collection
]: any -> record<usage: any, time: float, status: string, result: table<id: any, version: int, score: float, payload: any, vector: any, shard_key: any, order_value: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/discover" $qp)
  let body = {shard_key: $shard_key, target: $target, context: $context, filter: $filter, params: $params, limit: $limit, offset: $offset, with_payload: $with_payload, with_vector: $with_vector, using: $using, lookup_from: $lookup_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Discover batch points
#
# POST /collections/{collection_name}/points/discover/batch
# DEPRECATED
# operationId: discover_batch_points
# --searches item shape: {shard_key?: any, target?: any, context?: list, filter?: any, params?: any, limit: int, offset?: int, with_payload?: any, with_vector?: any, using?: any, lookup_from?: any}
@deprecated
export def "collections-points-discover-batch points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  searches: list # item shape: {shard_key?: any, target?: any, context?: list, filter?: any, params?: any, limit: int, offset?: int, with_payload?: any, with_vector?: any, using?: any, lookup_from?: any}
]: any -> record<usage: any, time: float, status: string, result: list<list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/discover/batch" $qp)
  let body = {searches: $searches} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Count points
#
# POST /collections/{collection_name}/points/count
# operationId: count_points
export def "collections-points-count points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  --filter: any # Look only for points which satisfies this conditions
  --exact: oneof<nothing, bool> # If true, count exact number of points. If false, count approximate number of points faster. Approximate count might be unreliable during the indexing process. Default: true (default: true)
]: any -> record<usage: any, time: float, status: string, result: record<count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/count" $qp)
  let body = {shard_key: $shard_key, filter: $filter, exact: $exact} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Facet a payload key with a given filter.
#
# POST /collections/{collection_name}/facet
# operationId: facet
export def "collections-facet facet" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any
  key: string # Payload key to use for faceting.
  --limit: int # Max number of hits to return. Default is 10. (nullable, format: uint)
  --filter: any # Filter conditions - only consider points that satisfy these conditions.
  --exact: oneof<nothing, bool> # Whether to do a more expensive exact count for each of the values in the facet. Default is false. (nullable)
]: any -> record<usage: any, time: float, status: string, result: record<hits: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/facet" $qp)
  let body = {shard_key: $shard_key, key: $key, limit: $limit, filter: $filter, exact: $exact} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query points
#
# POST /collections/{collection_name}/points/query
# operationId: query_points
export def "collections-points-query points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any
  --prefetch: any # Sub-requests to perform first. If present, the query will be performed on the results of the prefetch(es).
  --body-query: any # Query to perform. If missing without prefetches, returns points ordered by their IDs.
  --using: string # Define which vector name to use for querying. If missing, the default vector is used. (nullable)
  --filter: any # Filter conditions - return only those points that satisfy the specified conditions.
  --params: any # Search params for when there is no prefetch
  --score-threshold: float # Return points with scores better than this threshold. (nullable, format: float)
  --limit: int # Max number of points to return. Default is 10. (nullable, format: uint)
  --offset: int # Offset of the result. Skip this many points. Default is 0 (nullable, format: uint)
  --with-vector: any # Options for specifying which vectors to include into the response. Default is false.
  --with-payload: any # Options for specifying which payload to include or not. Default is false.
  --lookup-from: any # The location to use for IDs lookup, if not specified - use the current collection and the 'using' vector Note: the other collection vectors should have the same vector size as the 'using' vector in the current collection
]: any -> record<usage: any, time: float, status: string, result: record<points: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/query" $qp)
  let body = {shard_key: $shard_key, prefetch: $prefetch, query: $body_query, using: $using, filter: $filter, params: $params, score_threshold: $score_threshold, limit: $limit, offset: $offset, with_vector: $with_vector, with_payload: $with_payload, lookup_from: $lookup_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query points in batch
#
# POST /collections/{collection_name}/points/query/batch
# operationId: query_batch_points
# --searches item shape: {shard_key?: any, prefetch?: any, query?: any, using?: string, filter?: any, params?: any, score_threshold?: float, limit?: int, offset?: int, with_vector?: any, with_payload?: any, lookup_from?: any}
export def "collections-points-query-batch points" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  searches: list # item shape: {shard_key?: any, prefetch?: any, query?: any, using?: string, filter?: any, params?: any, score_threshold?: float, limit?: int, offset?: int, with_vector?: any, with_payload?: any, lookup_from?: any}
]: any -> record<usage: any, time: float, status: string, result: table<points: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/query/batch" $qp)
  let body = {searches: $searches} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query points, grouped by a given payload field
#
# POST /collections/{collection_name}/points/query/groups
# operationId: query_points_groups
export def "collections-points-query-groups groups" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any
  --prefetch: any # Sub-requests to perform first. If present, the query will be performed on the results of the prefetch(es).
  --body-query: any # Query to perform. If missing without prefetches, returns points ordered by their IDs.
  --using: string # Define which vector name to use for querying. If missing, the default vector is used. (nullable)
  --filter: any # Filter conditions - return only those points that satisfy the specified conditions.
  --params: any # Search params for when there is no prefetch
  --score-threshold: float # Return points with scores better than this threshold. (nullable, format: float)
  --with-vector: any # Options for specifying which vectors to include into the response. Default is false.
  --with-payload: any # Options for specifying which payload to include or not. Default is false.
  --lookup-from: any # The location to use for IDs lookup, if not specified - use the current collection and the 'using' vector Note: the other collection vectors should have the same vector size as the 'using' vector in the current collection
  group_by: string # Payload field to group by, must be a string or number field. If the field contains more than 1 value, all values will be used for grouping. One point can be in multiple groups.
  --group-size: int # Maximum amount of points to return per group. Default is 3. (nullable, format: uint)
  --limit: int # Maximum amount of groups to return. Default is 10. (nullable, format: uint)
  --with-lookup: any # Look for points in another collection using the group ids
]: any -> record<usage: any, time: float, status: string, result: record<groups: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/query/groups" $qp)
  let body = {shard_key: $shard_key, prefetch: $prefetch, query: $body_query, using: $using, filter: $filter, params: $params, score_threshold: $score_threshold, with_vector: $with_vector, with_payload: $with_payload, lookup_from: $lookup_from, group_by: $group_by, group_size: $group_size, limit: $limit, with_lookup: $with_lookup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search points matrix distance pairs
#
# POST /collections/{collection_name}/points/search/matrix/pairs
# operationId: search_matrix_pairs
export def "collections-points-search-matrix-pairs pairs" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  --filter: any # Look only for points which satisfies this conditions
  --sample: int # How many points to select and search within. Default is 10. (nullable, format: uint)
  --limit: int # How many neighbours per sample to find. Default is 3. (nullable, format: uint)
  --using: string # Define which vector name to use for querying. If missing, the default vector is used. (nullable)
]: any -> record<usage: any, time: float, status: string, result: record<pairs: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/search/matrix/pairs" $qp)
  let body = {shard_key: $shard_key, filter: $filter, sample: $sample, limit: $limit, using: $using} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search points matrix distance offsets
#
# POST /collections/{collection_name}/points/search/matrix/offsets
# operationId: search_matrix_offsets
export def "collections-points-search-matrix-offsets offsets" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string # Define read consistency guarantees for the operation
  --timeout: int # If set, overrides global timeout for this request. Unit is seconds.
  --shard-key: any # Specify in which shards to look for the points, if not specified - look in all shards
  --filter: any # Look only for points which satisfies this conditions
  --sample: int # How many points to select and search within. Default is 10. (nullable, format: uint)
  --limit: int # How many neighbours per sample to find. Default is 3. (nullable, format: uint)
  --using: string # Define which vector name to use for querying. If missing, the default vector is used. (nullable)
]: any -> record<usage: any, time: float, status: string, result: record<offsets_row: list<int>, offsets_col: list<int>, scores: list<float>, ids: list<any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency" $consistency "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collection_name)/points/search/matrix/offsets" $qp)
  let body = {shard_key: $shard_key, filter: $filter, sample: $sample, limit: $limit, using: $using} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
