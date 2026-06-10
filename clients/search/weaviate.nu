# Auto-generated client for Weaviate REST API v1.38.0-rc.1
# Source: https://raw.githubusercontent.com/weaviate/weaviate/main/openapi-specs/schema.json
# Auth: --token flag or $env.WEAVIATE_REST_API_TOKEN

const BASE_URL = "https://localhost/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEAVIATE_REST_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://localhost/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["COPY" "MOVE"] }
def action-completer [] { ["assign_and_revoke_groups" "assign_and_revoke_users" "create_aliases" "create_collections" "create_data" "create_mcp" "create_replicate" "create_roles" "create_tenants" "create_users" "delete_aliases" "delete_collections" "delete_data" "delete_replicate" "delete_roles" "delete_tenants" "delete_users" "manage_backups" "manage_namespaces" "read_aliases" "read_cluster" "read_collections" "read_data" "read_groups" "read_mcp" "read_nodes" "read_replicate" "read_roles" "read_tenants" "read_users" "update_aliases" "update_collections" "update_data" "update_mcp" "update_replicate" "update_roles" "update_tenants" "update_users"] }
def userType-completer [] { ["db" "oidc"] }
def groupType-completer [] { ["oidc"] }
def tokenization-completer [] { ["field" "gse" "gse_ch" "kagome_ja" "kagome_kr" "lowercase" "trigram" "whitespace" "word"] }
def order-completer [] { ["asc" "desc"] }
def file-format-completer [] { ["parquet"] }
def status-completer [] { ["completed" "failed" "running"] }
def accept-completer [] { ["application/json" "text/event-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api weaviateroot" } } | get name | first)
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

