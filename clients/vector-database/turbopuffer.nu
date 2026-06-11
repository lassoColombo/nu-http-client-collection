# Auto-generated client for turbopuffer API v0.0.1
# Source: https://raw.githubusercontent.com/turbopuffer/turbopuffer-openapi/next/openapi.yml
# Auth: --token flag or $env.TURBOPUFFER_API_TOKEN

const BASE_URL = "https://.turbopuffer.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TURBOPUFFER_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://.turbopuffer.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "namespaces get" } } | get name | first)
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

# List namespaces.
#
# GET /v1/namespaces
export def "namespaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Retrieve the next page of results.
  --prefix: string # Retrieve only the namespaces that match the prefix.
  --page-size: int # Limit the number of results per page. (format: int32)
]: nothing -> record<namespaces: table<id: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get namespace schema.
#
# GET /v1/namespaces/{namespace}/schema
export def "namespaces-schema get" [
  namespace: string
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
  let full_url = (build-url $base $"/v1/namespaces/($namespace)/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update namespace schema.
#
# POST /v1/namespaces/{namespace}/schema
export def "namespaces-schema post" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/namespaces/($namespace)/schema")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metadata about a namespace.
#
# GET /v2/namespaces/{namespace}/metadata
export def "namespaces-metadata get" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<schema: record, approx_row_count: int, approx_logical_bytes: int, created_at: string, updated_at: string, encryption: any, index: any, pinning: record<replicas: int, status: record<updated_at: string, ready_replicas: int, utilization: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/namespaces/($namespace)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update metadata configuration for a namespace.
#
# PATCH /v1/namespaces/{namespace}/metadata
export def "namespaces-metadata patch" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pinning: any # Configuration for namespace pinning. - Missing field: no change to pinning configuration - `null` or `false`: explicitly remove pinning - `true`: enable pinning with default configuration - Object: set pinning configuration
]: any -> record<schema: record, approx_row_count: int, approx_logical_bytes: int, created_at: string, updated_at: string, encryption: any, index: any, pinning: record<replicas: int, status: record<updated_at: string, ready_replicas: int, utilization: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/namespaces/($namespace)/metadata")
  let body = {pinning: $pinning} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Signal turbopuffer to prepare for low-latency requests.
#
# GET /v1/namespaces/{namespace}/hint_cache_warm
export def "namespaces-hint-cache-warm get" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: any, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/namespaces/($namespace)/hint_cache_warm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluate recall.
#
# POST /v1/namespaces/{namespace}/_debug/recall
export def "namespaces-debug-recall post" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --num: int # The number of searches to run.
  --top-k: int # Search for `top_k` nearest neighbors.
  --filters: any # Filter by attributes. Same syntax as the query endpoint.
  --include-ground-truth: string@bool-completer # Include ground truth data (query vectors and true nearest neighbors) in the response. (default: false)
  --rank-by: any # The ranking function to evaluate recall for. If provided, `num` must be either null or 1.
]: any -> record<avg_recall: float, avg_exhaustive_count: float, avg_ann_count: float, ground_truth: table<query_vector: list, nearest_neighbors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/namespaces/($namespace)/_debug/recall")
  let body = {num: $num, top_k: $top_k, filters: $filters, include_ground_truth: $include_ground_truth, rank_by: $rank_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create, update, or delete documents.
#
# POST /v2/namespaces/{namespace}
# --upsert_columns shape: {id: list, vector?: any}
# --upsert_rows item shape: {id: any, vector?: any}
# --patch_columns shape: {id: list, vector?: any}
# --patch_rows item shape: {id: any, vector?: any}
# --patch_by_filter shape: {patch: record, filters: any}
export def "namespaces post-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --upsert-columns: record # A list of documents in columnar format. Each key is a column name, mapped to an array of values for that column. — shape: {id: list, vector?: any}
  --upsert-rows: list # item shape: {id: any, vector?: any}
  --patch-columns: record # A list of documents in columnar format. Each key is a column name, mapped to an array of values for that column. — shape: {id: list, vector?: any}
  --patch-rows: list # item shape: {id: any, vector?: any}
  --deletes: list
  --upsert-condition: any # A condition evaluated against the current value of each document targeted by an upsert write. Only documents that pass the condition are upserted.
  --patch-condition: any # A condition evaluated against the current value of each document targeted by a patch write. Only documents that pass the condition are patched.
  --delete-condition: any # A condition evaluated against the current value of each document targeted by a delete write. Only documents that pass the condition are deleted.
  --distance-metric: any # A function used to calculate vector similarity.
  --schema: record # The schema of the attributes attached to the documents.
  --branch-from-namespace: any
  --copy-from-namespace: any
  --delete-by-filter: any # The filter specifying which documents to delete.
  --delete-by-filter-allow-partial: string@bool-completer # Allow partial completion when filter matches too many documents.
  --patch-by-filter: any # The patch and filter specifying which documents to patch. — shape: {patch: record, filters: any}
  --patch-by-filter-allow-partial: string@bool-completer # Allow partial completion when filter matches too many documents.
  --return-affected-ids: string@bool-completer # If true, return the IDs of affected rows (deleted, patched, upserted) in the response. For filtered and conditional writes, only IDs for writes that succeeded will be included.  (default: false)
  --encryption: any # The encryption configuration for a namespace.
  --disable-backpressure: string@bool-completer # Disables write throttling (HTTP 429 responses) during high-volume ingestion.
]: any -> record<status: any, message: string, rows_affected: int, rows_upserted: int, rows_patched: int, rows_deleted: int, rows_remaining: bool, upserted_ids: list<any>, patched_ids: list<any>, deleted_ids: list<any>, billing: record<billable_logical_bytes_written: int, query: record<billable_logical_bytes_queried: int, billable_logical_bytes_returned: int>>, performance: record<server_total_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/namespaces/($namespace)")
  let body = {upsert_columns: $upsert_columns, upsert_rows: $upsert_rows, patch_columns: $patch_columns, patch_rows: $patch_rows, deletes: $deletes, upsert_condition: $upsert_condition, patch_condition: $patch_condition, delete_condition: $delete_condition, distance_metric: $distance_metric, schema: $schema, branch_from_namespace: $branch_from_namespace, copy_from_namespace: $copy_from_namespace, delete_by_filter: $delete_by_filter, delete_by_filter_allow_partial: $delete_by_filter_allow_partial, patch_by_filter: $patch_by_filter, patch_by_filter_allow_partial: $patch_by_filter_allow_partial, return_affected_ids: $return_affected_ids, encryption: $encryption, disable_backpressure: $disable_backpressure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete namespace.
#
# DELETE /v2/namespaces/{namespace}
export def "namespaces delete" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/namespaces/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query, filter, full-text search and vector search documents.
#
# POST /v2/namespaces/{namespace}/query
# --consistency shape: {level?: any}
export def "namespaces-query post" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vector-encoding: any # The encoding to use for vectors in the response.
  --consistency: record # The consistency level for a query. — shape: {level?: any}
  --rank-by: any # How to rank the documents in the namespace.
  --top-k: int # The number of results to return.
  --filters: any # Exact filters for attributes to refine search results for. Think of it as a SQL WHERE clause.
  --include-attributes: any # Whether to include attributes in the response.
  --exclude-attributes: list # List of attribute names to exclude from the response. All other attributes will be included in the response.
  --aggregate-by: record # Aggregations to compute over all documents in the namespace that match the filters.
  --group-by: list # Groups documents by the specified attributes (the "group key") before computing aggregates. Aggregates are computed separately for each group.
  --distance-metric: any # A function used to calculate vector similarity.
  --limit: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/namespaces/($namespace)/query")
  let body = {vector_encoding: $vector_encoding, consistency: $consistency, rank_by: $rank_by, top_k: $top_k, filters: $filters, include_attributes: $include_attributes, exclude_attributes: $exclude_attributes, aggregate_by: $aggregate_by, group_by: $group_by, distance_metric: $distance_metric, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Issue multiple concurrent queries filter or search documents.
#
# POST /v2/namespaces/{namespace}/query?stainless_overload=multiQuery
# --consistency shape: {level?: any}
# --queries item shape: {rank_by?: any, top_k?: int, filters?: any, include_attributes?: any, exclude_attributes?: list, aggregate_by?: record, group_by?: list, distance_metric?: any, limit?: any}
export def "namespaces-query-stainless-overloadmulti-query post" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vector-encoding: any # The encoding to use for vectors in the response.
  --consistency: record # The consistency level for a query. — shape: {level?: any}
  queries: list # item shape: {rank_by?: any, top_k?: int, filters?: any, include_attributes?: any, exclude_attributes?: list, aggregate_by?: record, group_by?: list, distance_metric?: any, limit?: any}
  --rerank-by: any # How to combine the rows returned by each sub-query into a single ranked list.
]: any -> record<results: table<aggregations: record, aggregation_groups: list, rows: list>, performance: record<cache_hit_ratio: float, cache_temperature: string, server_total_ms: int, query_execution_ms: int, exhaustive_search_count: int, approx_namespace_size: int>, billing: record<billable_logical_bytes_queried: int, billable_logical_bytes_returned: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/namespaces/($namespace)/query?stainless_overload=multiQuery")
  let body = {vector_encoding: $vector_encoding, consistency: $consistency, queries: $queries, rerank_by: $rerank_by} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an instant, copy-on-write clone of a namespace.
#
# POST /v2/namespaces/{namespace}?stainless_overload=branchFrom
export def "namespaces post-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_namespace: string # The namespace to create an instant, copy-on-write clone of.
]: any -> record<status: any, message: string, rows_affected: int, rows_upserted: int, rows_patched: int, rows_deleted: int, rows_remaining: bool, upserted_ids: list<any>, patched_ids: list<any>, deleted_ids: list<any>, billing: record<billable_logical_bytes_written: int, query: record<billable_logical_bytes_queried: int, billable_logical_bytes_returned: int>>, performance: record<server_total_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/namespaces/($namespace)?stainless_overload=branchFrom")
  let body = {source_namespace: $source_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Copy all documents from another namespace into this one.
#
# POST /v2/namespaces/{namespace}?stainless_overload=copyFrom
export def "namespaces post-by-namespace-2" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_namespace: string # The namespace to copy documents from.
  --source-api-key: string # (Optional) An API key for the organization containing the source namespace
  --source-region: string # (Optional) The region of the source namespace.
  --dest-encryption: any # The encryption configuration for a namespace.
]: any -> record<status: any, message: string, rows_affected: int, rows_upserted: int, rows_patched: int, rows_deleted: int, rows_remaining: bool, upserted_ids: list<any>, patched_ids: list<any>, deleted_ids: list<any>, billing: record<billable_logical_bytes_written: int, query: record<billable_logical_bytes_queried: int, billable_logical_bytes_returned: int>>, performance: record<server_total_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/namespaces/($namespace)?stainless_overload=copyFrom")
  let body = {source_namespace: $source_namespace, source_api_key: $source_api_key, source_region: $source_region, dest_encryption: $dest_encryption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Explain a query plan.
#
# POST /v2/namespaces/{namespace}/explain_query
# --consistency shape: {level?: any}
export def "namespaces-explain-query post" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vector-encoding: any # The encoding to use for vectors in the response.
  --consistency: record # The consistency level for a query. — shape: {level?: any}
  --rank-by: any # How to rank the documents in the namespace.
  --top-k: int # The number of results to return.
  --filters: any # Exact filters for attributes to refine search results for. Think of it as a SQL WHERE clause.
  --include-attributes: any # Whether to include attributes in the response.
  --exclude-attributes: list # List of attribute names to exclude from the response. All other attributes will be included in the response.
  --aggregate-by: record # Aggregations to compute over all documents in the namespace that match the filters.
  --group-by: list # Groups documents by the specified attributes (the "group key") before computing aggregates. Aggregates are computed separately for each group.
  --distance-metric: any # A function used to calculate vector similarity.
  --limit: any
]: any -> record<plan_text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/namespaces/($namespace)/explain_query")
  let body = {vector_encoding: $vector_encoding, consistency: $consistency, rank_by: $rank_by, top_k: $top_k, filters: $filters, include_attributes: $include_attributes, exclude_attributes: $exclude_attributes, aggregate_by: $aggregate_by, group_by: $group_by, distance_metric: $distance_metric, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
