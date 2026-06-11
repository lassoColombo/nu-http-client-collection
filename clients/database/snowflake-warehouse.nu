# Auto-generated client for Snowflake Warehouse API v0.0.1
# Source: https://raw.githubusercontent.com/snowflakedb/snowflake-rest-api-specs/main/specifications/warehouse.yaml
# Auth: --token flag or $env.SNOWFLAKE_WAREHOUSE_API_TOKEN

const BASE_URL = "https://org-account.snowflakecomputing.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SNOWFLAKE_WAREHOUSE_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://org-account.snowflakecomputing.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def wait-for-completion-completer [] { ["false" "true"] }
def auto-resume-completer [] { ["false" "true"] }
def initially-suspended-completer [] { ["false" "true"] }
def enable-query-acceleration-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "warehouses createWarehouse" } } | get name | first)
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

# Create or replace warehouse
#
# POST /api/v2/warehouses
# operationId: createWarehouse
@deprecated --flag type
@deprecated --flag size
export def "warehouses createWarehouse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: any # Name of warehouse
  --warehouse-type: string # Type of warehouse, possible types: STANDARD, SNOWPARK-OPTIMIZED
  --warehouse-size: string # Size of warehouse, possible sizes: XSMALL, SMALL, MEDIUM, LARGE, XLARGE, XXLARGE, XXXLARGE, X4LARGE, X5LARGE, X6LARGE
  --wait-for-completion: string@wait-for-completion-completer # When resizing a warehouse, you can use this parameter to block the return of the ALTER WAREHOUSE command until the resize has finished provisioning all its compute resources
  --max-cluster-count: int # Specifies the maximum number of clusters for a multi-cluster warehouse (format: int32)
  --min-cluster-count: int # Specifies the minimum number of clusters for a multi-cluster warehouse (format: int32)
  --scaling-policy: string # Scaling policy of warehouse, possible scaling policies: STANDARD, ECONOMY
  --auto-suspend: int # time in seconds before auto suspend (format: int32)
  --auto-resume: string@auto-resume-completer # Specifies whether to automatically resume a warehouse when a SQL statement is submitted to it
  --initially-suspended: string@initially-suspended-completer # Specifies whether the warehouse is created initially in the Suspended state
  --resource-monitor: any # Specifies the name of a resource monitor that is explicitly assigned to the warehouse. When a resource monitor is explicitly assigned to a warehouse, the monitor controls the monthly credits used by the warehouse
  --comment: string # Specifies a comment for the warehouse (format: comment)
  --enable-query-acceleration: string@enable-query-acceleration-completer # Specifies whether to enable the query acceleration service for queries that rely on this warehouse for compute resources
  --query-acceleration-max-scale-factor: int # Specifies the maximum scale factor for leasing compute resources for query acceleration. The scale factor is used as a multiplier based on warehouse size (format: int32)
  --max-concurrency-level: int # Object parameter that specifies the concurrency level for SQL statements executed by a warehouse cluster (format: int32)
  --statement-queued-timeout-in-seconds: int # Object parameter that specifies the time, in seconds, a SQL statement can be queued on a warehouse before it is canceled by the system (format: int32)
  --statement-timeout-in-seconds: int # Object parameter that specifies the time, in seconds, after which a running SQL statement  is canceled by the system (format: int32)
  --type: string # [Deprecated] Type of warehouse, possible types: STANDARD, SNOWPARK-OPTIMIZED (DEPRECATED)
  --size: string # [Deprecated] names of size: X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large, 5X-Large, 6X-Large (DEPRECATED)
  --warehouse-credit-limit: int # Credit limit that are can be executed by the warehouse. (format: int64)
  --target-statement-size: string # Names of size: X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large, 5X-Large, 6X-Large
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/warehouses")
  let body = {name: $name, warehouse_type: $warehouse_type, warehouse_size: $warehouse_size, wait_for_completion: $wait_for_completion, max_cluster_count: $max_cluster_count, min_cluster_count: $min_cluster_count, scaling_policy: $scaling_policy, auto_suspend: $auto_suspend, auto_resume: $auto_resume, initially_suspended: $initially_suspended, resource_monitor: $resource_monitor, comment: $comment, enable_query_acceleration: $enable_query_acceleration, query_acceleration_max_scale_factor: $query_acceleration_max_scale_factor, max_concurrency_level: $max_concurrency_level, statement_queued_timeout_in_seconds: $statement_queued_timeout_in_seconds, statement_timeout_in_seconds: $statement_timeout_in_seconds, type: $type, size: $size, warehouse_credit_limit: $warehouse_credit_limit, target_statement_size: $target_statement_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List warehouse
#
# GET /api/v2/warehouses
# operationId: listWarehouses
export def "warehouses listWarehouses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: any, warehouse_type: string, warehouse_size: string, wait_for_completion: string, max_cluster_count: int, min_cluster_count: int, scaling_policy: string, auto_suspend: int, auto_resume: string, initially_suspended: string, resource_monitor: any, comment: string, enable_query_acceleration: string, query_acceleration_max_scale_factor: int, max_concurrency_level: int, statement_queued_timeout_in_seconds: int, statement_timeout_in_seconds: int, type: string, size: string, state: string, started_clusters: int, running: int, queued: int, is_default: bool, is_current: bool, available: string, provisioning: string, quiescing: string, other: string, created_on: string, resumed_on: string, updated_on: string, owner: string, budget: string, kind: string, owner_role_type: string, warehouse_credit_limit: int, target_statement_size: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/warehouses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Describe warehouse
#
# GET /api/v2/warehouses/{name}
# operationId: fetchWarehouse
export def "warehouses fetchWarehouse" [
  name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: any, warehouse_type: string, warehouse_size: string, wait_for_completion: string, max_cluster_count: int, min_cluster_count: int, scaling_policy: string, auto_suspend: int, auto_resume: string, initially_suspended: string, resource_monitor: any, comment: string, enable_query_acceleration: string, query_acceleration_max_scale_factor: int, max_concurrency_level: int, statement_queued_timeout_in_seconds: int, statement_timeout_in_seconds: int, type: string, size: string, state: string, started_clusters: int, running: int, queued: int, is_default: bool, is_current: bool, available: string, provisioning: string, quiescing: string, other: string, created_on: string, resumed_on: string, updated_on: string, owner: string, budget: string, kind: string, owner_role_type: string, warehouse_credit_limit: int, target_statement_size: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/warehouses/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Drop warehouse
#
# DELETE /api/v2/warehouses/{name}
# operationId: deleteWarehouse
export def "warehouses delete" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a (or alter an existing) warehouse.
#
# PUT /api/v2/warehouses/{name}
# operationId: createOrAlterWarehouse
@deprecated --flag type
@deprecated --flag size
export def "warehouses createOrAlterWarehouse" [
  name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: any # Name of warehouse
  --warehouse-type: string # Type of warehouse, possible types: STANDARD, SNOWPARK-OPTIMIZED
  --warehouse-size: string # Size of warehouse, possible sizes: XSMALL, SMALL, MEDIUM, LARGE, XLARGE, XXLARGE, XXXLARGE, X4LARGE, X5LARGE, X6LARGE
  --wait-for-completion: string@wait-for-completion-completer # When resizing a warehouse, you can use this parameter to block the return of the ALTER WAREHOUSE command until the resize has finished provisioning all its compute resources
  --max-cluster-count: int # Specifies the maximum number of clusters for a multi-cluster warehouse (format: int32)
  --min-cluster-count: int # Specifies the minimum number of clusters for a multi-cluster warehouse (format: int32)
  --scaling-policy: string # Scaling policy of warehouse, possible scaling policies: STANDARD, ECONOMY
  --auto-suspend: int # time in seconds before auto suspend (format: int32)
  --auto-resume: string@auto-resume-completer # Specifies whether to automatically resume a warehouse when a SQL statement is submitted to it
  --initially-suspended: string@initially-suspended-completer # Specifies whether the warehouse is created initially in the Suspended state
  --resource-monitor: any # Specifies the name of a resource monitor that is explicitly assigned to the warehouse. When a resource monitor is explicitly assigned to a warehouse, the monitor controls the monthly credits used by the warehouse
  --comment: string # Specifies a comment for the warehouse (format: comment)
  --enable-query-acceleration: string@enable-query-acceleration-completer # Specifies whether to enable the query acceleration service for queries that rely on this warehouse for compute resources
  --query-acceleration-max-scale-factor: int # Specifies the maximum scale factor for leasing compute resources for query acceleration. The scale factor is used as a multiplier based on warehouse size (format: int32)
  --max-concurrency-level: int # Object parameter that specifies the concurrency level for SQL statements executed by a warehouse cluster (format: int32)
  --statement-queued-timeout-in-seconds: int # Object parameter that specifies the time, in seconds, a SQL statement can be queued on a warehouse before it is canceled by the system (format: int32)
  --statement-timeout-in-seconds: int # Object parameter that specifies the time, in seconds, after which a running SQL statement  is canceled by the system (format: int32)
  --type: string # [Deprecated] Type of warehouse, possible types: STANDARD, SNOWPARK-OPTIMIZED (DEPRECATED)
  --size: string # [Deprecated] names of size: X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large, 5X-Large, 6X-Large (DEPRECATED)
  --warehouse-credit-limit: int # Credit limit that are can be executed by the warehouse. (format: int64)
  --target-statement-size: string # Names of size: X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large, 5X-Large, 6X-Large
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/warehouses/($name)")
  let body = {name: $body_name, warehouse_type: $warehouse_type, warehouse_size: $warehouse_size, wait_for_completion: $wait_for_completion, max_cluster_count: $max_cluster_count, min_cluster_count: $min_cluster_count, scaling_policy: $scaling_policy, auto_suspend: $auto_suspend, auto_resume: $auto_resume, initially_suspended: $initially_suspended, resource_monitor: $resource_monitor, comment: $comment, enable_query_acceleration: $enable_query_acceleration, query_acceleration_max_scale_factor: $query_acceleration_max_scale_factor, max_concurrency_level: $max_concurrency_level, statement_queued_timeout_in_seconds: $statement_queued_timeout_in_seconds, statement_timeout_in_seconds: $statement_timeout_in_seconds, type: $type, size: $size, warehouse_credit_limit: $warehouse_credit_limit, target_statement_size: $target_statement_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resume warehouse
#
# POST /api/v2/warehouses/{name}:resume
# operationId: resumeWarehouse
export def "warehouses resumeWarehouse" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name):resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspend warehouse
#
# POST /api/v2/warehouses/{name}:suspend
# operationId: suspendWarehouse
export def "warehouses suspendWarehouse" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name):suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update and rename warehouse
#
# POST /api/v2/warehouses/{name}:rename
# operationId: renameWarehouse
@deprecated --flag type
@deprecated --flag size
export def "warehouses renameWarehouse" [
  name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: any # Name of warehouse
  --warehouse-type: string # Type of warehouse, possible types: STANDARD, SNOWPARK-OPTIMIZED
  --warehouse-size: string # Size of warehouse, possible sizes: XSMALL, SMALL, MEDIUM, LARGE, XLARGE, XXLARGE, XXXLARGE, X4LARGE, X5LARGE, X6LARGE
  --wait-for-completion: string@wait-for-completion-completer # When resizing a warehouse, you can use this parameter to block the return of the ALTER WAREHOUSE command until the resize has finished provisioning all its compute resources
  --max-cluster-count: int # Specifies the maximum number of clusters for a multi-cluster warehouse (format: int32)
  --min-cluster-count: int # Specifies the minimum number of clusters for a multi-cluster warehouse (format: int32)
  --scaling-policy: string # Scaling policy of warehouse, possible scaling policies: STANDARD, ECONOMY
  --auto-suspend: int # time in seconds before auto suspend (format: int32)
  --auto-resume: string@auto-resume-completer # Specifies whether to automatically resume a warehouse when a SQL statement is submitted to it
  --initially-suspended: string@initially-suspended-completer # Specifies whether the warehouse is created initially in the Suspended state
  --resource-monitor: any # Specifies the name of a resource monitor that is explicitly assigned to the warehouse. When a resource monitor is explicitly assigned to a warehouse, the monitor controls the monthly credits used by the warehouse
  --comment: string # Specifies a comment for the warehouse (format: comment)
  --enable-query-acceleration: string@enable-query-acceleration-completer # Specifies whether to enable the query acceleration service for queries that rely on this warehouse for compute resources
  --query-acceleration-max-scale-factor: int # Specifies the maximum scale factor for leasing compute resources for query acceleration. The scale factor is used as a multiplier based on warehouse size (format: int32)
  --max-concurrency-level: int # Object parameter that specifies the concurrency level for SQL statements executed by a warehouse cluster (format: int32)
  --statement-queued-timeout-in-seconds: int # Object parameter that specifies the time, in seconds, a SQL statement can be queued on a warehouse before it is canceled by the system (format: int32)
  --statement-timeout-in-seconds: int # Object parameter that specifies the time, in seconds, after which a running SQL statement  is canceled by the system (format: int32)
  --type: string # [Deprecated] Type of warehouse, possible types: STANDARD, SNOWPARK-OPTIMIZED (DEPRECATED)
  --size: string # [Deprecated] names of size: X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large, 5X-Large, 6X-Large (DEPRECATED)
  --warehouse-credit-limit: int # Credit limit that are can be executed by the warehouse. (format: int64)
  --target-statement-size: string # Names of size: X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large, 5X-Large, 6X-Large
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/warehouses/($name):rename")
  let body = {name: $body_name, warehouse_type: $warehouse_type, warehouse_size: $warehouse_size, wait_for_completion: $wait_for_completion, max_cluster_count: $max_cluster_count, min_cluster_count: $min_cluster_count, scaling_policy: $scaling_policy, auto_suspend: $auto_suspend, auto_resume: $auto_resume, initially_suspended: $initially_suspended, resource_monitor: $resource_monitor, comment: $comment, enable_query_acceleration: $enable_query_acceleration, query_acceleration_max_scale_factor: $query_acceleration_max_scale_factor, max_concurrency_level: $max_concurrency_level, statement_queued_timeout_in_seconds: $statement_queued_timeout_in_seconds, statement_timeout_in_seconds: $statement_timeout_in_seconds, type: $type, size: $size, warehouse_credit_limit: $warehouse_credit_limit, target_statement_size: $target_statement_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Abort all queries
#
# POST /api/v2/warehouses/{name}:abort
# operationId: abortAllQueriesOnWarehouse
export def "warehouses abortAllQueriesOnWarehouse" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name):abort")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Use current warehouse for session
#
# POST /api/v2/warehouses/{name}:use
# DEPRECATED
# operationId: useWarehouse
@deprecated
export def "warehouses useWarehouse" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name):use")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# enable adaptive warehouse
#
# POST /api/v2/warehouses/{name}:enable
# operationId: enableWarehouse
export def "warehouses enableWarehouse" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name):enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# disable adaptive warehouse
#
# POST /api/v2/warehouses/{name}:disable
# operationId: disableWarehouse
export def "warehouses disableWarehouse" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name):disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set tags on a warehouse.
#
# POST /api/v2/warehouses/{name}:set-tags
# operationId: setTags
export def "warehouses setTags" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name):set-tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unset tags from a warehouse.
#
# POST /api/v2/warehouses/{name}:unset-tags
# operationId: unsetTags
export def "warehouses unsetTags" [
  name: any
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
  let full_url = (build-url $base $"/api/v2/warehouses/($name):unset-tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the tag assignments for a warehouse.
#
# GET /api/v2/warehouses/{name}:get-tags
# operationId: getTags
export def "warehouses get" [
  name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/warehouses/($name):get-tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
