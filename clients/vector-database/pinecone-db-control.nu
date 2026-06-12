# Auto-generated client for Pinecone Control Plane API v2026-04
# Source: https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/db_control_2026-04.oas.yaml
# Auth: --token flag or $env.PINECONE_CONTROL_PLANE_API_TOKEN

const BASE_URL = "https://api.pinecone.io"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PINECONE_CONTROL_PLANE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.pinecone.io"] }
def auth-scheme-completer [] { ["api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "indexes indexes" } } | get name | first)
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

# List indexes
#
# GET /indexes
# operationId: list_indexes
export def "indexes indexes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<indexes: table<name: string, dimension: int, metric: string, host: string, private_host: string, deletion_protection: string, tags: record, embed: record, spec: record, status: record, vector_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/indexes")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an index
#
# POST /indexes
# operationId: create_index
# --spec shape: {serverless?: record, pod?: record, byoc?: record}
export def "indexes index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
  name: string # The name of the index. Resource name must be 1-45 characters long, start and end with an alphanumeric character, and consist only of lower case alphanumeric characters or '-'.  (e.g. example-index)
  --dimension: int # The dimensions of the vectors to be inserted in the index. (format: int32, e.g. 1536)
  --metric: string # The distance metric to be used for similarity search. You can use 'euclidean', 'cosine', or 'dotproduct'. If the 'vector_type' is 'sparse', the metric must be 'dotproduct'. If the `vector_type` is `dense`, the metric defaults to 'cosine'. Possible values: `cosine`, `euclidean`, or `dotproduct`.
  --deletion-protection: string # Whether [deletion protection](http://docs.pinecone.io/guides/manage-data/manage-indexes#configure-deletion-protection) is enabled/disabled for the index. Possible values: `disabled` or `enabled`. (default: disabled)
  --tags: record # Custom user tags added to an index. Keys must be 80 characters or less. Values must be 120 characters or less. Keys must be alphanumeric, '_', or '-'.  Values must be alphanumeric, ';', '@', '_', '-', '.', '+', or ' '. To unset a key, set the value to be an empty string. (e.g. {tag0: val0, tag1: val1})
  spec: record # The spec object defines how the index should be deployed.  For serverless indexes, you define only the [cloud and region](http://docs.pinecone.io/guides/index-data/create-an-index#cloud-regions) where the index should be hosted. For pod-based indexes, you define the [environment](http://docs.pinecone.io/guides/indexes/pods/understanding-pod-based-indexes#pod-environments) where the index should be hosted, the [pod type and size](http://docs.pinecone.io/guides/indexes/pods/understanding-pod-based-indexes#pod-types) to use, and other index characteristics. — shape: {serverless?: record, pod?: record, byoc?: record}
  --vector-type: string # The index vector type. You can use 'dense' or 'sparse'. If 'dense', the vector dimension must be specified.  If 'sparse', the vector dimension should not be specified. (default: dense)
]: any -> record<name: string, dimension: int, metric: string, host: string, private_host: string, deletion_protection: string, tags: record, embed: record<model: string, metric: string, dimension: int, vector_type: string, field_map: record, read_parameters: record, write_parameters: record>, spec: record, status: record<ready: bool, state: string>, vector_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/indexes")
  let body = {name: $name, dimension: $dimension, metric: $metric, deletion_protection: $deletion_protection, tags: $tags, spec: $spec, vector_type: $vector_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describe an index
#
# GET /indexes/{index_name}
# operationId: describe_index
export def "indexes index-by-index_name" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<name: string, dimension: int, metric: string, host: string, private_host: string, deletion_protection: string, tags: record, embed: record<model: string, metric: string, dimension: int, vector_type: string, field_map: record, read_parameters: record, write_parameters: record>, spec: record, status: record<ready: bool, state: string>, vector_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($index_name)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an index
#
# DELETE /indexes/{index_name}
# operationId: delete_index
export def "indexes index-by-index_name-1" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($index_name)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure an index
#
# PATCH /indexes/{index_name}
# operationId: configure_index
# --embed shape: {model?: string, field_map?: record, read_parameters?: record, write_parameters?: record}
export def "indexes index-by-index_name-2" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
  --spec: any # The spec object defines how the index should be deployed.  Only some attributes of an index's spec may be updated.  In general, you can modify settings related to scaling and  configuration but you cannot change the cloud or region  where the index is hosted.
  --deletion-protection: string # Whether [deletion protection](http://docs.pinecone.io/guides/manage-data/manage-indexes#configure-deletion-protection) is enabled/disabled for the index. Possible values: `disabled` or `enabled`. (default: disabled)
  --tags: record # Custom user tags added to an index. Keys must be 80 characters or less. Values must be 120 characters or less. Keys must be alphanumeric, '_', or '-'.  Values must be alphanumeric, ';', '@', '_', '-', '.', '+', or ' '. To unset a key, set the value to be an empty string. (e.g. {tag0: val0, tag1: val1})
  --embed: record # Configure the integrated inference embedding settings for this index.  You can convert an existing index to an integrated index by specifying the embedding model and field_map. The index vector type and dimension must match the model vector type and dimension, and the index similarity metric must be supported by the model. Refer to the [model guide](https://docs.pinecone.io/guides/index-data/create-an-index#embedding-models) for available models and model details.  You can later change the embedding configuration to update the field map, read parameters, or write parameters. Once set, the model cannot be changed. (e.g. {field_map: {text: your-text-field}, model: multilingual-e5-large, read_parameters: {input_type: query, truncate: NONE}, write_parameters: {input_type: passage}}) — shape: {model?: string, field_map?: record, read_parameters?: record, write_parameters?: record}
]: any -> record<name: string, dimension: int, metric: string, host: string, private_host: string, deletion_protection: string, tags: record, embed: record<model: string, metric: string, dimension: int, vector_type: string, field_map: record, read_parameters: record, write_parameters: record>, spec: record, status: record<ready: bool, state: string>, vector_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($index_name)")
  let body = {spec: $spec, deletion_protection: $deletion_protection, tags: $tags, embed: $embed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List backups for an index
#
# GET /indexes/{index_name}/backups
# operationId: list_index_backups
export def "indexes-backups backups" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of results to return per page. (default: 10)
  --paginationToken: string # The token to use to retrieve the next page of results.
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<data: table<backup_id: string, source_index_name: string, source_index_id: string, name: string, description: string, status: string, cloud: string, region: string, dimension: int, metric: string, schema: record, record_count: int, namespace_count: int, size_bytes: int, tags: record, created_at: string>, pagination: record<next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "paginationToken" $paginationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/indexes/($index_name)/backups" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a backup of an index
#
# POST /indexes/{index_name}/backups
# operationId: create_backup
export def "indexes-backups backup" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
  --name: string # The name of the backup.
  --description: string # A description of the backup.
]: any -> record<backup_id: string, source_index_name: string, source_index_id: string, name: string, description: string, status: string, cloud: string, region: string, dimension: int, metric: string, schema: record<fields: record>, record_count: int, namespace_count: int, size_bytes: int, tags: record, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($index_name)/backups")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List collections
#
# GET /collections
# operationId: list_collections
export def "collections collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<collections: table<name: string, size: int, status: string, dimension: int, vector_count: int, environment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a collection
#
# POST /collections
# operationId: create_collection
export def "collections collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
  name: string # The name of the collection to be created. Resource name must be 1-45 characters long, start and end with an alphanumeric character, and consist only of lower case alphanumeric characters or '-'.
  --body-source: string # The name of the index to be used as the source for the collection. (e.g. example-source-index)
]: any -> record<name: string, size: int, status: string, dimension: int, vector_count: int, environment: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections")
  let body = {name: $name, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an index with integrated embedding
#
# POST /indexes/create-for-model
# operationId: create_index_for_model
# --schema shape: {fields: record}
# --embed shape: {model: string, metric?: string, field_map: record, dimension?: int, read_parameters?: record, write_parameters?: record}
export def "indexes-create-for-model model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
  name: string # The name of the index. Resource name must be 1-45 characters long, start and end with an alphanumeric character, and consist only of lower case alphanumeric characters or '-'.  (e.g. example-index)
  cloud: string # The public cloud where you would like your index hosted. Possible values: `gcp`, `aws`, or `azure`. (e.g. aws)
  region: string # The region where you would like your index to be created. (e.g. us-east-1)
  --deletion-protection: string # Whether [deletion protection](http://docs.pinecone.io/guides/manage-data/manage-indexes#configure-deletion-protection) is enabled/disabled for the index. Possible values: `disabled` or `enabled`. (default: disabled)
  --tags: record # Custom user tags added to an index. Keys must be 80 characters or less. Values must be 120 characters or less. Keys must be alphanumeric, '_', or '-'.  Values must be alphanumeric, ';', '@', '_', '-', '.', '+', or ' '. To unset a key, set the value to be an empty string. (e.g. {tag0: val0, tag1: val1})
  --schema: record # Schema for the behavior of Pinecone's internal metadata index. By default, all metadata is indexed; when `schema` is present, only fields which are present in the `fields` object with a `filterable: true` are indexed. Note that `filterable: false` is not currently supported. (e.g. {fields: {description: {filterable: true}, genre: {filterable: true}, year: {filterable: true}}}) — shape: {fields: record}
  --read-capacity: any # By default the index will be created with read capacity  mode `OnDemand`. If you prefer to allocate dedicated read  nodes for your workload, you must specify mode `Dedicated` and additional configurations for `node_type` and `scaling`.
  embed: record # Specify the integrated inference embedding configuration for the index.  Once set the model cannot be changed, but you can later update the embedding configuration for an integrated inference index including field map, read parameters, or write parameters.  Refer to the [model guide](https://docs.pinecone.io/guides/index-data/create-an-index#embedding-models) for available models and model details. (e.g. {field_map: {text: your-text-field}, metric: cosine, model: multilingual-e5-large, read_parameters: {input_type: query, truncate: NONE}, write_parameters: {input_type: passage}}) — shape: {model: string, metric?: string, field_map: record, dimension?: int, read_parameters?: record, write_parameters?: record}
]: any -> record<name: string, dimension: int, metric: string, host: string, private_host: string, deletion_protection: string, tags: record, embed: record<model: string, metric: string, dimension: int, vector_type: string, field_map: record, read_parameters: record, write_parameters: record>, spec: record, status: record<ready: bool, state: string>, vector_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/indexes/create-for-model")
  let body = {name: $name, cloud: $cloud, region: $region, deletion_protection: $deletion_protection, tags: $tags, schema: $schema, read_capacity: $read_capacity, embed: $embed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List backups for all indexes in a project
#
# GET /backups
# operationId: list_project_backups
export def "backups backups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of results to return per page. (default: 10)
  --paginationToken: string # The token to use to retrieve the next page of results.
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<data: table<backup_id: string, source_index_name: string, source_index_id: string, name: string, description: string, status: string, cloud: string, region: string, dimension: int, metric: string, schema: record, record_count: int, namespace_count: int, size_bytes: int, tags: record, created_at: string>, pagination: record<next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "paginationToken" $paginationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/backups" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describe a backup
#
# GET /backups/{backup_id}
# operationId: describe_backup
export def "backups backup-by-backup_id" [
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<backup_id: string, source_index_name: string, source_index_id: string, name: string, description: string, status: string, cloud: string, region: string, dimension: int, metric: string, schema: record<fields: record>, record_count: int, namespace_count: int, size_bytes: int, tags: record, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/backups/($backup_id)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a backup
#
# DELETE /backups/{backup_id}
# operationId: delete_backup
export def "backups backup-by-backup_id-1" [
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/backups/($backup_id)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an index from a backup
#
# POST /backups/{backup_id}/create-index
# operationId: create_index_from_backup_operation
export def "backups-create-index operation" [
  backup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
  name: string # The name of the index. Resource name must be 1-45 characters long, start and end with an alphanumeric character, and consist only of lower case alphanumeric characters or '-'.  (e.g. example-index)
  --tags: record # Custom user tags added to an index. Keys must be 80 characters or less. Values must be 120 characters or less. Keys must be alphanumeric, '_', or '-'.  Values must be alphanumeric, ';', '@', '_', '-', '.', '+', or ' '. To unset a key, set the value to be an empty string. (e.g. {tag0: val0, tag1: val1})
  --deletion-protection: string # Whether [deletion protection](http://docs.pinecone.io/guides/manage-data/manage-indexes#configure-deletion-protection) is enabled/disabled for the index. Possible values: `disabled` or `enabled`. (default: disabled)
]: any -> record<restore_job_id: string, index_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/backups/($backup_id)/create-index")
  let body = {name: $name, tags: $tags, deletion_protection: $deletion_protection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List restore jobs
#
# GET /restore-jobs
# operationId: list_restore_jobs
export def "restore-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of results to return per page. (default: 10)
  --paginationToken: string # The token to use to retrieve the next page of results.
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<data: table<restore_job_id: string, backup_id: string, target_index_name: string, target_index_id: string, status: string, created_at: string, completed_at: string, percent_complete: float>, pagination: record<next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "paginationToken" $paginationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restore-jobs" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describe a restore job
#
# GET /restore-jobs/{job_id}
# operationId: describe_restore_job
export def "restore-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<restore_job_id: string, backup_id: string, target_index_name: string, target_index_id: string, status: string, created_at: string, completed_at: string, percent_complete: float> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restore-jobs/($job_id)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describe a collection
#
# GET /collections/{collection_name}
# operationId: describe_collection
export def "collections collection-by-collection_name" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<name: string, size: int, status: string, dimension: int, vector_count: int, environment: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a collection
#
# DELETE /collections/{collection_name}
# operationId: delete_collection
export def "collections collection-by-collection_name-1" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_name)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