# List available endpoints
#
# GET /
# operationId: weaviate.root
export def "api weaviateroot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<links: table<href: string, rel: string, name: string, documentationHref: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check application liveness
#
# GET /.well-known/live
# operationId: weaviate.wellknown.liveness
export def "well-known-live weaviatewellknownliveness" [
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
  let full_url = (build-url $base "/.well-known/live")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check application readiness
#
# GET /.well-known/ready
# operationId: weaviate.wellknown.readiness
export def "well-known-ready weaviatewellknownreadiness" [
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
  let full_url = (build-url $base "/.well-known/ready")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OIDC configuration
#
# GET /.well-known/openid-configuration
export def "well-known-openid-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<href: string, clientId: string, scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/openid-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate a replica movement
#
# POST /replication/replicate
# operationId: replicate
export def "replication-replicate replicate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sourceNode: string # The name of the Weaviate node currently hosting the shard replica that needs to be moved or copied.
  targetNode: string # The name of the Weaviate node where the new shard replica will be created as part of the movement or copy operation.
  collection: string # The name of the collection to which the target shard belongs.
  shard: string # The name of the shard whose replica is to be moved or copied.
  --type: string@type-completer # Specifies the type of replication operation to perform. `COPY` creates a new replica on the target node while keeping the source replica. `MOVE` creates a new replica on the target node and then removes the source replica upon successful completion. Defaults to `COPY` if omitted. (default: COPY)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/replication/replicate")
  let body = {sourceNode: $sourceNode, targetNode: $targetNode, collection: $collection, shard: $shard, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all replication operations
#
# DELETE /replication/replicate
# operationId: deleteAllReplications
export def "replication-replicate delete" [
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
  let full_url = (build-url $base "/replication/replicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Force delete replication operations
#
# POST /replication/replicate/force-delete
# operationId: forceDeleteReplications
export def "replication-replicate-force-delete forceDeleteReplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier (ID) of the replication operation to be forcefully deleted. (format: uuid)
  --collection: string # The name of the collection to which the shard being replicated belongs.
  --shard: string # The identifier of the shard involved in the replication operations.
  --node: string # The name of the target node where the replication operations are registered.
  --dryRun: string@bool-completer # If true, the operation will not actually delete anything but will return the expected outcome of the deletion. (default: false)
]: any -> record<deleted: list<string>, dryRun: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/replication/replicate/force-delete")
  let body = {id: $id, collection: $collection, shard: $shard, node: $node, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a replication operation
#
# GET /replication/replicate/{id}
# operationId: replicationDetails
export def "replication-replicate replicationDetails" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeHistory: string@bool-completer # Whether to include the history of the replication operation.
]: nothing -> record<id: string, shard: string, collection: string, sourceNode: string, targetNode: string, type: string, uncancelable: bool, scheduledForCancel: bool, scheduledForDelete: bool, status: record<state: string, whenStartedUnixMs: int, errors: list<record>>, statusHistory: table<state: string, whenStartedUnixMs: int, errors: list>, whenStartedUnixMs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeHistory" $includeHistory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/replication/replicate/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a replication operation
#
# DELETE /replication/replicate/{id}
# operationId: deleteReplication
export def "replication-replicate delete-by-id" [
  id: string
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
  let full_url = (build-url $base $"/replication/replicate/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List replication operations
#
# GET /replication/replicate/list
# operationId: listReplication
export def "replication-replicate-list listReplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetNode: string # The name of the target node to get details for.
  --collection: string # The name of the collection to get details for.
  --shard: string # The shard to get details for.
  --includeHistory: string@bool-completer # Whether to include the history of the replication operation.
]: nothing -> table<id: string, shard: string, collection: string, sourceNode: string, targetNode: string, type: string, uncancelable: bool, scheduledForCancel: bool, scheduledForDelete: bool, status: record<state: string, whenStartedUnixMs: int, errors: list>, statusHistory: list<record>, whenStartedUnixMs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetNode" $targetNode "scalar") (serialize-qp "collection" $collection "scalar") (serialize-qp "shard" $shard "scalar") (serialize-qp "includeHistory" $includeHistory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/replication/replicate/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a replication operation
#
# POST /replication/replicate/{id}/cancel
# operationId: cancelReplication
export def "replication-replicate-cancel cancelReplication" [
  id: string
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
  let full_url = (build-url $base $"/replication/replicate/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sharding state
#
# GET /replication/sharding-state
# operationId: getCollectionShardingState
export def "replication-sharding-state get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collection: string # The collection name to get the sharding state for.
  --shard: string # The shard to get the sharding state for.
]: nothing -> record<shardingState: record<collection: string, shards: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collection" $collection "scalar") (serialize-qp "shard" $shard "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/replication/sharding-state" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get replication scale plan
#
# GET /replication/scale
# operationId: getReplicationScalePlan
export def "replication-scale get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collection: string # The collection name to get the scaling plan for.
  --replicationFactor: int # The desired replication factor to scale to. Must be a positive integer greater than zero.
]: nothing -> record<planId: string, collection: string, shardScaleActions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collection" $collection "scalar") (serialize-qp "replicationFactor" $replicationFactor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/replication/scale" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply replication scaling plan
#
# POST /replication/scale
# operationId: applyReplicationScalePlan
export def "replication-scale applyReplicationScalePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  planId: string # A unique identifier for this replication scaling plan, useful for tracking and auditing purposes. (format: uuid)
  collection: string # The name of the collection to which this replication scaling plan applies.
  shardScaleActions: record # A mapping of shard names to their corresponding scaling actions. Each key corresponds to a shard name, and its value defines which nodes should be removed and which should be added for that shard. If a source node listed for an addition is also in 'removeNodes' for the same shard, that addition is treated as a move operation. Such a node can appear only once as a source in that shard. Otherwise, if the source node is not being removed, it represents a copy operation and can be referenced multiple times as a source for additions.
]: any -> record<operationIds: list<string>, planId: string, collection: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/replication/scale")
  let body = {planId: $planId, collection: $collection, shardScaleActions: $shardScaleActions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get current user info
#
# GET /users/own-info
# operationId: getOwnInfo
export def "users-own-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<groups: list<string>, roles: table<name: string, permissions: list>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/own-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all users
#
# GET /users/db
# operationId: listAllUsers
export def "users-db listAllUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeLastUsedTime: string@bool-completer # Whether to include the last time the users were utilized. (default: false)
]: nothing -> table<roles: list<string>, userId: string, dbUserType: string, active: bool, createdAt: string, apiKeyFirstLetters: string, lastUsedAt: string, namespace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeLastUsedTime" $includeLastUsedTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/db" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user info
#
# GET /users/db/{user_id}
# operationId: getUserInfo
export def "users-db get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeLastUsedTime: string@bool-completer # Whether to include the last used time of the given user (default: false)
]: nothing -> record<roles: list<string>, userId: string, dbUserType: string, active: bool, createdAt: string, apiKeyFirstLetters: string, lastUsedAt: string, namespace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeLastUsedTime" $includeLastUsedTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/db/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /users/db/{user_id}
# operationId: createUser
export def "users-db createUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --import: string@bool-completer # EXPERIMENTAL, DONT USE. THIS WILL BE REMOVED AGAIN. - import api key from static user (default: false)
  --createTime: string # EXPERIMENTAL, DONT USE. THIS WILL BE REMOVED AGAIN. - set the given time as creation time (format: date-time)
]: any -> record<apikey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/db/($user_id)")
  let body = {import: $import, createTime: $createTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /users/db/{user_id}
# operationId: deleteUser
export def "users-db delete" [
  user_id: string
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
  let full_url = (build-url $base $"/users/db/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate API key of a user
#
# POST /users/db/{user_id}/rotate-key
# operationId: rotateUserApiKey
export def "users-db-rotate-key rotateUserApiKey" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apikey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/db/($user_id)/rotate-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate a user
#
# POST /users/db/{user_id}/activate
# operationId: activateUser
export def "users-db-activate activateUser" [
  user_id: string
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
  let full_url = (build-url $base $"/users/db/($user_id)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate a user
#
# POST /users/db/{user_id}/deactivate
# operationId: deactivateUser
export def "users-db-deactivate deactivateUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --revoke-key: string@bool-completer # Whether the API key should be revoked when deactivating the user. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/db/($user_id)/deactivate")
  let body = {revoke_key: $revoke_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all roles
#
# GET /authz/roles
# operationId: getRoles
export def "authz-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, permissions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authz/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new role
#
# POST /authz/roles
# operationId: createRole
# --permissions item shape: {backups?: record, data?: record, nodes?: record, users?: record, groups?: record, tenants?: record, roles?: record, collections?: record, replicate?: record, aliases?: record, namespaces?: record, action: "manage_backups"|"read_cluster"|"create_data"|"read_data"|"update_data"|"delete_data"|"read_nodes"|"create_roles"|"read_roles"|"update_roles"|"delete_roles"|"create_collections"|"read_collections"|"update_collections"|"delete_collections"|"assign_and_revoke_users"|"create_users"|"read_users"|"update_users"|"delete_users"|"create_tenants"|"read_tenants"|"update_tenants"|"delete_tenants"|"create_replicate"|"read_replicate"|"update_replicate"|"delete_replicate"|"create_aliases"|"read_aliases"|"update_aliases"|"delete_aliases"|"assign_and_revoke_groups"|"read_groups"|"create_mcp"|"read_mcp"|"update_mcp"|"manage_namespaces"}
export def "authz-roles createRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name (ID) of the role.
  permissions: list # item shape: {backups?: record, data?: record, nodes?: record, users?: record, groups?: record, tenants?: record, roles?: record, collections?: record, replicate?: record, aliases?: record, namespaces?: record, action: "manage_backups"|"read_cluster"|"create_data"|"read_data"|"update_data"|"delete_data"|"read_nodes"|"create_roles"|"read_roles"|"update_roles"|"delete_roles"|"create_collections"|"read_collections"|"update_collections"|"delete_collections"|"assign_and_revoke_users"|"create_users"|"read_users"|"update_users"|"delete_users"|"create_tenants"|"read_tenants"|"update_tenants"|"delete_tenants"|"create_replicate"|"read_replicate"|"update_replicate"|"delete_replicate"|"create_aliases"|"read_aliases"|"update_aliases"|"delete_aliases"|"assign_and_revoke_groups"|"read_groups"|"create_mcp"|"read_mcp"|"update_mcp"|"manage_namespaces"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authz/roles")
  let body = {name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add permissions to a role
#
# POST /authz/roles/{id}/add-permissions
# operationId: addPermissions
# --permissions item shape: {backups?: record, data?: record, nodes?: record, users?: record, groups?: record, tenants?: record, roles?: record, collections?: record, replicate?: record, aliases?: record, namespaces?: record, action: "manage_backups"|"read_cluster"|"create_data"|"read_data"|"update_data"|"delete_data"|"read_nodes"|"create_roles"|"read_roles"|"update_roles"|"delete_roles"|"create_collections"|"read_collections"|"update_collections"|"delete_collections"|"assign_and_revoke_users"|"create_users"|"read_users"|"update_users"|"delete_users"|"create_tenants"|"read_tenants"|"update_tenants"|"delete_tenants"|"create_replicate"|"read_replicate"|"update_replicate"|"delete_replicate"|"create_aliases"|"read_aliases"|"update_aliases"|"delete_aliases"|"assign_and_revoke_groups"|"read_groups"|"create_mcp"|"read_mcp"|"update_mcp"|"manage_namespaces"}
export def "authz-roles-add-permissions addPermissions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissions: list # Permissions to be added to the role. — item shape: {backups?: record, data?: record, nodes?: record, users?: record, groups?: record, tenants?: record, roles?: record, collections?: record, replicate?: record, aliases?: record, namespaces?: record, action: "manage_backups"|"read_cluster"|"create_data"|"read_data"|"update_data"|"delete_data"|"read_nodes"|"create_roles"|"read_roles"|"update_roles"|"delete_roles"|"create_collections"|"read_collections"|"update_collections"|"delete_collections"|"assign_and_revoke_users"|"create_users"|"read_users"|"update_users"|"delete_users"|"create_tenants"|"read_tenants"|"update_tenants"|"delete_tenants"|"create_replicate"|"read_replicate"|"update_replicate"|"delete_replicate"|"create_aliases"|"read_aliases"|"update_aliases"|"delete_aliases"|"assign_and_revoke_groups"|"read_groups"|"create_mcp"|"read_mcp"|"update_mcp"|"manage_namespaces"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/roles/($id)/add-permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove permissions from a role
#
# POST /authz/roles/{id}/remove-permissions
# operationId: removePermissions
# --permissions item shape: {backups?: record, data?: record, nodes?: record, users?: record, groups?: record, tenants?: record, roles?: record, collections?: record, replicate?: record, aliases?: record, namespaces?: record, action: "manage_backups"|"read_cluster"|"create_data"|"read_data"|"update_data"|"delete_data"|"read_nodes"|"create_roles"|"read_roles"|"update_roles"|"delete_roles"|"create_collections"|"read_collections"|"update_collections"|"delete_collections"|"assign_and_revoke_users"|"create_users"|"read_users"|"update_users"|"delete_users"|"create_tenants"|"read_tenants"|"update_tenants"|"delete_tenants"|"create_replicate"|"read_replicate"|"update_replicate"|"delete_replicate"|"create_aliases"|"read_aliases"|"update_aliases"|"delete_aliases"|"assign_and_revoke_groups"|"read_groups"|"create_mcp"|"read_mcp"|"update_mcp"|"manage_namespaces"}
export def "authz-roles-remove-permissions removePermissions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissions: list # Permissions to remove from the role. — item shape: {backups?: record, data?: record, nodes?: record, users?: record, groups?: record, tenants?: record, roles?: record, collections?: record, replicate?: record, aliases?: record, namespaces?: record, action: "manage_backups"|"read_cluster"|"create_data"|"read_data"|"update_data"|"delete_data"|"read_nodes"|"create_roles"|"read_roles"|"update_roles"|"delete_roles"|"create_collections"|"read_collections"|"update_collections"|"delete_collections"|"assign_and_revoke_users"|"create_users"|"read_users"|"update_users"|"delete_users"|"create_tenants"|"read_tenants"|"update_tenants"|"delete_tenants"|"create_replicate"|"read_replicate"|"update_replicate"|"delete_replicate"|"create_aliases"|"read_aliases"|"update_aliases"|"delete_aliases"|"assign_and_revoke_groups"|"read_groups"|"create_mcp"|"read_mcp"|"update_mcp"|"manage_namespaces"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/roles/($id)/remove-permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a role
#
# GET /authz/roles/{id}
# operationId: getRole
export def "authz-roles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, permissions: table<backups: record, data: record, nodes: record, users: record, groups: record, tenants: record, roles: record, collections: record, replicate: record, aliases: record, namespaces: record, action: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a role
#
# DELETE /authz/roles/{id}
# operationId: deleteRole
export def "authz-roles delete" [
  id: string
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
  let full_url = (build-url $base $"/authz/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check whether a role possesses a permission
#
# POST /authz/roles/{id}/has-permission
# operationId: hasPermission
# --backups shape: {collection?: string}
# --data shape: {collection?: string, tenant?: string, object?: string}
# --nodes shape: {verbosity?: "verbose"|"minimal", collection?: string}
# --users shape: {users?: string}
# --groups shape: {group?: string, groupType?: "oidc"}
# --tenants shape: {collection?: string, tenant?: string}
# --roles shape: {role?: string, scope?: "all"|"match"}
# --collections shape: {collection?: string}
# --replicate shape: {collection?: string, shard?: string}
# --aliases shape: {collection?: string, alias?: string}
# --namespaces shape: {namespace?: string}
export def "authz-roles-has-permission hasPermission" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --backups: record # Resources applicable for backup actions. — shape: {collection?: string}
  --data: record # Resources applicable for data actions. — shape: {collection?: string, tenant?: string, object?: string}
  --nodes: record # Resources applicable for cluster actions. — shape: {verbosity?: "verbose"|"minimal", collection?: string}
  --users: record # Resources applicable for user actions. — shape: {users?: string}
  --groups: record # Resources applicable for group actions. — shape: {group?: string, groupType?: "oidc"}
  --tenants: record # Resources applicable for tenant actions. — shape: {collection?: string, tenant?: string}
  --roles: record # Resources applicable for role actions. — shape: {role?: string, scope?: "all"|"match"}
  --collections: record # Resources applicable for collection and/or tenant actions. — shape: {collection?: string}
  --replicate: record # resources applicable for replicate actions — shape: {collection?: string, shard?: string}
  --aliases: record # Resource definition for alias-related actions and permissions. Used to specify which aliases and collections can be accessed or modified. — shape: {collection?: string, alias?: string}
  --namespaces: record # Resources applicable for namespace actions. — shape: {namespace?: string}
  action: string@action-completer # Allowed actions in weaviate.
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/roles/($id)/has-permission")
  let body = {backups: $backups, data: $data, nodes: $nodes, users: $users, groups: $groups, tenants: $tenants, roles: $roles, collections: $collections, replicate: $replicate, aliases: $aliases, namespaces: $namespaces, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get users assigned to a role
#
# GET /authz/roles/{id}/users
# DEPRECATED
# operationId: getUsersForRoleDeprecated
@deprecated
export def "authz-roles-users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/roles/($id)/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users assigned to a role
#
# GET /authz/roles/{id}/user-assignments
# operationId: getUsersForRole
export def "authz-roles-user-assignments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<userId: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/roles/($id)/user-assignments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get groups that have a specific role assigned
#
# GET /authz/roles/{id}/group-assignments
# operationId: getGroupsForRole
export def "authz-roles-group-assignments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<groupId: string, groupType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/roles/($id)/group-assignments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get roles assigned to a user
#
# GET /authz/users/{id}/roles
# DEPRECATED
# operationId: getRolesForUserDeprecated
@deprecated
export def "authz-users-roles list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, permissions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/users/($id)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get roles assigned to a user
#
# GET /authz/users/{id}/roles/{userType}
# operationId: getRolesForUser
export def "authz-users-roles get" [
  id: string
  userType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeFullRoles: string@bool-completer # Whether to include detailed role information like its assigned permissions. (default: false)
]: nothing -> table<name: string, permissions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeFullRoles" $includeFullRoles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authz/users/($id)/roles/($userType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a role to a user
#
# POST /authz/users/{id}/assign
# operationId: assignRoleToUser
export def "authz-users-assign assignRoleToUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --roles: list # The roles that are assigned to the specified user.
  --userType: string@userType-completer # The type of the user. `db` users are managed by Weaviate, `oidc` users are managed by an external OIDC provider.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/users/($id)/assign")
  let body = {roles: $roles, userType: $userType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke a role from a user
#
# POST /authz/users/{id}/revoke
# operationId: revokeRoleFromUser
export def "authz-users-revoke revokeRoleFromUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --roles: list # The roles to revoke from the specified user.
  --userType: string@userType-completer # The type of the user. `db` users are managed by Weaviate, `oidc` users are managed by an external OIDC provider.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/users/($id)/revoke")
  let body = {roles: $roles, userType: $userType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a role to a group
#
# POST /authz/groups/{id}/assign
# operationId: assignRoleToGroup
export def "authz-groups-assign assignRoleToGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --roles: list # The roles to assign to the specified group.
  --groupType: string@groupType-completer # If the group contains OIDC or database users.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/groups/($id)/assign")
  let body = {roles: $roles, groupType: $groupType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke a role from a group
#
# POST /authz/groups/{id}/revoke
# operationId: revokeRoleFromGroup
export def "authz-groups-revoke revokeRoleFromGroup" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --roles: list # The roles to revoke from the specified group.
  --groupType: string@groupType-completer # If the group contains OIDC or database users.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/groups/($id)/revoke")
  let body = {roles: $roles, groupType: $groupType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get roles assigned to a specific group
#
# GET /authz/groups/{id}/roles/{groupType}
# operationId: getRolesForGroup
export def "authz-groups-roles get" [
  id: string
  groupType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeFullRoles: string@bool-completer # If true, the response will include the full role definitions with all associated permissions. If false, only role names are returned. (default: false)
]: nothing -> table<name: string, permissions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeFullRoles" $includeFullRoles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authz/groups/($id)/roles/($groupType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all groups of a specific type
#
# GET /authz/groups/{groupType}
# operationId: getGroups
export def "authz-groups get" [
  groupType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authz/groups/($groupType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List objects
#
# GET /objects
# operationId: objects.list
export def "objects objectslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # A threshold UUID of the objects to retrieve after, using an UUID-based ordering. This object is not part of the set. <br/><br/>Must be used with collection name (`class`), typically in conjunction with `limit`. <br/><br/>Note `after` cannot be used with `offset` or `sort`. <br/><br/>For a null value similar to offset=0, set an empty string in the request, i.e. `after=` or `after`.
  --offset: int # The starting index of the result window. Note `offset` will retrieve `offset+limit` results and return `limit` results from the object with index `offset` onwards. Limited by the value of `QUERY_MAXIMUM_RESULTS`. <br/><br/>Should be used in conjunction with `limit`. <br/><br/>Cannot be used with `after`. (format: int64, default: 0)
  --limit: int # The maximum number of items to be returned per page. The default is 25 unless set otherwise as an environment variable. (format: int64)
  --include: string # Include additional information, such as classification information. Allowed values include: `classification`, `vector` and `interpretation`.
  --qp-sort: string # Name(s) of the property to sort by - e.g. `city`, or `country,city`.
  --order: string # Order parameter to tell how to order (asc or desc) data within given field. Should be used in conjunction with `sort` parameter. If providing multiple `sort` values, provide multiple `order` values in corresponding order, e.g.: `sort=author_name,title&order=desc,asc`.
  --class: string # The collection from which to query objects.  <br/><br/>Note that if the collection name (`class`) is not provided, the response will not include any objects.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
]: nothing -> record<objects: table<class: string, vectorWeights: record, properties: record, id: string, creationTimeUnix: int, lastUpdateTimeUnix: int, vector: list, vectors: record, tenant: string, additional: record>, deprecations: table<id: string, status: string, apiType: string, msg: string, mitigation: string, sinceVersion: string, plannedRemovalVersion: string, removedIn: string, removedTime: string, sinceTime: string, locations: list>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "class" $class "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/objects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an object
#
# POST /objects
# operationId: objects.create
export def "objects objectscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --class: string # Name of the collection (class) the object belongs to.
  --vectorWeights: record # Allow custom overrides of vector weights as math expressions. E.g. `pancake`: `7` will set the weight for the word pancake to 7 in the vectorization, whereas `w * 3` would triple the originally calculated word. This is an open object, with OpenAPI Specification 3.0 this will be more detailed. See Weaviate docs for more info. In the future this will become a key/value (string/string) object.
  --properties: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --id: string # The UUID of the object. (format: uuid)
  --creationTimeUnix: int # (Response only) Timestamp of creation of this object in milliseconds since epoch UTC. (format: int64)
  --lastUpdateTimeUnix: int # (Response only) Timestamp of the last object update in milliseconds since epoch UTC. (format: int64)
  --vector: list # A vector representation of the object in the Contextionary. If provided at object creation, this wil take precedence over any vectorizer setting.
  --vectors: record # A map of named vectors for multi-vector representations.
  --tenant: string # The name of the tenant the object belongs to.
  --additional: record # (Response only) Additional meta information about a single object.
]: any -> record<class: string, vectorWeights: record, properties: record, id: string, creationTimeUnix: int, lastUpdateTimeUnix: int, vector: list<float>, vectors: record, tenant: string, additional: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/objects" $qp)
  let body = {class: $class, vectorWeights: $vectorWeights, properties: $properties, id: $id, creationTimeUnix: $creationTimeUnix, lastUpdateTimeUnix: $lastUpdateTimeUnix, vector: $vector, vectors: $vectors, tenant: $tenant, additional: $additional} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an object
#
# DELETE /objects/{id}
# DEPRECATED
# operationId: objects.delete
@deprecated
export def "objects objectsdelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an object
#
# GET /objects/{id}
# DEPRECATED
# operationId: objects.get
@deprecated
export def "objects objectsget" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Include additional information, such as classification information. Allowed values include: `classification`, `vector` and `interpretation`.
]: nothing -> record<class: string, vectorWeights: record, properties: record, id: string, creationTimeUnix: int, lastUpdateTimeUnix: int, vector: list<float>, vectors: record, tenant: string, additional: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch an object
#
# PATCH /objects/{id}
# DEPRECATED
# operationId: objects.patch
@deprecated
export def "objects objectspatch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --class: string # Name of the collection (class) the object belongs to.
  --vectorWeights: record # Allow custom overrides of vector weights as math expressions. E.g. `pancake`: `7` will set the weight for the word pancake to 7 in the vectorization, whereas `w * 3` would triple the originally calculated word. This is an open object, with OpenAPI Specification 3.0 this will be more detailed. See Weaviate docs for more info. In the future this will become a key/value (string/string) object.
  --properties: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --body-id: string # The UUID of the object. (format: uuid)
  --creationTimeUnix: int # (Response only) Timestamp of creation of this object in milliseconds since epoch UTC. (format: int64)
  --lastUpdateTimeUnix: int # (Response only) Timestamp of the last object update in milliseconds since epoch UTC. (format: int64)
  --vector: list # A vector representation of the object in the Contextionary. If provided at object creation, this wil take precedence over any vectorizer setting.
  --vectors: record # A map of named vectors for multi-vector representations.
  --tenant: string # The name of the tenant the object belongs to.
  --additional: record # (Response only) Additional meta information about a single object.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($id)" $qp)
  let body = {class: $class, vectorWeights: $vectorWeights, properties: $properties, id: $body_id, creationTimeUnix: $creationTimeUnix, lastUpdateTimeUnix: $lastUpdateTimeUnix, vector: $vector, vectors: $vectors, tenant: $tenant, additional: $additional} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an object
#
# PUT /objects/{id}
# DEPRECATED
# operationId: objects.update
@deprecated
export def "objects objectsupdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --class: string # Name of the collection (class) the object belongs to.
  --vectorWeights: record # Allow custom overrides of vector weights as math expressions. E.g. `pancake`: `7` will set the weight for the word pancake to 7 in the vectorization, whereas `w * 3` would triple the originally calculated word. This is an open object, with OpenAPI Specification 3.0 this will be more detailed. See Weaviate docs for more info. In the future this will become a key/value (string/string) object.
  --properties: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --body-id: string # The UUID of the object. (format: uuid)
  --creationTimeUnix: int # (Response only) Timestamp of creation of this object in milliseconds since epoch UTC. (format: int64)
  --lastUpdateTimeUnix: int # (Response only) Timestamp of the last object update in milliseconds since epoch UTC. (format: int64)
  --vector: list # A vector representation of the object in the Contextionary. If provided at object creation, this wil take precedence over any vectorizer setting.
  --vectors: record # A map of named vectors for multi-vector representations.
  --tenant: string # The name of the tenant the object belongs to.
  --additional: record # (Response only) Additional meta information about a single object.
]: any -> record<class: string, vectorWeights: record, properties: record, id: string, creationTimeUnix: int, lastUpdateTimeUnix: int, vector: list<float>, vectors: record, tenant: string, additional: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($id)" $qp)
  let body = {class: $class, vectorWeights: $vectorWeights, properties: $properties, id: $body_id, creationTimeUnix: $creationTimeUnix, lastUpdateTimeUnix: $lastUpdateTimeUnix, vector: $vector, vectors: $vectors, tenant: $tenant, additional: $additional} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if an object exists
#
# HEAD /objects/{id}
# DEPRECATED
# operationId: objects.head
@deprecated
export def "objects objectshead" [
  id: string
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
  let full_url = (build-url $base $"/objects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an object
#
# GET /objects/{className}/{id}
# operationId: objects.class.get
export def "objects objectsclassget" [
  className: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Include additional information, such as classification information. Allowed values include: `classification`, `vector` and `interpretation`.
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --node-name: string # The target node which should fulfill the request.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
]: nothing -> record<class: string, vectorWeights: record, properties: record, id: string, creationTimeUnix: int, lastUpdateTimeUnix: int, vector: list<float>, vectors: record, tenant: string, additional: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "consistency_level" $consistency_level "scalar") (serialize-qp "node_name" $node_name "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($className)/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an object
#
# DELETE /objects/{className}/{id}
# operationId: objects.class.delete
export def "objects objectsclassdelete" [
  className: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($className)/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace an object
#
# PUT /objects/{className}/{id}
# operationId: objects.class.put
export def "objects objectsclassput" [
  className: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --class: string # Name of the collection (class) the object belongs to.
  --vectorWeights: record # Allow custom overrides of vector weights as math expressions. E.g. `pancake`: `7` will set the weight for the word pancake to 7 in the vectorization, whereas `w * 3` would triple the originally calculated word. This is an open object, with OpenAPI Specification 3.0 this will be more detailed. See Weaviate docs for more info. In the future this will become a key/value (string/string) object.
  --properties: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --body-id: string # The UUID of the object. (format: uuid)
  --creationTimeUnix: int # (Response only) Timestamp of creation of this object in milliseconds since epoch UTC. (format: int64)
  --lastUpdateTimeUnix: int # (Response only) Timestamp of the last object update in milliseconds since epoch UTC. (format: int64)
  --vector: list # A vector representation of the object in the Contextionary. If provided at object creation, this wil take precedence over any vectorizer setting.
  --vectors: record # A map of named vectors for multi-vector representations.
  --tenant: string # The name of the tenant the object belongs to.
  --additional: record # (Response only) Additional meta information about a single object.
]: any -> record<class: string, vectorWeights: record, properties: record, id: string, creationTimeUnix: int, lastUpdateTimeUnix: int, vector: list<float>, vectors: record, tenant: string, additional: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($className)/($id)" $qp)
  let body = {class: $class, vectorWeights: $vectorWeights, properties: $properties, id: $body_id, creationTimeUnix: $creationTimeUnix, lastUpdateTimeUnix: $lastUpdateTimeUnix, vector: $vector, vectors: $vectors, tenant: $tenant, additional: $additional} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch an object
#
# PATCH /objects/{className}/{id}
# operationId: objects.class.patch
export def "objects objectsclasspatch" [
  className: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --class: string # Name of the collection (class) the object belongs to.
  --vectorWeights: record # Allow custom overrides of vector weights as math expressions. E.g. `pancake`: `7` will set the weight for the word pancake to 7 in the vectorization, whereas `w * 3` would triple the originally calculated word. This is an open object, with OpenAPI Specification 3.0 this will be more detailed. See Weaviate docs for more info. In the future this will become a key/value (string/string) object.
  --properties: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --body-id: string # The UUID of the object. (format: uuid)
  --creationTimeUnix: int # (Response only) Timestamp of creation of this object in milliseconds since epoch UTC. (format: int64)
  --lastUpdateTimeUnix: int # (Response only) Timestamp of the last object update in milliseconds since epoch UTC. (format: int64)
  --vector: list # A vector representation of the object in the Contextionary. If provided at object creation, this wil take precedence over any vectorizer setting.
  --vectors: record # A map of named vectors for multi-vector representations.
  --tenant: string # The name of the tenant the object belongs to.
  --additional: record # (Response only) Additional meta information about a single object.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($className)/($id)" $qp)
  let body = {class: $class, vectorWeights: $vectorWeights, properties: $properties, id: $body_id, creationTimeUnix: $creationTimeUnix, lastUpdateTimeUnix: $lastUpdateTimeUnix, vector: $vector, vectors: $vectors, tenant: $tenant, additional: $additional} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if an object exists
#
# HEAD /objects/{className}/{id}
# operationId: objects.class.head
export def "objects objectsclasshead" [
  className: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($className)/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an object reference
#
# POST /objects/{id}/references/{propertyName}
# DEPRECATED
# operationId: objects.references.create
# --classification shape: {overallCount?: float, winningCount?: float, losingCount?: float, closestOverallDistance?: float, winningDistance?: float, meanWinningDistance?: float, closestWinningDistance?: float, closestLosingDistance?: float, losingDistance?: float, meanLosingDistance?: float}
@deprecated
export def "objects-references objectsreferencescreate" [
  id: string
  propertyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
  --class: string # If using a concept reference (rather than a direct reference), specify the desired collection (class) name here. (format: uri)
  --schema: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --beacon: string # If using a direct reference, specify the URI to point to the cross-reference here. Should be in the form of weaviate://localhost/<uuid> for the example of a local cross-reference to an object (format: uri)
  --href: string # If using a direct reference, this read-only fields provides a link to the referenced resource. If 'origin' is globally configured, an absolute URI is shown - a relative URI otherwise. (format: uri)
  --classification: any # This meta field contains additional info about the classified reference property — shape: {overallCount?: float, winningCount?: float, losingCount?: float, closestOverallDistance?: float, winningDistance?: float, meanWinningDistance?: float, closestWinningDistance?: float, closestLosingDistance?: float, losingDistance?: float, meanLosingDistance?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($id)/references/($propertyName)" $qp)
  let body = {class: $class, schema: $schema, beacon: $beacon, href: $href, classification: $classification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace object references
#
# PUT /objects/{id}/references/{propertyName}
# DEPRECATED
# operationId: objects.references.update
@deprecated
export def "objects-references objectsreferencesupdate" [
  id: string
  propertyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($id)/references/($propertyName)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an object reference
#
# DELETE /objects/{id}/references/{propertyName}
# DEPRECATED
# operationId: objects.references.delete
# --classification shape: {overallCount?: float, winningCount?: float, losingCount?: float, closestOverallDistance?: float, winningDistance?: float, meanWinningDistance?: float, closestWinningDistance?: float, closestLosingDistance?: float, losingDistance?: float, meanLosingDistance?: float}
@deprecated
export def "objects-references objectsreferencesdelete" [
  id: string
  propertyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
  --class: string # If using a concept reference (rather than a direct reference), specify the desired collection (class) name here. (format: uri)
  --schema: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --beacon: string # If using a direct reference, specify the URI to point to the cross-reference here. Should be in the form of weaviate://localhost/<uuid> for the example of a local cross-reference to an object (format: uri)
  --href: string # If using a direct reference, this read-only fields provides a link to the referenced resource. If 'origin' is globally configured, an absolute URI is shown - a relative URI otherwise. (format: uri)
  --classification: any # This meta field contains additional info about the classified reference property — shape: {overallCount?: float, winningCount?: float, losingCount?: float, closestOverallDistance?: float, winningDistance?: float, meanWinningDistance?: float, closestWinningDistance?: float, closestLosingDistance?: float, losingDistance?: float, meanLosingDistance?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($id)/references/($propertyName)" $qp)
  let body = {class: $class, schema: $schema, beacon: $beacon, href: $href, classification: $classification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add an object reference
#
# POST /objects/{className}/{id}/references/{propertyName}
# operationId: objects.class.references.create
# --classification shape: {overallCount?: float, winningCount?: float, losingCount?: float, closestOverallDistance?: float, winningDistance?: float, meanWinningDistance?: float, closestWinningDistance?: float, closestLosingDistance?: float, losingDistance?: float, meanLosingDistance?: float}
export def "objects-references objectsclassreferencescreate" [
  className: string
  id: string
  propertyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
  --class: string # If using a concept reference (rather than a direct reference), specify the desired collection (class) name here. (format: uri)
  --schema: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --beacon: string # If using a direct reference, specify the URI to point to the cross-reference here. Should be in the form of weaviate://localhost/<uuid> for the example of a local cross-reference to an object (format: uri)
  --href: string # If using a direct reference, this read-only fields provides a link to the referenced resource. If 'origin' is globally configured, an absolute URI is shown - a relative URI otherwise. (format: uri)
  --classification: any # This meta field contains additional info about the classified reference property — shape: {overallCount?: float, winningCount?: float, losingCount?: float, closestOverallDistance?: float, winningDistance?: float, meanWinningDistance?: float, closestWinningDistance?: float, closestLosingDistance?: float, losingDistance?: float, meanLosingDistance?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($className)/($id)/references/($propertyName)" $qp)
  let body = {class: $class, schema: $schema, beacon: $beacon, href: $href, classification: $classification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace object references
#
# PUT /objects/{className}/{id}/references/{propertyName}
# operationId: objects.class.references.put
export def "objects-references objectsclassreferencesput" [
  className: string
  id: string
  propertyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($className)/($id)/references/($propertyName)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an object reference
#
# DELETE /objects/{className}/{id}/references/{propertyName}
# operationId: objects.class.references.delete
# --classification shape: {overallCount?: float, winningCount?: float, losingCount?: float, closestOverallDistance?: float, winningDistance?: float, meanWinningDistance?: float, closestWinningDistance?: float, closestLosingDistance?: float, losingDistance?: float, meanLosingDistance?: float}
export def "objects-references objectsclassreferencesdelete" [
  className: string
  id: string
  propertyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
  --class: string # If using a concept reference (rather than a direct reference), specify the desired collection (class) name here. (format: uri)
  --schema: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --beacon: string # If using a direct reference, specify the URI to point to the cross-reference here. Should be in the form of weaviate://localhost/<uuid> for the example of a local cross-reference to an object (format: uri)
  --href: string # If using a direct reference, this read-only fields provides a link to the referenced resource. If 'origin' is globally configured, an absolute URI is shown - a relative URI otherwise. (format: uri)
  --classification: any # This meta field contains additional info about the classified reference property — shape: {overallCount?: float, winningCount?: float, losingCount?: float, closestOverallDistance?: float, winningDistance?: float, meanWinningDistance?: float, closestWinningDistance?: float, closestLosingDistance?: float, losingDistance?: float, meanLosingDistance?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($className)/($id)/references/($propertyName)" $qp)
  let body = {class: $class, schema: $schema, beacon: $beacon, href: $href, classification: $classification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate an object
#
# POST /objects/validate
# operationId: objects.validate
export def "objects-validate objectsvalidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --class: string # Name of the collection (class) the object belongs to.
  --vectorWeights: record # Allow custom overrides of vector weights as math expressions. E.g. `pancake`: `7` will set the weight for the word pancake to 7 in the vectorization, whereas `w * 3` would triple the originally calculated word. This is an open object, with OpenAPI Specification 3.0 this will be more detailed. See Weaviate docs for more info. In the future this will become a key/value (string/string) object.
  --properties: record # Names and values of an individual property. A returned response may also contain additional metadata, such as from classification or feature projection.
  --id: string # The UUID of the object. (format: uuid)
  --creationTimeUnix: int # (Response only) Timestamp of creation of this object in milliseconds since epoch UTC. (format: int64)
  --lastUpdateTimeUnix: int # (Response only) Timestamp of the last object update in milliseconds since epoch UTC. (format: int64)
  --vector: list # A vector representation of the object in the Contextionary. If provided at object creation, this wil take precedence over any vectorizer setting.
  --vectors: record # A map of named vectors for multi-vector representations.
  --tenant: string # The name of the tenant the object belongs to.
  --additional: record # (Response only) Additional meta information about a single object.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/objects/validate")
  let body = {class: $class, vectorWeights: $vectorWeights, properties: $properties, id: $id, creationTimeUnix: $creationTimeUnix, lastUpdateTimeUnix: $lastUpdateTimeUnix, vector: $vector, vectors: $vectors, tenant: $tenant, additional: $additional} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create objects in batch
#
# POST /batch/objects
# operationId: batch.objects.create
# --objects item shape: {class?: string, vectorWeights?: record, properties?: record, id?: string, creationTimeUnix?: int, lastUpdateTimeUnix?: int, vector?: list, vectors?: record, tenant?: string, additional?: record}
export def "batch-objects batchobjectscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --body-fields: list # Controls which fields are returned in the response for each object. Default is `ALL`.
  --objects: list # Array of objects to be created. — item shape: {class?: string, vectorWeights?: record, properties?: record, id?: string, creationTimeUnix?: int, lastUpdateTimeUnix?: int, vector?: list, vectors?: record, tenant?: string, additional?: record}
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch/objects" $qp)
  let body = {fields: $body_fields, objects: $objects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete objects in batch
#
# DELETE /batch/objects
# operationId: batch.objects.delete
# --match shape: {class?: string, where?: record}
export def "batch-objects batchobjectsdelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --tenant: string # Specifies the tenant in a request targeting a multi-tenant collection (class).
  --body-match: record # Outlines how to find the objects to be deleted. — shape: {class?: string, where?: record}
  --output: string # Controls the verbosity of the output, possible values are: `minimal`, `verbose`. Defaults to `minimal`. (default: minimal)
  --deletionTimeUnixMilli: int # Timestamp of deletion in milliseconds since epoch UTC. (format: int64)
  --dryRun: string@bool-completer # If true, the call will show which objects would be matched using the specified filter without deleting any objects. <br/><br/>Depending on the configured verbosity, you will either receive a count of affected objects, or a list of IDs. (default: false)
]: any -> record<match: record<class: string, where: record<operands: list, operator: string, path: list, valueInt: int, valueNumber: float, valueBoolean: bool, valueString: string, valueText: string, valueDate: string, valueIntArray: list, valueNumberArray: list, valueBooleanArray: list, valueStringArray: list, valueTextArray: list, valueDateArray: list, valueGeoRange: record>>, output: string, deletionTimeUnixMilli: int, dryRun: bool, results: record<matches: float, limit: float, successful: float, failed: float, objects: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar") (serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch/objects" $qp)
  let body = {match: $body_match, output: $output, deletionTimeUnixMilli: $deletionTimeUnixMilli, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create cross-references in bulk
#
# POST /batch/references
# operationId: batch.references.create
export def "batch-references batchreferencescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency-level: string # Determines how many replicas must acknowledge a request before it is considered successful.
  --body: record
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consistency_level" $consistency_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch/references" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Perform a GraphQL query
#
# POST /graphql
# operationId: graphql.post
export def "graphql graphqlpost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --operationName: string # The name of the operation if multiple exist in the query.
  --body-query: string # Query based on GraphQL syntax.
  --body-variables: record # Additional variables for the query.
]: any -> record<data: record, errors: table<locations: list, message: string, path: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/graphql")
  let body = {operationName: $operationName, query: $body_query, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Perform batched GraphQL queries
#
# POST /graphql/batch
# operationId: graphql.batch
export def "graphql-batch graphqlbatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<data: record, errors: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/graphql/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get instance metadata
#
# GET /meta
# operationId: meta.get
export def "meta metaget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<hostname: string, version: string, modules: record, grpcMaxMessageSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meta")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tokenize text
#
# POST /tokenize
# operationId: tokenize
# --analyzerConfig shape: {asciiFold?: bool, asciiFoldIgnore?: list, stopwordPreset?: string}
# --stopwords shape: {preset?: string, additions?: list, removals?: list}
export def "tokenize tokenize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string # The text to tokenize.
  tokenization: string@tokenization-completer # The tokenization method to apply.
  --analyzerConfig: record # Text analysis options for a property. These settings are immutable after the property is created. Applies only to text and text[] data types that use an inverted index (searchable or filterable). — shape: {asciiFold?: bool, asciiFoldIgnore?: list, stopwordPreset?: string}
  --stopwords: record # Fine-grained control over stopword list usage. — shape: {preset?: string, additions?: list, removals?: list}
  --stopwordPresets: record # Optional user-defined named stopword presets. Shape matches InvertedIndexConfig.stopwordPresets on a collection: each key is a preset name, each value is a plain list of stopwords. A preset name that matches a built-in ('en', 'none') fully replaces the built-in. Preset names must not be empty or whitespace-only; each word list must contain at least one word; individual words must not be empty or whitespace-only. Mutually exclusive with stopwords — pass one or the other, not both.
]: any -> record<indexed: list<string>, query: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokenize")
  let body = {text: $text, tokenization: $tokenization, analyzerConfig: $analyzerConfig, stopwords: $stopwords, stopwordPresets: $stopwordPresets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all collection definitions
#
# GET /schema
# operationId: schema.dump
export def "schema schemadump" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string@bool-completer # If true, the request is proxied to the cluster leader to ensure strong schema consistency. Default is true.
]: nothing -> record<classes: table<class: string, vectorConfig: record, vectorIndexType: string, vectorIndexConfig: record, shardingConfig: record, replicationConfig: record, invertedIndexConfig: record, multiTenancyConfig: record, objectTtlConfig: record, vectorizer: string, moduleConfig: record, description: string, properties: list>, maintainer: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schema")
  let extra_headers = {"consistency": $consistency} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new collection
#
# POST /schema
# operationId: schema.objects.create
# --replicationConfig shape: {factor?: int, asyncConfig?: record, deletionStrategy?: "NoAutomatedResolution"|"DeleteOnConflict"|"TimeBasedResolution"}
# --invertedIndexConfig shape: {cleanupIntervalSeconds?: float, bm25?: record, stopwords?: record, indexTimestamps?: bool, indexNullState?: bool, indexPropertyLength?: bool, usingBlockMaxWAND?: bool, tokenizerUserDict?: list, stopwordPresets?: record}
# --multiTenancyConfig shape: {enabled?: bool, autoTenantCreation?: bool, autoTenantActivation?: bool}
# --objectTtlConfig shape: {enabled?: bool, defaultTtl?: int, deleteOn?: string, filterExpiredObjects?: bool}
# --properties item shape: {dataType?: list, description?: string, moduleConfig?: record, name?: string, indexInverted?: bool, bucketGeneration?: int, indexFilterable?: bool, indexSearchable?: bool, indexRangeFilters?: bool, tokenization?: "word"|"lowercase"|"whitespace"|"field"|"trigram"|"gse"|"kagome_kr"|"kagome_ja"|"gse_ch", nestedProperties?: list, disableDuplicatedReferences?: bool, textAnalyzer?: record}
export def "schema schemaobjectscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --class: string # Name of the collection (formerly 'class') (required). Multiple words should be concatenated in CamelCase, e.g. `ArticleAuthor`.
  --vectorConfig: record # Configure named vectors. Either use this field or `vectorizer`, `vectorIndexType`, and `vectorIndexConfig` fields. Available from `v1.24.0`.
  --vectorIndexType: string # Name of the vector index type to use for the collection (e.g. `hnsw` or `flat`).
  --vectorIndexConfig: record # Vector-index config, that is specific to the type of index selected in vectorIndexType
  --shardingConfig: record # Manage how the index should be sharded and distributed in the cluster
  --replicationConfig: record # Configure how replication is executed in a cluster — shape: {factor?: int, asyncConfig?: record, deletionStrategy?: "NoAutomatedResolution"|"DeleteOnConflict"|"TimeBasedResolution"}
  --invertedIndexConfig: record # Configure the inverted index built into Weaviate. See [Reference: Inverted index](https://docs.weaviate.io/weaviate/config-refs/indexing/inverted-index#inverted-index-parameters) for details. — shape: {cleanupIntervalSeconds?: float, bm25?: record, stopwords?: record, indexTimestamps?: bool, indexNullState?: bool, indexPropertyLength?: bool, usingBlockMaxWAND?: bool, tokenizerUserDict?: list, stopwordPresets?: record}
  --multiTenancyConfig: any # Configuration related to multi-tenancy within a collection (class) — shape: {enabled?: bool, autoTenantCreation?: bool, autoTenantActivation?: bool}
  --objectTtlConfig: any # Configuration of objects' time-to-live — shape: {enabled?: bool, defaultTtl?: int, deleteOn?: string, filterExpiredObjects?: bool}
  --vectorizer: string # Specify how the vectors for this collection should be determined. The options are either `none` - this means you have to import a vector with each object yourself - or the name of a module that provides vectorization capabilities, such as `text2vec-weaviate`. If left empty, it will use the globally configured default ([`DEFAULT_VECTORIZER_MODULE`](https://docs.weaviate.io/deploy/configuration/env-vars)) which can itself either be `none` or a specific module.
  --moduleConfig: record # Configuration specific to modules in a collection context.
  --description: string # Description of the collection for metadata purposes.
  --properties: list # Define properties of the collection. — item shape: {dataType?: list, description?: string, moduleConfig?: record, name?: string, indexInverted?: bool, bucketGeneration?: int, indexFilterable?: bool, indexSearchable?: bool, indexRangeFilters?: bool, tokenization?: "word"|"lowercase"|"whitespace"|"field"|"trigram"|"gse"|"kagome_kr"|"kagome_ja"|"gse_ch", nestedProperties?: list, disableDuplicatedReferences?: bool, textAnalyzer?: record}
]: any -> record<class: string, vectorConfig: record, vectorIndexType: string, vectorIndexConfig: record, shardingConfig: record, replicationConfig: record<factor: int, asyncConfig: record<hashtreeHeight: int, frequency: int, frequencyWhilePropagating: int, loggingFrequency: int, diffBatchSize: int, diffPerNodeTimeout: int, prePropagationTimeout: int, propagationTimeout: int, propagationLimit: int, propagationDelay: int, propagationConcurrency: int, propagationBatchSize: int>, deletionStrategy: string>, invertedIndexConfig: record<cleanupIntervalSeconds: float, bm25: record<k1: float, b: float>, stopwords: record<preset: string, additions: list, removals: list>, indexTimestamps: bool, indexNullState: bool, indexPropertyLength: bool, usingBlockMaxWAND: bool, tokenizerUserDict: list<record>, stopwordPresets: record>, multiTenancyConfig: record<enabled: bool, autoTenantCreation: bool, autoTenantActivation: bool>, objectTtlConfig: record<enabled: bool, defaultTtl: int, deleteOn: string, filterExpiredObjects: bool>, vectorizer: string, moduleConfig: record, description: string, properties: table<dataType: list, description: string, moduleConfig: record, name: string, indexInverted: bool, bucketGeneration: int, indexFilterable: bool, indexSearchable: bool, indexRangeFilters: bool, tokenization: string, nestedProperties: list, disableDuplicatedReferences: bool, textAnalyzer: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schema")
  let body = {class: $class, vectorConfig: $vectorConfig, vectorIndexType: $vectorIndexType, vectorIndexConfig: $vectorIndexConfig, shardingConfig: $shardingConfig, replicationConfig: $replicationConfig, invertedIndexConfig: $invertedIndexConfig, multiTenancyConfig: $multiTenancyConfig, objectTtlConfig: $objectTtlConfig, vectorizer: $vectorizer, moduleConfig: $moduleConfig, description: $description, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single collection
#
# GET /schema/{className}
# operationId: schema.objects.get
export def "schema schemaobjectsget" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string@bool-completer # If true, the request is proxied to the cluster leader to ensure strong schema consistency. Default is true.
]: nothing -> record<class: string, vectorConfig: record, vectorIndexType: string, vectorIndexConfig: record, shardingConfig: record, replicationConfig: record<factor: int, asyncConfig: record<hashtreeHeight: int, frequency: int, frequencyWhilePropagating: int, loggingFrequency: int, diffBatchSize: int, diffPerNodeTimeout: int, prePropagationTimeout: int, propagationTimeout: int, propagationLimit: int, propagationDelay: int, propagationConcurrency: int, propagationBatchSize: int>, deletionStrategy: string>, invertedIndexConfig: record<cleanupIntervalSeconds: float, bm25: record<k1: float, b: float>, stopwords: record<preset: string, additions: list, removals: list>, indexTimestamps: bool, indexNullState: bool, indexPropertyLength: bool, usingBlockMaxWAND: bool, tokenizerUserDict: list<record>, stopwordPresets: record>, multiTenancyConfig: record<enabled: bool, autoTenantCreation: bool, autoTenantActivation: bool>, objectTtlConfig: record<enabled: bool, defaultTtl: int, deleteOn: string, filterExpiredObjects: bool>, vectorizer: string, moduleConfig: record, description: string, properties: table<dataType: list, description: string, moduleConfig: record, name: string, indexInverted: bool, bucketGeneration: int, indexFilterable: bool, indexSearchable: bool, indexRangeFilters: bool, tokenization: string, nestedProperties: list, disableDuplicatedReferences: bool, textAnalyzer: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)")
  let extra_headers = {"consistency": $consistency} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a collection (and all associated data)
#
# DELETE /schema/{className}
# operationId: schema.objects.delete
export def "schema schemaobjectsdelete" [
  className: string
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
  let full_url = (build-url $base $"/schema/($className)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update collection definition
#
# PUT /schema/{className}
# operationId: schema.objects.update
# --replicationConfig shape: {factor?: int, asyncConfig?: record, deletionStrategy?: "NoAutomatedResolution"|"DeleteOnConflict"|"TimeBasedResolution"}
# --invertedIndexConfig shape: {cleanupIntervalSeconds?: float, bm25?: record, stopwords?: record, indexTimestamps?: bool, indexNullState?: bool, indexPropertyLength?: bool, usingBlockMaxWAND?: bool, tokenizerUserDict?: list, stopwordPresets?: record}
# --multiTenancyConfig shape: {enabled?: bool, autoTenantCreation?: bool, autoTenantActivation?: bool}
# --objectTtlConfig shape: {enabled?: bool, defaultTtl?: int, deleteOn?: string, filterExpiredObjects?: bool}
# --properties item shape: {dataType?: list, description?: string, moduleConfig?: record, name?: string, indexInverted?: bool, bucketGeneration?: int, indexFilterable?: bool, indexSearchable?: bool, indexRangeFilters?: bool, tokenization?: "word"|"lowercase"|"whitespace"|"field"|"trigram"|"gse"|"kagome_kr"|"kagome_ja"|"gse_ch", nestedProperties?: list, disableDuplicatedReferences?: bool, textAnalyzer?: record}
export def "schema schemaobjectsupdate" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --class: string # Name of the collection (formerly 'class') (required). Multiple words should be concatenated in CamelCase, e.g. `ArticleAuthor`.
  --vectorConfig: record # Configure named vectors. Either use this field or `vectorizer`, `vectorIndexType`, and `vectorIndexConfig` fields. Available from `v1.24.0`.
  --vectorIndexType: string # Name of the vector index type to use for the collection (e.g. `hnsw` or `flat`).
  --vectorIndexConfig: record # Vector-index config, that is specific to the type of index selected in vectorIndexType
  --shardingConfig: record # Manage how the index should be sharded and distributed in the cluster
  --replicationConfig: record # Configure how replication is executed in a cluster — shape: {factor?: int, asyncConfig?: record, deletionStrategy?: "NoAutomatedResolution"|"DeleteOnConflict"|"TimeBasedResolution"}
  --invertedIndexConfig: record # Configure the inverted index built into Weaviate. See [Reference: Inverted index](https://docs.weaviate.io/weaviate/config-refs/indexing/inverted-index#inverted-index-parameters) for details. — shape: {cleanupIntervalSeconds?: float, bm25?: record, stopwords?: record, indexTimestamps?: bool, indexNullState?: bool, indexPropertyLength?: bool, usingBlockMaxWAND?: bool, tokenizerUserDict?: list, stopwordPresets?: record}
  --multiTenancyConfig: any # Configuration related to multi-tenancy within a collection (class) — shape: {enabled?: bool, autoTenantCreation?: bool, autoTenantActivation?: bool}
  --objectTtlConfig: any # Configuration of objects' time-to-live — shape: {enabled?: bool, defaultTtl?: int, deleteOn?: string, filterExpiredObjects?: bool}
  --vectorizer: string # Specify how the vectors for this collection should be determined. The options are either `none` - this means you have to import a vector with each object yourself - or the name of a module that provides vectorization capabilities, such as `text2vec-weaviate`. If left empty, it will use the globally configured default ([`DEFAULT_VECTORIZER_MODULE`](https://docs.weaviate.io/deploy/configuration/env-vars)) which can itself either be `none` or a specific module.
  --moduleConfig: record # Configuration specific to modules in a collection context.
  --description: string # Description of the collection for metadata purposes.
  --properties: list # Define properties of the collection. — item shape: {dataType?: list, description?: string, moduleConfig?: record, name?: string, indexInverted?: bool, bucketGeneration?: int, indexFilterable?: bool, indexSearchable?: bool, indexRangeFilters?: bool, tokenization?: "word"|"lowercase"|"whitespace"|"field"|"trigram"|"gse"|"kagome_kr"|"kagome_ja"|"gse_ch", nestedProperties?: list, disableDuplicatedReferences?: bool, textAnalyzer?: record}
]: any -> record<class: string, vectorConfig: record, vectorIndexType: string, vectorIndexConfig: record, shardingConfig: record, replicationConfig: record<factor: int, asyncConfig: record<hashtreeHeight: int, frequency: int, frequencyWhilePropagating: int, loggingFrequency: int, diffBatchSize: int, diffPerNodeTimeout: int, prePropagationTimeout: int, propagationTimeout: int, propagationLimit: int, propagationDelay: int, propagationConcurrency: int, propagationBatchSize: int>, deletionStrategy: string>, invertedIndexConfig: record<cleanupIntervalSeconds: float, bm25: record<k1: float, b: float>, stopwords: record<preset: string, additions: list, removals: list>, indexTimestamps: bool, indexNullState: bool, indexPropertyLength: bool, usingBlockMaxWAND: bool, tokenizerUserDict: list<record>, stopwordPresets: record>, multiTenancyConfig: record<enabled: bool, autoTenantCreation: bool, autoTenantActivation: bool>, objectTtlConfig: record<enabled: bool, defaultTtl: int, deleteOn: string, filterExpiredObjects: bool>, vectorizer: string, moduleConfig: record, description: string, properties: table<dataType: list, description: string, moduleConfig: record, name: string, indexInverted: bool, bucketGeneration: int, indexFilterable: bool, indexSearchable: bool, indexRangeFilters: bool, tokenization: string, nestedProperties: list, disableDuplicatedReferences: bool, textAnalyzer: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)")
  let body = {class: $class, vectorConfig: $vectorConfig, vectorIndexType: $vectorIndexType, vectorIndexConfig: $vectorIndexConfig, shardingConfig: $shardingConfig, replicationConfig: $replicationConfig, invertedIndexConfig: $invertedIndexConfig, multiTenancyConfig: $multiTenancyConfig, objectTtlConfig: $objectTtlConfig, vectorizer: $vectorizer, moduleConfig: $moduleConfig, description: $description, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a property to a collection
#
# POST /schema/{className}/properties
# operationId: schema.objects.properties.add
# --nestedProperties item shape: {dataType?: list, description?: string, name?: string, indexFilterable?: bool, indexSearchable?: bool, indexRangeFilters?: bool, tokenization?: "word"|"lowercase"|"whitespace"|"field"|"trigram"|"gse"|"kagome_kr"|"kagome_ja"|"gse_ch", nestedProperties?: list, textAnalyzer?: record}
# --textAnalyzer shape: {asciiFold?: bool, asciiFoldIgnore?: list, stopwordPreset?: string}
export def "schema-properties schemaobjectspropertiesadd" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataType: list # Data type of the property (required). If it starts with a capital (for example Person), may be a reference to another type.
  --description: string # Description of the property.
  --moduleConfig: record # Configuration specific to modules in a collection context.
  --name: string # The name of the property (required). Multiple words should be concatenated in camelCase, e.g. `nameOfAuthor`.
  --indexInverted: string@bool-completer # (Deprecated). Whether to include this property in the inverted index. If `false`, this property cannot be used in `where` filters, `bm25` or `hybrid` search. <br/><br/>Unrelated to vectorization behavior (deprecated as of v1.19; use indexFilterable or/and indexSearchable instead)
  --bucketGeneration: int # Internal RAFT-replicated counter bumped by semantic runtime-reindex migrations (e.g. change-tokenization, enable-filterable, enable-searchable). Used by the data path to resolve the property's inverted-index bucket name; a single RAFT commit flipping the schema flag AND bumping this counter atomically cuts the cluster from the old bucket to the new one. Defaults to 0. Internal use; clients should not set this. (format: int64)
  --indexFilterable: string@bool-completer # Whether to include this property in the filterable, Roaring Bitmap index. If `false`, this property cannot be used in `where` filters. <br/><br/>Note: Unrelated to vectorization behavior.
  --indexSearchable: string@bool-completer # Optional. Should this property be indexed in the inverted index. Defaults to true. Applicable only to properties of data type text and text[]. If you choose false, you will not be able to use this property in bm25 or hybrid search. This property has no affect on vectorization decisions done by modules
  --indexRangeFilters: string@bool-completer # Whether to include this property in the filterable, range-based Roaring Bitmap index. Provides better performance for range queries compared to filterable index in large datasets. Applicable only to properties of data type int, number, date.
  --tokenization: string@tokenization-completer # Determines how a property is indexed. This setting applies to `text` and `text[]` data types. The following tokenization methods are available:<br/><br/>- `word` (default): Splits the text on any non-alphanumeric characters and lowercases the tokens.<br/>- `lowercase`: Splits the text on whitespace and lowercases the tokens.<br/>- `whitespace`: Splits the text on whitespace. This tokenization is case-sensitive.<br/>- `field`: Indexes the entire property value as a single token after trimming whitespace.<br/>- `trigram`: Splits the property into rolling trigrams (three-character sequences).<br/>- `gse`: Uses the `gse` tokenizer, suitable for Chinese language text. [See `gse` docs](https://pkg.go.dev/github.com/go-ego/gse#section-readme).<br/>- `kagome_ja`: Uses the `Kagome` tokenizer with a Japanese (IPA) dictionary. [See `kagome` docs](https://github.com/ikawaha/kagome).<br/>- `kagome_kr`: Uses the `Kagome` tokenizer with a Korean dictionary. [See `kagome` docs](https://github.com/ikawaha/kagome).<br/><br/>See [Reference: Tokenization](https://docs.weaviate.io/weaviate/config-refs/collections#tokenization) for details.
  --nestedProperties: list # The properties of the nested object(s). Applies to object and object[] data types. — item shape: {dataType?: list, description?: string, name?: string, indexFilterable?: bool, indexSearchable?: bool, indexRangeFilters?: bool, tokenization?: "word"|"lowercase"|"whitespace"|"field"|"trigram"|"gse"|"kagome_kr"|"kagome_ja"|"gse_ch", nestedProperties?: list, textAnalyzer?: record}
  --disableDuplicatedReferences: string@bool-completer # If set to false, allows multiple references to the same target object within this property. Setting it to true will enforce uniqueness of references within this property. By default, this is set to true. (default: true)
  --textAnalyzer: record # Text analysis options for a property. These settings are immutable after the property is created. Applies only to text and text[] data types that use an inverted index (searchable or filterable). — shape: {asciiFold?: bool, asciiFoldIgnore?: list, stopwordPreset?: string}
]: any -> record<dataType: list<string>, description: string, moduleConfig: record, name: string, indexInverted: bool, bucketGeneration: int, indexFilterable: bool, indexSearchable: bool, indexRangeFilters: bool, tokenization: string, nestedProperties: table<dataType: list, description: string, name: string, indexFilterable: bool, indexSearchable: bool, indexRangeFilters: bool, tokenization: string, nestedProperties: list, textAnalyzer: record>, disableDuplicatedReferences: bool, textAnalyzer: record<asciiFold: bool, asciiFoldIgnore: list<string>, stopwordPreset: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/properties")
  let body = {dataType: $dataType, description: $description, moduleConfig: $moduleConfig, name: $name, indexInverted: $indexInverted, bucketGeneration: $bucketGeneration, indexFilterable: $indexFilterable, indexSearchable: $indexSearchable, indexRangeFilters: $indexRangeFilters, tokenization: $tokenization, nestedProperties: $nestedProperties, disableDuplicatedReferences: $disableDuplicatedReferences, textAnalyzer: $textAnalyzer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get index status for all properties of a collection
#
# GET /schema/{className}/indexes
# operationId: schema.objects.indexes.get
export def "schema-indexes schemaobjectsindexesget" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<collection: string, properties: table<name: string, dataType: string, description: string, indexes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/indexes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update index configuration for a property (triggers reindex)
#
# PUT /schema/{className}/indexes/{propertyName}
# operationId: schema.objects.indexes.update
# --searchable shape: {tokenization?: string, rebuild?: bool, algorithm?: "blockmax", enabled?: bool, cancel?: bool}
# --filterable shape: {rebuild?: bool, enabled?: bool, tokenization?: string, cancel?: bool}
# --rangeable shape: {enabled?: bool, rebuild?: bool, cancel?: bool}
export def "schema-indexes schemaobjectsindexesupdate" [
  className: string
  propertyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenants: list # Tenant names to target. Only for non-semantic operations on multi-tenant collections. Omit to target all tenants.
  --searchable: record # shape: {tokenization?: string, rebuild?: bool, algorithm?: "blockmax", enabled?: bool, cancel?: bool}
  --filterable: record # shape: {rebuild?: bool, enabled?: bool, tokenization?: string, cancel?: bool}
  --rangeable: record # shape: {enabled?: bool, rebuild?: bool, cancel?: bool}
]: any -> record<taskId: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenants" $tenants "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/schema/($className)/indexes/($propertyName)" $qp)
  let body = {searchable: $searchable, filterable: $filterable, rangeable: $rangeable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a property's inverted index
#
# DELETE /schema/{className}/properties/{propertyName}/index/{indexName}
# operationId: schema.objects.properties.delete
export def "schema-properties-index schemaobjectspropertiesdelete" [
  className: string
  propertyName: string
  indexName: string
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
  let full_url = (build-url $base $"/schema/($className)/properties/($propertyName)/index/($indexName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tokenize text using a property's configuration
#
# POST /schema/{className}/properties/{propertyName}/tokenize
# operationId: schema.objects.properties.tokenize
export def "schema-properties-tokenize schemaobjectspropertiestokenize" [
  className: string
  propertyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: string # The text to tokenize using the property's configured tokenization.
]: any -> record<indexed: list<string>, query: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/properties/($propertyName)/tokenize")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a collection's vector index.
#
# DELETE /schema/{className}/vectors/{vectorIndexName}/index
# operationId: schema.objects.vectors.delete
export def "schema-vectors-index schemaobjectsvectorsdelete" [
  className: string
  vectorIndexName: string
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
  let full_url = (build-url $base $"/schema/($className)/vectors/($vectorIndexName)/index")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the shards status of a collection
#
# GET /schema/{className}/shards
# operationId: schema.objects.shards.get
export def "schema-shards schemaobjectsshardsget" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant: string # The name of the tenant for which to retrieve shard statuses (only applicable for multi-tenant collections).
]: nothing -> table<name: string, status: string, vectorQueueSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schema/($className)/shards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a shard status
#
# PUT /schema/{className}/shards/{shardName}
# operationId: schema.objects.shards.update
export def "schema-shards schemaobjectsshardsupdate" [
  className: string
  shardName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # Status of the shard
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/shards/($shardName)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new tenant
#
# POST /schema/{className}/tenants
# operationId: tenants.create
export def "schema-tenants tenantscreate" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<name: string, activityStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/tenants")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a tenant
#
# PUT /schema/{className}/tenants
# operationId: tenants.update
export def "schema-tenants tenantsupdate" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<name: string, activityStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/tenants")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete tenants
#
# DELETE /schema/{className}/tenants
# operationId: tenants.delete
export def "schema-tenants tenantsdelete" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/tenants")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the list of tenants
#
# GET /schema/{className}/tenants
# operationId: tenants.get
export def "schema-tenants tenantsget" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string@bool-completer # If true, the request is proxied to the cluster leader to ensure strong schema consistency. Default is true.
]: nothing -> table<name: string, activityStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/tenants")
  let extra_headers = {"consistency": $consistency} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a tenant exists
#
# HEAD /schema/{className}/tenants/{tenantName}
# operationId: tenant.exists
export def "schema-tenants tenantexists" [
  className: string
  tenantName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string@bool-completer # If true, the request is proxied to the cluster leader to ensure strong schema consistency. Default is true.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/tenants/($tenantName)")
  let extra_headers = {"consistency": $consistency} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific tenant
#
# GET /schema/{className}/tenants/{tenantName}
# operationId: tenants.get.one
export def "schema-tenants tenantsgetone" [
  className: string
  tenantName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consistency: string@bool-completer # If true, the request is proxied to the cluster leader to ensure strong schema consistency. Default is true.
]: nothing -> record<name: string, activityStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schema/($className)/tenants/($tenantName)")
  let extra_headers = {"consistency": $consistency} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List aliases
#
# GET /aliases
# operationId: aliases.get
export def "aliases aliasesget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --class: string # Optional filter to retrieve aliases for a specific collection (class) only. If not provided, returns all aliases.
]: nothing -> record<aliases: table<alias: string, class: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "class" $class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new alias
#
# POST /aliases
# operationId: aliases.create
export def "aliases aliasescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alias: string # The unique name of the alias that serves as an alternative identifier for the collection.
  --class: string # The name of the collection (class) to which this alias is mapped.
]: any -> record<alias: string, class: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aliases")
  let body = {alias: $alias, class: $class} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an alias
#
# GET /aliases/{aliasName}
# operationId: aliases.get.alias
export def "aliases aliasesgetalias" [
  aliasName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alias: string, class: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aliases/($aliasName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an alias
#
# PUT /aliases/{aliasName}
# operationId: aliases.update
export def "aliases aliasesupdate" [
  aliasName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --class: string # The new collection (class) that the alias should point to.
]: any -> record<alias: string, class: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aliases/($aliasName)")
  let body = {class: $class} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an alias
#
# DELETE /aliases/{aliasName}
# operationId: aliases.delete
export def "aliases aliasesdelete" [
  aliasName: string
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
  let full_url = (build-url $base $"/aliases/($aliasName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List namespaces
#
# GET /namespaces
# operationId: listNamespaces
export def "namespaces listNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, home_node: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/namespaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new namespace
#
# POST /namespaces/{namespace_id}
# operationId: createNamespace
export def "namespaces createNamespace" [
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --home-node: string # Optional. Cluster node to place this namespace's shards on. Must be a current storage candidate. When omitted, the cluster picks one.
]: any -> record<name: string, home_node: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace_id)")
  let body = {home_node: $home_node} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a namespace
#
# GET /namespaces/{namespace_id}
# operationId: getNamespace
export def "namespaces get" [
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, home_node: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a namespace
#
# PUT /namespaces/{namespace_id}
# operationId: updateNamespace
export def "namespaces updateNamespace" [
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  home_node: string # Cluster node to use for future placements in this namespace. Must be a current storage candidate. Existing live shards are not moved.
]: any -> record<name: string, home_node: string, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace_id)")
  let body = {home_node: $home_node} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a namespace
#
# DELETE /namespaces/{namespace_id}
# operationId: deleteNamespace
export def "namespaces delete" [
  namespace_id: string
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
  let full_url = (build-url $base $"/namespaces/($namespace_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a backup
#
# POST /backups/{backend}
# operationId: backups.create
# --config shape: {Endpoint?: string, Bucket?: string, Path?: string, CPUPercentage?: int, ChunkSize?: int, CompressionLevel?: "DefaultCompression"|"BestSpeed"|"BestCompression"|"ZstdDefaultCompression"|"ZstdBestSpeed"|"ZstdBestCompression"|"NoCompression"}
export def "backups backupscreate" [
  backend: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID of the backup (required). Must be URL-safe and work as a filesystem path, only lowercase, numbers, underscore, minus characters allowed.
  --config: record # Backup custom configuration. — shape: {Endpoint?: string, Bucket?: string, Path?: string, CPUPercentage?: int, ChunkSize?: int, CompressionLevel?: "DefaultCompression"|"BestSpeed"|"BestCompression"|"ZstdDefaultCompression"|"ZstdBestSpeed"|"ZstdBestCompression"|"NoCompression"}
  --include: list # List of collections to include in the backup creation process. If not set, all collections are included. Cannot be used together with `exclude`.
  --exclude: list # List of collections to exclude from the backup creation process. If not set, all collections are included. Cannot be used together with `include`.
  --incremental-base-backup-id: string # The ID of an existing backup to use as the base for a file-based incremental backup. If set, only files that have changed since the base backup will be included in the new backup.
]: any -> record<id: string, classes: list<string>, backend: string, bucket: string, path: string, error: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/backups/($backend)")
  let body = {id: $id, config: $config, include: $include, exclude: $exclude, incremental_base_backup_id: $incremental_base_backup_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all created backups
#
# GET /backups/{backend}
# operationId: backups.list
export def "backups backupslist" [
  backend: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer # Order of returned list of backups based on creation time. (asc or desc) (default: desc)
]: nothing -> table<id: string, classes: list<string>, status: string, startedAt: string, completedAt: string, size: float, incremental_base_backup_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/backups/($backend)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get backup creation status
#
# GET /backups/{backend}/{id}
# operationId: backups.create.status
export def "backups backupscreatestatus" [
  backend: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bucket: string # Optional: Specifies the bucket, container, or volume name if required by the backend.
  --path: string # Optional: Specifies the path within the bucket/container/volume if the backup is not at the root.
]: nothing -> record<id: string, backend: string, path: string, error: string, status: string, startedAt: string, completedAt: string, size: float, incremental_base_backup_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucket" $bucket "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/backups/($backend)/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a backup
#
# DELETE /backups/{backend}/{id}
# operationId: backups.cancel
export def "backups backupscancel" [
  backend: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bucket: string # Optional: Specifies the bucket, container, or volume name if required by the backend.
  --path: string # Optional: Specifies the path within the bucket/container/volume if the backup is not at the root.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucket" $bucket "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/backups/($backend)/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore from a backup
#
# POST /backups/{backend}/{id}/restore
# operationId: backups.restore
# --config shape: {Endpoint?: string, Bucket?: string, Path?: string, CPUPercentage?: int, rolesOptions?: "noRestore"|"all", usersOptions?: "noRestore"|"all"}
export def "backups-restore backupsrestore" [
  backend: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # Backup custom configuration — shape: {Endpoint?: string, Bucket?: string, Path?: string, CPUPercentage?: int, rolesOptions?: "noRestore"|"all", usersOptions?: "noRestore"|"all"}
  --include: list # List of collections (classes) to include in the backup restoration process.
  --exclude: list # List of collections (classes) to exclude from the backup restoration process.
  --node-mapping: record # Allows overriding the node names stored in the backup with different ones. Useful when restoring backups to a different environment.
  --overwriteAlias: string@bool-completer # Allows ovewriting the collection alias if there is a conflict
]: any -> record<id: string, classes: list<string>, backend: string, path: string, error: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/backups/($backend)/($id)/restore")
  let body = {config: $config, include: $include, exclude: $exclude, node_mapping: $node_mapping, overwriteAlias: $overwriteAlias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get backup restoration status
#
# GET /backups/{backend}/{id}/restore
# operationId: backups.restore.status
export def "backups-restore backupsrestorestatus" [
  backend: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bucket: string # Optional: Specifies the bucket, container, or volume name if required by the backend.
  --path: string # Optional: Specifies the path within the bucket.
]: nothing -> record<id: string, backend: string, path: string, error: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucket" $bucket "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/backups/($backend)/($id)/restore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a backup restoration
#
# DELETE /backups/{backend}/{id}/restore
# operationId: backups.restore.cancel
export def "backups-restore backupsrestorecancel" [
  backend: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bucket: string # Optional: Specifies the bucket, container, or volume name if required by the backend.
  --path: string # Optional: Specifies the path within the bucket/container/volume if the backup is not at the root.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucket" $bucket "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/backups/($backend)/($id)/restore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a new export
#
# POST /export/{backend}
# operationId: export.create
export def "export exportcreate" [
  backend: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # Unique identifier for this export. Must be URL-safe.
  file_format: string@file-format-completer # Output file format for the export.
  --include: list # List of collection names to include in the export. Cannot be used with 'exclude'.
  --exclude: list # List of collection names to exclude from the export. Cannot be used with 'include'.
]: any -> record<id: string, backend: string, path: string, status: string, startedAt: string, classes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/export/($backend)")
  let body = {id: $id, file_format: $file_format, include: $include, exclude: $exclude} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get export status
#
# GET /export/{backend}/{id}
# operationId: export.status
export def "export exportstatus" [
  backend: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, backend: string, path: string, status: string, startedAt: string, completedAt: string, tookInMs: int, classes: list<string>, shardStatus: record, error: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/export/($backend)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an export
#
# DELETE /export/{backend}/{id}
# operationId: export.cancel
export def "export exportcancel" [
  backend: string
  id: string
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
  let full_url = (build-url $base $"/export/($backend)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cluster statistics
#
# GET /cluster/statistics
# operationId: cluster.get.statistics
export def "cluster-statistics clustergetstatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<statistics: table<name: string, status: string, bootstrapped: bool, dbLoaded: bool, initialLastAppliedIndex: float, lastAppliedIndex: float, isVoter: bool, leaderId: record, leaderAddress: record, open: bool, ready: bool, candidates: record, raft: record>, synchronized: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster/statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get node status
#
# GET /nodes
# operationId: nodes.get
export def "nodes nodesget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output: string # Controls the verbosity of the output, possible values are: `minimal`, `verbose`. Defaults to `minimal`. (default: minimal)
]: nothing -> record<nodes: table<name: string, status: string, version: string, gitHash: string, stats: record, batchStats: record, shards: list, operationalMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get node status by collection
#
# GET /nodes/{className}
# operationId: nodes.get.class
export def "nodes nodesgetclass" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --shardName: string
  --output: string # Controls the verbosity of the output, possible values are: `minimal`, `verbose`. Defaults to `minimal`. (default: minimal)
]: nothing -> record<nodes: table<name: string, status: string, version: string, gitHash: string, stats: record, batchStats: record, shards: list, operationalMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shardName" $shardName "scalar") (serialize-qp "output" $output "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nodes/($className)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all distributed tasks in the cluster
#
# GET /tasks
# operationId: distributedTasks.get
export def "tasks distributedTasksget" [
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
  let full_url = (build-url $base "/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a classification
#
# POST /classifications/
# operationId: classifications.post
# --meta shape: {started?: string, completed?: string, count?: int, countSucceeded?: int, countFailed?: int}
# --filters shape: {sourceWhere?: record, trainingSetWhere?: record, targetWhere?: record}
export def "classifications classificationspost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # ID to uniquely identify this classification run. (format: uuid, e.g. ee722219-b8ec-4db1-8f8d-5150bb1a9e0c)
  --class: string # The name of the collection (class) which is used in this classification. (e.g. City)
  --classifyProperties: list # Which ref-property to set as part of the classification. (e.g. [inCountry])
  --basedOnProperties: list # Base the text-based classification on these fields (of type text). (e.g. [description])
  --status: string@status-completer # Status of this classification. (e.g. running)
  --meta: record # Additional information to a specific classification. — shape: {started?: string, completed?: string, count?: int, countSucceeded?: int, countFailed?: int}
  --type: string # Which algorithm to use for classifications.
  --settings: record # Classification-type specific settings.
  --body-error: string # Error message if status == failed. (default: , e.g. classify xzy: something went wrong)
  --filters: record # shape: {sourceWhere?: record, trainingSetWhere?: record, targetWhere?: record}
]: any -> record<id: string, class: string, classifyProperties: list<string>, basedOnProperties: list<string>, status: string, meta: record<started: string, completed: string, count: int, countSucceeded: int, countFailed: int>, type: string, settings: record, error: string, filters: record<sourceWhere: record<operands: list, operator: string, path: list, valueInt: int, valueNumber: float, valueBoolean: bool, valueString: string, valueText: string, valueDate: string, valueIntArray: list, valueNumberArray: list, valueBooleanArray: list, valueStringArray: list, valueTextArray: list, valueDateArray: list, valueGeoRange: record>, trainingSetWhere: record<operands: list, operator: string, path: list, valueInt: int, valueNumber: float, valueBoolean: bool, valueString: string, valueText: string, valueDate: string, valueIntArray: list, valueNumberArray: list, valueBooleanArray: list, valueStringArray: list, valueTextArray: list, valueDateArray: list, valueGeoRange: record>, targetWhere: record<operands: list, operator: string, path: list, valueInt: int, valueNumber: float, valueBoolean: bool, valueString: string, valueText: string, valueDate: string, valueIntArray: list, valueNumberArray: list, valueBooleanArray: list, valueStringArray: list, valueTextArray: list, valueDateArray: list, valueGeoRange: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/")
  let body = {id: $id, class: $class, classifyProperties: $classifyProperties, basedOnProperties: $basedOnProperties, status: $status, meta: $meta, type: $type, settings: $settings, error: $body_error, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get classification status
#
# GET /classifications/{id}
# operationId: classifications.get
export def "classifications classificationsget" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, class: string, classifyProperties: list<string>, basedOnProperties: list<string>, status: string, meta: record<started: string, completed: string, count: int, countSucceeded: int, countFailed: int>, type: string, settings: record, error: string, filters: record<sourceWhere: record<operands: list, operator: string, path: list, valueInt: int, valueNumber: float, valueBoolean: bool, valueString: string, valueText: string, valueDate: string, valueIntArray: list, valueNumberArray: list, valueBooleanArray: list, valueStringArray: list, valueTextArray: list, valueDateArray: list, valueGeoRange: record>, trainingSetWhere: record<operands: list, operator: string, path: list, valueInt: int, valueNumber: float, valueBoolean: bool, valueString: string, valueText: string, valueDate: string, valueIntArray: list, valueNumberArray: list, valueBooleanArray: list, valueStringArray: list, valueTextArray: list, valueDateArray: list, valueGeoRange: record>, targetWhere: record<operands: list, operator: string, path: list, valueInt: int, valueNumber: float, valueBoolean: bool, valueString: string, valueText: string, valueDate: string, valueIntArray: list, valueNumberArray: list, valueBooleanArray: list, valueStringArray: list, valueTextArray: list, valueDateArray: list, valueGeoRange: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/classifications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# MCP Streamable HTTP endpoint. Handles JSON-RPC requests for tool discovery and invocation.
#
# POST /mcp
# operationId: mcp.post
export def "mcp mcppost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mcp")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Opens an SSE stream for receiving MCP server-sent events.
#
# GET /mcp
# operationId: mcp.get
export def "mcp mcpget" [
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
  let full_url = (build-url $base "/mcp")
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Terminates an MCP session.
#
# DELETE /mcp
# operationId: mcp.delete
export def "mcp mcpdelete" [
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
  let full_url = (build-url $base "/mcp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
