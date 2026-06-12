# Auto-generated client for Pinecone Data Plane API v2026-04
# Source: https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/db_data_2026-04.oas.yaml
# Auth: --token flag or $env.PINECONE_DATA_PLANE_API_TOKEN

const BASE_URL = "https://unknown"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PINECONE_DATA_PLANE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {Api-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://unknown"] }
def auth-scheme-completer [] { ["api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bulk-imports listBulkImports" } } | get name | first)
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

# List imports
#
# GET /bulk/imports
# operationId: listBulkImports
export def "bulk-imports listBulkImports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max number of operations to return per page. (format: int32, default: 100, e.g. 10)
  --paginationToken: string # Pagination token to continue a previous listing operation.
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<data: table<id: string, uri: string, status: string, createdAt: string, finishedAt: string, percentComplete: float, recordsImported: int, error: string>, pagination: record<next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "paginationToken" $paginationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk/imports" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start import
#
# POST /bulk/imports
# operationId: startBulkImport
# --errorMode shape: {onError?: string}
export def "bulk-imports startBulkImport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --integrationId: string # The id of the [storage integration](https://docs.pinecone.io/guides/operations/integrations/manage-storage-integrations) that should be used to access the data.
  uri: string # The URI of the bucket (or container) and import directory containing the namespaces and Parquet files you want to import. For example, `s3://BUCKET_NAME/IMPORT_DIR` for Amazon S3, `gs://BUCKET_NAME/IMPORT_DIR` for Google Cloud Storage, or `https://STORAGE_ACCOUNT.blob.core.windows.net/CONTAINER_NAME/IMPORT_DIR` for Azure Blob Storage. For more information, see [Import records](https://docs.pinecone.io/guides/index-data/import-data#prepare-your-data).
  --errorMode: record # Indicates how to respond to errors during the import process. — shape: {onError?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk/imports")
  let body = {integrationId: $integrationId, uri: $uri, errorMode: $errorMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describe an import
#
# GET /bulk/imports/{id}
# operationId: describeBulkImport
export def "bulk-imports describeBulkImport" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<id: string, uri: string, status: string, createdAt: string, finishedAt: string, percentComplete: float, recordsImported: int, error: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulk/imports/($id)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an import
#
# DELETE /bulk/imports/{id}
# operationId: cancelBulkImport
export def "bulk-imports cancelBulkImport" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulk/imports/($id)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get index stats
#
# POST /describe_index_stats
# operationId: describeIndexStats
export def "describe-index-stats describeIndexStats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --filter: record # If this parameter is present, the operation only returns statistics for vectors that satisfy the filter. See [Understanding metadata](https://docs.pinecone.io/guides/index-data/indexing-overview#metadata).  Serverless indexes do not support filtering `describe_index_stats` by metadata.
]: any -> record<namespaces: record, dimension: int, indexFullness: float, totalVectorCount: int, metric: string, vectorType: string, memory_fullness: float, storage_fullness: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/describe_index_stats")
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search with a vector
#
# POST /query
# operationId: queryVectors
# --queries item shape: {values: list, sparseValues?: record, topK?: int, namespace?: string, filter?: record}
# --sparseVector shape: {indices: list, values: list}
@deprecated --flag queries
export def "query queryVectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --namespace: string # The namespace to query. (e.g. example-namespace)
  topK: int # The number of results to return for each query. (format: int64, e.g. 10)
  --filter: record # The filter to apply. You can use vector metadata to limit your search. See [Understanding metadata](https://docs.pinecone.io/guides/index-data/indexing-overview#metadata). (e.g. {genre: {$in: [comedy, documentary, drama]}, year: {$eq: 2019}})
  --includeValues: oneof<nothing, bool> # Indicates whether vector values are included in the response. For on-demand indexes, setting this to `true` may increase latency, especially with higher `topK` values, because vector values are retrieved from object storage. Unless you need vector values, set this to `false` for better performance. (default: false, e.g. true)
  --includeMetadata: oneof<nothing, bool> # Indicates whether metadata is included in the response as well as the ids. (default: false, e.g. true)
  --queries: list # DEPRECATED. Use `vector` or `id` instead. (DEPRECATED) — item shape: {values: list, sparseValues?: record, topK?: int, namespace?: string, filter?: record}
  --vector: list # The query vector. This should be the same length as the dimension of the index being queried. Each `query` request can contain only one of the parameters `id` or `vector`. (e.g. [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8])
  --sparseVector: record # Vector sparse data. Represented as a list of indices and a list of  corresponded values, which must be with the same length. — shape: {indices: list, values: list}
  --id: string # The unique ID of the vector to be used as a query vector. Each request can contain either the `vector` or `id` parameter. (e.g. example-vector-1)
  --scanFactor: float # An optimization parameter for IVF dense indexes in dedicated read node indexes. It adjusts how much of the index is scanned to find vector candidates. Range: 0.5 – 4 (default). Keep the default (4.0) for the best search results. If query latency is too high, try lowering this value incrementally (minimum 0.5) to speed up the search at the cost of slightly lower accuracy. This parameter is only supported for dedicated (DRN) dense indexes. (format: float, e.g. 2.0)
  --maxCandidates: int # An optimization parameter that controls the maximum number of candidate dense vectors to rerank. Reranking computes exact distances to improve recall but increases query latency. Range: top_k – 100000. Keep the default for a balance of recall and latency. Increase this value if recall is too low, or decrease it to reduce latency at the cost of accuracy. This parameter is only supported for dedicated (DRN) dense indexes. (format: int64, e.g. 1000)
]: any -> record<results: table<matches: list, namespace: string>, matches: table<id: string, score: float, values: list, sparseValues: record, metadata: record>, namespace: string, usage: record<readUnits: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query")
  let body = {namespace: $namespace, topK: $topK, filter: $filter, includeValues: $includeValues, includeMetadata: $includeMetadata, queries: $queries, vector: $vector, sparseVector: $sparseVector, id: $id, scanFactor: $scanFactor, maxCandidates: $maxCandidates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete records
#
# POST /vectors/delete
# operationId: deleteVectors
export def "vectors-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --ids: list # Vectors to delete. (e.g. [id-0, id-1])
  --deleteAll: oneof<nothing, bool> # This indicates that all vectors in the index namespace should be deleted. (default: false, e.g. false)
  --namespace: string # The namespace to delete records from, if applicable. (e.g. example-namespace)
  --filter: record # If specified, the metadata filter here will be used to select the vectors to delete. This is mutually exclusive with specifying ids to delete in the ids param or using delete_all=True. See [Delete data](https://docs.pinecone.io/guides/manage-data/delete-data#delete-records-by-metadata).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vectors/delete")
  let body = {ids: $ids, deleteAll: $deleteAll, namespace: $namespace, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch records
#
# GET /vectors/fetch
# operationId: fetchVectors
export def "vectors-fetch fetchVectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The vector IDs to fetch. Does not accept values containing spaces.
  --namespace: string # The namespace to fetch records from. If not provided, the default namespace is used.
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<vectors: record, namespace: string, usage: record<readUnits: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vectors/fetch" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch records by metadata
#
# POST /vectors/fetch_by_metadata
# operationId: fetch_vectors_by_metadata
export def "vectors-fetch-by-metadata metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --namespace: string # The namespace to fetch records from. (e.g. example-namespace)
  --filter: record # Metadata filter expression to select vectors. See [Understanding metadata](https://docs.pinecone.io/guides/index-data/indexing-overview#metadata). (e.g. {genre: {$in: [comedy, documentary, drama]}, year: {$eq: 2019}})
  --limit: int # Max number of vectors to return. (format: int64, default: 100, e.g. 12)
  --paginationToken: string # Pagination token to continue a previous listing operation. (e.g. Tm90aGluZyB0byBzZWUgaGVyZQo=)
]: any -> record<vectors: record, namespace: string, usage: record<readUnits: int>, pagination: record<next: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vectors/fetch_by_metadata")
  let body = {namespace: $namespace, filter: $filter, limit: $limit, paginationToken: $paginationToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List record IDs
#
# GET /vectors/list
# operationId: listVectors
export def "vectors-list listVectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prefix: string # The vector IDs to fetch. Does not accept values containing spaces.
  --limit: int # Max number of IDs to return per page. (format: int64, default: 100)
  --paginationToken: string # Pagination token to continue a previous listing operation.
  --namespace: string # The namespace to list vectors from. If not provided, the default namespace is used.
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<vectors: table<id: string>, pagination: record<next: string>, namespace: string, usage: record<readUnits: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefix" $prefix "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "paginationToken" $paginationToken "scalar") (serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vectors/list" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a record
#
# POST /vectors/update
# operationId: updateVector
# --sparseValues shape: {indices: list, values: list}
export def "vectors-update updateVector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --id: string # Vector's unique id. (e.g. example-vector-1)
  --values: list # Vector data. (e.g. [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8])
  --sparseValues: record # Vector sparse data. Represented as a list of indices and a list of  corresponded values, which must be with the same length. — shape: {indices: list, values: list}
  --setMetadata: record # Metadata to set for the record. (e.g. {genre: documentary, year: 2019})
  --namespace: string # The namespace containing the record to update. (e.g. example-namespace)
  --filter: record # A metadata filter expression. When updating metadata across records in a namespace,  the update is applied to all records that match the filter.  See [Understanding metadata](https://docs.pinecone.io/guides/index-data/indexing-overview#metadata). (e.g. {genre: {$in: [comedy, documentary, drama]}, year: {$eq: 2019}})
  --dryRun: oneof<nothing, bool> # If `true`, return the number of records that match the `filter`, but do not execute the update.  Default is `false`. (default: false, e.g. false)
]: any -> record<matchedRecords: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vectors/update")
  let body = {id: $id, values: $values, sparseValues: $sparseValues, setMetadata: $setMetadata, namespace: $namespace, filter: $filter, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert records
#
# POST /vectors/upsert
# operationId: upsertVectors
# --vectors item shape: {id: string, values?: list, sparseValues?: record, metadata?: record}
export def "vectors-upsert upsertVectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  vectors: list # An array containing the vectors to upsert. Recommended batch limit is up to 1000 vectors. — item shape: {id: string, values?: list, sparseValues?: record, metadata?: record}
  --namespace: string # The namespace where you upsert records. (e.g. example-namespace)
]: any -> record<upsertedCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vectors/upsert")
  let body = {vectors: $vectors, namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List namespaces
#
# GET /namespaces
# operationId: listNamespacesOperation
export def "namespaces listNamespacesOperation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max number namespaces to return per page. (format: int32, e.g. 10)
  --paginationToken: string # Pagination token to continue a previous listing operation.
  --prefix: string # Prefix of the namespaces to list. Acts as a filter to return only namespaces that start with this prefix. (e.g. prefixExample)
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<namespaces: table<name: string, record_count: int, schema: record, indexed_fields: record>, pagination: record<next: string>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "paginationToken" $paginationToken "scalar") (serialize-qp "prefix" $prefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/namespaces" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a namespace
#
# POST /namespaces
# operationId: createNamespace
# --schema shape: {fields: record}
export def "namespaces createNamespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  name: string # The name of the namespace. (e.g. example-namespace)
  --schema: record # Schema for the behavior of Pinecone's internal metadata index. By default, all metadata is indexed; when `schema` is present, only fields which are present in the `fields` object with a `filterable: true` are indexed. Note that `filterable: false` is not currently supported. (e.g. {fields: {description: {filterable: true}, genre: {filterable: true}, year: {filterable: true}}}) — shape: {fields: record}
]: any -> record<name: string, record_count: int, schema: record<fields: record>, indexed_fields: record<fields: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/namespaces")
  let body = {name: $name, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describe a namespace
#
# GET /namespaces/{namespace}
# operationId: describeNamespace
export def "namespaces describeNamespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<name: string, record_count: int, schema: record<fields: record>, indexed_fields: record<fields: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a namespace
#
# DELETE /namespaces/{namespace}
# operationId: deleteNamespace
export def "namespaces delete" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert text
#
# POST /records/namespaces/{namespace}/upsert
# operationId: upsertRecordsNamespace
export def "records-namespaces-upsert upsertRecordsNamespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/records/namespaces/($namespace)/upsert")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-ndjson" $body
}

# Search with text
#
# POST /records/namespaces/{namespace}/search
# operationId: searchRecordsNamespace
# --query shape: {top_k: int, filter?: record, inputs?: record, vector?: record, id?: string, match_terms?: record}
# --rerank shape: {model: string, rank_fields: list, top_n?: int, parameters?: record, query?: string}
export def "records-namespaces-search searchRecordsNamespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --body-query: record # . — shape: {top_k: int, filter?: record, inputs?: record, vector?: record, id?: string, match_terms?: record}
  --body-fields: list # The fields to return in the search results. If not specified, the response will include all fields. (e.g. [chunk_text])
  --rerank: record # Parameters for reranking the initial search results. — shape: {model: string, rank_fields: list, top_n?: int, parameters?: record, query?: string}
]: any -> record<result: record<hits: list<record>>, usage: record<read_units: int, embed_total_tokens: int, rerank_units: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/records/namespaces/($namespace)/search")
  let body = {query: $body_query, fields: $body_fields, rerank: $rerank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
