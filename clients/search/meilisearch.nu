# Auto-generated client for Meilisearch Core API v1.7.0
# Source: https://raw.githubusercontent.com/meilisearch/specifications/main/open-api.yaml
# Auth: --token flag or $env.MEILISEARCH_CORE_API_TOKEN

const BASE_URL = "https://example.meilisearch.com:7700"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MEILISEARCH_CORE_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://example.meilisearch.com:7700" "http://example.meilisearch.com:7700"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Content-Type-completer [] { ["application/json"] }
def Content-Type-completer-1 [] { ["application/json" "application/x-ndjson" "text/csv"] }
def matchingStrategy-completer [] { ["all" "last"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "dumps dumpscreate" } } | get name | first)
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

# Create a Dump
#
# POST /dumps
# operationId: dumps.create
export def "dumps dumpscreate" [
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
  let full_url = (build-url $base "/dumps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Snapshot
#
# POST /snapshots
# operationId: snapshots.create
export def "snapshots snapshotscreate" [
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
  let full_url = (build-url $base "/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get health
#
# GET /health
# operationId: health.check
export def "health healthcheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Indexes
#
# GET /indexes
# operationId: indexes.list
export def "indexes indexeslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of results to return. (default: 20)
  --offset: float # Number of results to skip. (default: 0)
]: nothing -> record<results: table<uid: string, primaryKey: string, createdAt: string, updatedAt: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/indexes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Index
#
# POST /indexes
# operationId: indexes.create
export def "indexes indexescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  uid: string
  --primaryKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/indexes")
  let body = {uid: $uid, primaryKey: $primaryKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Index
#
# GET /indexes/{indexUid}
# operationId: indexes.get
export def "indexes indexesget" [
  indexUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uid: string, primaryKey: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Index
#
# PATCH /indexes/{indexUid}
# operationId: indexes.update
export def "indexes indexesupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  primaryKey: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)")
  let body = {primaryKey: $primaryKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Index
#
# DELETE /indexes/{indexUid}
# operationId: indexes.remove
export def "indexes indexesremove" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Documents
#
# GET /indexes/{indexUid}/documents
# operationId: indexes.documents.list
export def "indexes-documents indexesdocumentslist" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of results to return. (default: 20)
  --offset: float # Number of results to skip. (default: 0)
  --qp-fields: string # Comma-separated list of fields to display for an API resource. By default it contains all fields of an API resource. (default: *, e.g. uid,createdAt)
  --filter: string # Attribute(s) to filter on.  Can be made of 3 syntaxes  - Nested Array: `["something > 1", "genres=comedy", ["genres=horror", "title=batman"]]` - String: `something > 1 AND genres=comedy AND (genres=horror OR title=batman)` - Mixed: `["something > 1 AND genres=comedy", "genres=horror OR title=batman"]`  > info > _geoRadius({lat}, {lng}, {distance_in_meters}) and _geoBoundingBox([{lat, lng}], [{lat}, {lng}]) built-in filter rules can be used to filter documents within geo shapes.  > warn > Attribute(s) used in `filter` should be declared as filterable attributes. See [Filtering and Faceted Search](https://docs.meilisearch.com/reference/features/filtering_and_faceted_search.html).  (e.g. something > 1 AND genres=comedy AND (genres=horror OR title=batman))
]: nothing -> record<results: list<record>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/indexes/($indexUid)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or replace documents
#
# POST /indexes/{indexUid}/documents
# operationId: indexes.documents.create
export def "indexes-documents indexesdocumentscreate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --primaryKey: string # The [primary key](https://docs.meilisearch.com/learn/core_concepts/documents.html#primary-key) of the documents. primaryKey is optional. If you want to set the primary key of your index through this route, it only has to be done the first time you add documents to the index. After which it will be ignored if given.
  --csvDelimiter: string # Customize the csv delimiter when importing CSV documents. By default its a comma "," (default: ,)
  --Content-Type: string@Content-Type-completer-1 # The content-type associated with the format to be indexed
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "primaryKey" $primaryKey "scalar") (serialize-qp "csvDelimiter" $csvDelimiter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/indexes/($indexUid)/documents" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add or update documents
#
# PUT /indexes/{indexUid}/documents
# operationId: indexes.documents.upsert
export def "indexes-documents indexesdocumentsupsert" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --primaryKey: string # The [primary key](https://docs.meilisearch.com/learn/core_concepts/documents.html#primary-key) of the documents. primaryKey is optional. If you want to set the primary key of your index through this route, it only has to be done the first time you add documents to the index. After which it will be ignored if given.
  --csvDelimiter: string # Customize the csv delimiter when importing CSV documents. By default its a comma "," (default: ,)
  --Content-Type: string@Content-Type-completer-1 # The content-type associated with the format to be indexed
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "primaryKey" $primaryKey "scalar") (serialize-qp "csvDelimiter" $csvDelimiter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/indexes/($indexUid)/documents" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all documents
#
# DELETE /indexes/{indexUid}/documents
# operationId: indexes.documents.removeAll
export def "indexes-documents indexesdocumentsremoveAll" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/documents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Documents
#
# POST /indexes/{indexUid}/documents/fetch
# operationId: indexes.documents.fetch
export def "indexes-documents-fetch indexesdocumentsfetch" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: float # Number of documents to skip. (default: 0)
  --limit: float # Maximum number of documents returned. (default: 20)
  --body-fields: list # Array of attributes whose fields will be present in the returned documents. By default all attributes will be returned.
  --filter: any # Attribute(s) to filter on.  Can be made of 3 syntaxes  - Nested Array: `["something > 1", "genres=comedy", ["genres=horror", "title=batman"]]` - String: `"something > 1 AND genres=comedy AND (genres=horror OR title=batman)"` - Mixed: `["something > 1 AND genres=comedy", "genres=horror OR title=batman"]`  > info > _geoRadius({lat}, {lng}, {distance_in_meters}) and _geoBoundingBox([{lat, lng}], [{lat}, {lng}]) built-in filter rules can be used to filter documents within geo shapes.  > warn > Attribute(s) used in `filter` should be declared as filterable attributes. See [Filtering and Faceted Search](https://docs.meilisearch.com/reference/features/filtering_and_faceted_search.html).  (e.g. [director:Mati Diop, genres:Comedy, genres:Romance])
]: any -> record<results: list<record>, limit: int, offset: int, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/documents/fetch")
  let body = {offset: $offset, limit: $limit, fields: $body_fields, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete documents
#
# POST /indexes/{indexUid}/documents/delete-batch
# operationId: indexes.documents.removeBatch
export def "indexes-documents-delete-batch indexesdocumentsremoveBatch" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/documents/delete-batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete documents
#
# POST /indexes/{indexUid}/documents/delete
# operationId: indexes.documents.remove
export def "indexes-documents-delete indexesdocumentsremove" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --filter: any # Attribute(s) to filter on.  Can be made of 3 syntaxes  - Nested Array: `["something > 1", "genres=comedy", ["genres=horror", "title=batman"]]` - String: `"something > 1 AND genres=comedy AND (genres=horror OR title=batman)"` - Mixed: `["something > 1 AND genres=comedy", "genres=horror OR title=batman"]`  > info > _geoRadius({lat}, {lng}, {distance_in_meters}) and _geoBoundingBox([{lat, lng}], [{lat}, {lng}]) built-in filter rules can be used to filter documents within geo shapes.  > warn > Attribute(s) used in `filter` should be declared as filterable attributes. See [Filtering and Faceted Search](https://docs.meilisearch.com/reference/features/filtering_and_faceted_search.html).  (e.g. [director:Mati Diop, genres:Comedy, genres:Romance])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/documents/delete")
  let body = {filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get one document
#
# GET /indexes/{indexUid}/documents/{documentId}
# operationId: indexes.documents.get
export def "indexes-documents indexesdocumentsget" [
  indexUid: any
  documentId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of fields to display for an API resource. By default it contains all fields of an API resource. (default: *, e.g. uid,createdAt)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/indexes/($indexUid)/documents/($documentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete one document
#
# DELETE /indexes/{indexUid}/documents/{documentId}
# operationId: indexes.documents.removeOne
export def "indexes-documents indexesdocumentsremoveOne" [
  indexUid: string
  documentId: any
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
  let full_url = (build-url $base $"/indexes/($indexUid)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# GET /indexes/{indexUid}/search
# operationId: indexes.documents.searchGet
export def "indexes-search indexesdocumentssearchGet" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string. (default: "", e.g. back to the future)
  --attributesToRetrieve: string # Comma-separated list of attributes whose fields will be present in the returned documents. Defaults to the [displayedAttributes list](https://docs.meilisearch.com/reference/features/settings.html#displayed-attributes) which contains by default all attributes found in the documents. (default: *, e.g. title,description)
  --attributesToHighlight: string # Comma-separated list of attributes whose values will contain highlighted matching terms. Highlighted attributes are returned in `_formatted` response object. (e.g. title,description)
  --highlightPreTag: string # Specify the tag to put before the highlighted query terms. (default: <em>)
  --highlightPostTag: string # Specify the tag to put after the highlighted query terms. (default: </em>)
  --attributesToCrop: string # Comma-separated list of attributes whose values have to be cropped. Cropped attributes are returned in `_formatted` response object. (e.g. overview:10)
  --cropMarker: string # Sets the crop marker to apply before and/or after cropped part selected within an attribute defined in `attributesToCrop` parameter. (default: …)
  --cropLength: int # Sets the total number of words to keep around the matched part of an attribute specified in the `attributesToCrop` parameter. (default: 10, e.g. 5)
  --facets: string # Comma-separated list of attributes whose fields will be distributed as a facet. If you have [set up filterableAttributes](https://docs.meilisearch.com/reference/features/settings.html#filterable-attributes), you can retrieve the count of matching terms for each facets.[Learn more about facet distribution in the dedicated guide](https://docs.meilisearch.com/reference/features/search_parameters.html#facet-distribution) (e.g. genres,author)
  --filter: string # Attribute(s) to filter on.  Can be made of 3 syntaxes  - Nested Array: `["something > 1", "genres=comedy", ["genres=horror", "title=batman"]]` - String: `something > 1 AND genres=comedy AND (genres=horror OR title=batman)` - Mixed: `["something > 1 AND genres=comedy", "genres=horror OR title=batman"]`  > info > _geoRadius({lat}, {lng}, {distance_in_meters}) and _geoBoundingBox([{lat, lng}], [{lat}, {lng}]) built-in filter rules can be used to filter documents within geo shapes.  > warn > Attribute(s) used in `filter` should be declared as filterable attributes. See [Filtering and Faceted Search](https://docs.meilisearch.com/reference/features/filtering_and_faceted_search.html).  (e.g. something > 1 AND genres=comedy AND (genres=horror OR title=batman))
  --offset: float # Number of results to skip. (default: 0)
  --qp-sort: string # Fields on which you want to sort the results.  > warn > Attribute(s) used in `sort` should be declared as sortable attributes. See [Sorting](https://docs.meilisearch.com/reference/features/sorting.html).  > info > _geoPoint({lat}, {long}) built-in sort rule can be used to sort documents around a geo point.  (e.g. price:asc)
  --limit: float # Maximum number of results to return. (default: 20)
  --page: float # Sets the specific results page. (default: 1)
  --hitsPerPage: float # Sets the number of results returned for a query. If hitsPerPage is not provided as a query parameter, this parameter is ignored. (default: 20)
  --showMatchesPosition: string@bool-completer # Defines whether an `_matchesPosition` object that contains information about the matches should be returned or not. (default: false)
  --matchingStrategy: string@matchingStrategy-completer # Defines which strategy to use to match the query terms within the documents as search results. Two different strategies are available, `last` and `all`. By default, the `last` strategy is chosen. (default: last)
]: nothing -> record<hits: table<_formatted: record, _matchesPosition: record, _rankingScore: float, _rankingScoreDetails: record, attribute: string, _geoDistance: float>, offset: int, limit: int, estimatedTotalHits: int, page: int, hitsPerPage: int, totalHits: int, totalPages: int, facetDistribution: record, facetStats: record, processingTimeMs: int, query: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "attributesToRetrieve" $attributesToRetrieve "scalar") (serialize-qp "attributesToHighlight" $attributesToHighlight "scalar") (serialize-qp "highlightPreTag" $highlightPreTag "scalar") (serialize-qp "highlightPostTag" $highlightPostTag "scalar") (serialize-qp "attributesToCrop" $attributesToCrop "scalar") (serialize-qp "cropMarker" $cropMarker "scalar") (serialize-qp "cropLength" $cropLength "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "hitsPerPage" $hitsPerPage "scalar") (serialize-qp "showMatchesPosition" $showMatchesPosition "scalar") (serialize-qp "matchingStrategy" $matchingStrategy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/indexes/($indexUid)/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# POST /indexes/{indexUid}/search
# operationId: indexes.documents.search
export def "indexes-search indexesdocumentssearch" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --q: string # Query string. (default: "", e.g. "Back to the future")
  --vector: list # Query vector. (default: null, e.g. [0.8, 0.145, 0.26, 0.3])
  --attributesToRetrieve: list # Array of attributes whose fields will be present in the returned documents. Defaults to the [displayedAttributes list](https://docs.meilisearch.com/reference/features/settings.html#displayed-attributes) which contains by default all attributes found in the documents.
  --attributesToHighlight: list # Array of attributes whose values will contain highlighted matching terms. Highlighted attributes are returned in `_formatted` response object.
  --highlightPreTag: string # Specify the tag to put before the highlighted query terms. (default: <em>, e.g. <mark>)
  --highlightPostTag: string # Specify the tag to put after the highlighted query terms. (default: </em>, e.g. </mark>)
  --attributesToCrop: list # Array of attributes whose values have to be cropped. Cropped attributes are returned in `_formatted` response object.
  --cropMarker: string # Sets the crop marker to apply before and/or after cropped part selected within an attribute defined in `attributesToCrop` parameter. (default: …)
  --cropLength: float # Sets the total number of **words** to keep for the cropped part of an attribute specified in the `attributesToCrop` parameter. (default: 10)
  --showMatchesPosition: string@bool-completer # Defines whether an `_matchesPosition` object that contains information about the matches should be returned or not. (default: false)
  --showRankingScore: string@bool-completer # Defines whether a `_rankingScore` number representing the relevancy score of that document should be returned or not. (default: false)
  --showRankingScoreDetails: string@bool-completer # Defines whether a `_rankingScoreDetails` object containing information about the score of that document for each ranking rule should be returned or not. (default: false)
  --matchingStrategy: string # Defines which strategy to use to match the query terms within the documents as search results. Two different strategies are available, `last` and `all`. By default, the `last` strategy is chosen. (default: last)
  --attributesToSearchOn: list # Defines which `searchableAttributes` the query will search on. (default: ["*"])
  --filter: any # Attribute(s) to filter on.  Can be made of 3 syntaxes  - Nested Array: `["something > 1", "genres=comedy", ["genres=horror", "title=batman"]]` - String: `"something > 1 AND genres=comedy AND (genres=horror OR title=batman)"` - Mixed: `["something > 1 AND genres=comedy", "genres=horror OR title=batman"]`  > info > _geoRadius({lat}, {lng}, {distance_in_meters}) and _geoBoundingBox([{lat, lng}], [{lat}, {lng}]) built-in filter rules can be used to filter documents within geo shapes.  > warn > Attribute(s) used in `filter` should be declared as filterable attributes. See [Filtering and Faceted Search](https://docs.meilisearch.com/reference/features/filtering_and_faceted_search.html).  (e.g. [director:Mati Diop, genres:Comedy, genres:Romance])
  --facets: list # Array of attributes whose fields will be distributed as a facet. If you have [set up filterableAttributes](https://docs.meilisearch.com/reference/features/settings.html#filterable-attributes), you can retrieve the count of matching terms for each [facets](https://docs.meilisearch.com/reference/features/filtering_and_faceted_search.html#faceted-search).[Learn more about facet distribution in the dedicated guide](https://docs.meilisearch.com/reference/features/search_parameters.html#facet-distribution)
  --offset: float # Number of documents to skip. (default: 0)
  --limit: float # Maximum number of documents returned. (default: 20)
  --page: float # The specific search results page to fetch. (e.g. 1)
  --hitsPerPage: float # Number of returned results per page. (e.g. 20)
  --body-sort: any # Fields on which you want to sort the results.  > warn > Attribute(s) used in `sort` should be declared as sortable attributes. See [Sorting](https://docs.meilisearch.com/reference/features/sorting.html).  > info > _geoPoint({lat}, {long}) built-in sort rule can be used to sort documents around a geo point.  (e.g. [price:desc])
]: any -> record<hits: table<_formatted: record, _matchesPosition: record, _rankingScore: float, _rankingScoreDetails: record, attribute: string, _geoDistance: float>, offset: int, limit: int, estimatedTotalHits: int, page: int, hitsPerPage: int, totalHits: int, totalPages: int, facetDistribution: record, facetStats: record, processingTimeMs: int, query: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/search")
  let body = {q: $q, vector: $vector, attributesToRetrieve: $attributesToRetrieve, attributesToHighlight: $attributesToHighlight, highlightPreTag: $highlightPreTag, highlightPostTag: $highlightPostTag, attributesToCrop: $attributesToCrop, cropMarker: $cropMarker, cropLength: $cropLength, showMatchesPosition: $showMatchesPosition, showRankingScore: $showRankingScore, showRankingScoreDetails: $showRankingScoreDetails, matchingStrategy: $matchingStrategy, attributesToSearchOn: $attributesToSearchOn, filter: $filter, facets: $facets, offset: $offset, limit: $limit, page: $page, hitsPerPage: $hitsPerPage, sort: $body_sort} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Facet Search
#
# POST /indexes/{indexUid}/facet-search
# operationId: indexes.documents.facet.search
export def "indexes-facet-search indexesdocumentsfacetsearch" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --facetName: string # Query string. (e.g. "genres")
  --facetQuery: string # default: "", e.g. "Horror"
  --q: string # Additional search parameter. If additional search parameters are set, the method will return facet values that both: - Match the face query - Are contained in the records matching the additional search parameters (default: "", e.g. "Back to the future")
  --matchingStrategy: string # Additional search parameter. If additional search parameters are set, the method will return facet values that both: - Match the face query - Are contained in the records matching the additional search parameters (default: last)
  --filter: any # Attribute(s) to filter on.  Can be made of 3 syntaxes  - Nested Array: `["something > 1", "genres=comedy", ["genres=horror", "title=batman"]]` - String: `"something > 1 AND genres=comedy AND (genres=horror OR title=batman)"` - Mixed: `["something > 1 AND genres=comedy", "genres=horror OR title=batman"]`  > info > _geoRadius({lat}, {lng}, {distance_in_meters}) and _geoBoundingBox([{lat, lng}], [{lat}, {lng}]) built-in filter rules can be used to filter documents within geo shapes.  > warn > Attribute(s) used in `filter` should be declared as filterable attributes. See [Filtering and Faceted Search](https://docs.meilisearch.com/reference/features/filtering_and_faceted_search.html).  (e.g. [director:Mati Diop, genres:Comedy, genres:Romance])
]: any -> record<facetHits: table<value: string, count: int>, facetQuery: string, processingTimeMs: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/facet-search")
  let body = {facetName: $facetName, facetQuery: $facetQuery, q: $q, matchingStrategy: $matchingStrategy, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get settings
#
# GET /indexes/{indexUid}/settings
# operationId: indexes.settings.get
export def "indexes-settings indexessettingsget" [
  indexUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rankingRules: list<string>, distinctAttribute: string, searchableAttributes: list<string>, displayedAttributes: list<string>, stopWords: list<string>, synonyms: record, filterableAttributes: list<string>, sortableAttributes: list<string>, typoTolerance: record<enabled: bool, disableOnAttributes: list<string>, disableOnWords: list<string>, minWordSizeForTypos: record<oneTypo: int, twoTypos: int>>, pagination: record<maxTotalHits: int>, faceting: record<maxValuesPerFacet: int, sortFacetValuesBy: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update settings
#
# PATCH /indexes/{indexUid}/settings
# operationId: indexes.settings.update
# --typoTolerance shape: {enabled?: bool, disableOnAttributes?: list, disableOnWords?: list, minWordSizeForTypos?: record}
# --pagination shape: {maxTotalHits?: int}
# --faceting shape: {maxValuesPerFacet?: int, sortFacetValuesBy?: record}
export def "indexes-settings indexessettingsupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --synonyms: record # List of associated words treated similarly. A word associated to an array of word as synonyms. (e.g. {wolverine: [xmen, logan], logan: [wolverine, xmen], wow: [world of warcraft]})
  --stopWords: list # List of words ignored when present in search queries. (e.g. [of, the, to])
  --rankingRules: list # List of ranking rules sorted by order of importance. The order is customizable.  [A list of ordered built-in ranking rules](https://docs.meilisearch.com/learn/core_concepts/relevancy.html).  (e.g. [words, typo, proximity, attribute, sort, exactness, release_date:asc])
  --distinctAttribute: string # Search returns documents with distinct (different) values of the given field. (nullable)
  --searchableAttributes: list # Fields in which to search for matching query words sorted by order of importance. (e.g. [title, description, genre])
  --displayedAttributes: list # Fields displayed in the returned documents. (e.g. [title, description, genre, release_date])
  --filterableAttributes: list # Attributes to use for faceting and filtering. See [Filtering and Faceted Search](https://docs.meilisearch.com/reference/features/filtering_and_faceted_search.html).  (e.g. [genres, director])
  --sortableAttributes: list # List of attributes to sort on at search. (e.g. [price, author, title])
  --typoTolerance: record # Customize typo tolerance feature. — shape: {enabled?: bool, disableOnAttributes?: list, disableOnWords?: list, minWordSizeForTypos?: record}
  --pagination: record # Customize pagination settings — shape: {maxTotalHits?: int}
  --faceting: record # Customize faceting settings — shape: {maxValuesPerFacet?: int, sortFacetValuesBy?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings")
  let body = {synonyms: $synonyms, stopWords: $stopWords, rankingRules: $rankingRules, distinctAttribute: $distinctAttribute, searchableAttributes: $searchableAttributes, displayedAttributes: $displayedAttributes, filterableAttributes: $filterableAttributes, sortableAttributes: $sortableAttributes, typoTolerance: $typoTolerance, pagination: $pagination, faceting: $faceting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset settings
#
# DELETE /indexes/{indexUid}/settings
# operationId: indexes.settings.reset
export def "indexes-settings indexessettingsreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get synonyms
#
# GET /indexes/{indexUid}/settings/synonyms
# operationId: indexes.settings.synonyms.get
export def "indexes-settings-synonyms indexessettingssynonymsget" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/synonyms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update synonyms
#
# PUT /indexes/{indexUid}/settings/synonyms
# operationId: indexes.settings.synonyms.update
export def "indexes-settings-synonyms indexessettingssynonymsupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/synonyms")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset synonyms
#
# DELETE /indexes/{indexUid}/settings/synonyms
# operationId: indexes.settings.synonyms.reset
export def "indexes-settings-synonyms indexessettingssynonymsreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/synonyms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sortable attributes
#
# GET /indexes/{indexUid}/settings/sortable-attributes
# operationId: indexes.settings.sortable-attributes.get
export def "indexes-settings-sortable-attributes indexessettingssortable-attributesget" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/sortable-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update sortable attributes
#
# PUT /indexes/{indexUid}/settings/sortable-attributes
# operationId: indexes.settings.sortable-attributes.update
export def "indexes-settings-sortable-attributes indexessettingssortable-attributesupdate" [
  indexUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/sortable-attributes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset sortable attributes
#
# DELETE /indexes/{indexUid}/settings/sortable-attributes
# operationId: indexes.settings.sortable-attributes.reset
export def "indexes-settings-sortable-attributes indexessettingssortable-attributesreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/sortable-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stop-words
#
# GET /indexes/{indexUid}/settings/stop-words
# operationId: indexes.settings.stopWords.get
export def "indexes-settings-stop-words indexessettingsstopWordsget" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/stop-words")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update stop-words
#
# PUT /indexes/{indexUid}/settings/stop-words
# operationId: indexes.settings.stopWords.update
export def "indexes-settings-stop-words indexessettingsstopWordsupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/stop-words")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset stop-words
#
# DELETE /indexes/{indexUid}/settings/stop-words
# operationId: indexes.settings.stopWords.reset
export def "indexes-settings-stop-words indexessettingsstopWordsreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/stop-words")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ranking rules
#
# GET /indexes/{indexUid}/settings/ranking-rules
# operationId: indexes.settings.rankingRules.get
export def "indexes-settings-ranking-rules indexessettingsrankingRulesget" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/ranking-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update ranking rules
#
# PUT /indexes/{indexUid}/settings/ranking-rules
# operationId: indexes.settings.rankingRules.update
export def "indexes-settings-ranking-rules indexessettingsrankingRulesupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/ranking-rules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset ranking rules
#
# DELETE /indexes/{indexUid}/settings/ranking-rules
# operationId: indexes.settings.rankingRules.reset
export def "indexes-settings-ranking-rules indexessettingsrankingRulesreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/ranking-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get typo tolerance configuration
#
# GET /indexes/{indexUid}/settings/typo-tolerance
# operationId: indexes.settings.typoTolerance.get
export def "indexes-settings-typo-tolerance indexessettingstypoToleranceget" [
  indexUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, disableOnAttributes: list<string>, disableOnWords: list<string>, minWordSizeForTypos: record<oneTypo: int, twoTypos: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/typo-tolerance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update typo tolerance settings
#
# PATCH /indexes/{indexUid}/settings/typo-tolerance
# operationId: indexes.settings.typoTolerance.update
# --minWordSizeForTypos shape: {oneTypo?: int, twoTypos?: int}
export def "indexes-settings-typo-tolerance indexessettingstypoToleranceupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --enabled: string@bool-completer # Enable the typo tolerance feature. (default: true)
  --disableOnAttributes: list # Disable the typo tolerance feature on the specified attributes. (default: [])
  --disableOnWords: list # Disable the typo tolerance feature for a set of query terms given for a search query. (default: [])
  --minWordSizeForTypos: record # shape: {oneTypo?: int, twoTypos?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/typo-tolerance")
  let body = {enabled: $enabled, disableOnAttributes: $disableOnAttributes, disableOnWords: $disableOnWords, minWordSizeForTypos: $minWordSizeForTypos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset typo tolerance settings to the default configuration
#
# DELETE /indexes/{indexUid}/settings/typo-tolerance
# operationId: indexes.settings.typoTolerance.reset
export def "indexes-settings-typo-tolerance indexessettingstypoTolerancereset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/typo-tolerance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pagination configuration
#
# GET /indexes/{indexUid}/settings/pagination
# operationId: indexes.settings.pagination.get
export def "indexes-settings-pagination indexessettingspaginationget" [
  indexUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<maxTotalHits: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/pagination")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update pagination settings
#
# PATCH /indexes/{indexUid}/settings/pagination
# operationId: indexes.settings.pagination.update
export def "indexes-settings-pagination indexessettingspaginationupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --maxTotalHits: int # Define the maximum number of documents reachable for a search request. It means that with the default value of `1000`, it is not possible to see the `1001`st result for a **search query**. (default: 1000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/pagination")
  let body = {maxTotalHits: $maxTotalHits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset pagination settings to the default configuration
#
# DELETE /indexes/{indexUid}/settings/pagination
# operationId: indexes.settings.pagination.reset
export def "indexes-settings-pagination indexessettingspaginationreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/pagination")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get faceting configuration
#
# GET /indexes/{indexUid}/settings/faceting
# operationId: indexes.settings.faceting.get
export def "indexes-settings-faceting indexessettingsfacetingget" [
  indexUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<maxValuesPerFacet: int, sortFacetValuesBy: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/faceting")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update faceting settings
#
# PATCH /indexes/{indexUid}/settings/faceting
# operationId: indexes.settings.faceting.update
export def "indexes-settings-faceting indexessettingsfacetingupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --maxValuesPerFacet: int # Define maximum number of value returned for a facet for a **search query**. It means that with the default value of `100`, it is not possible to have `101` different colors if the `color`` field is defined as a facet at search time. (default: 100)
  --sortFacetValuesBy: record # Defines how facet values are sorted. By default, all facets (`*`) are sorted by name, alphanumerically in ascending order (`alpha`). `count` sorts facet values by the number of documents containing a facet value in descending order. (e.g. {*: alpha, genres: count})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/faceting")
  let body = {maxValuesPerFacet: $maxValuesPerFacet, sortFacetValuesBy: $sortFacetValuesBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset faceting settings to the default configuration
#
# DELETE /indexes/{indexUid}/settings/faceting
# operationId: indexes.settings.faceting.reset
export def "indexes-settings-faceting indexessettingsfacetingreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/faceting")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Filterable Attributes
#
# GET /indexes/{indexUid}/settings/filterable-attributes
# operationId: indexes.settings.filterableAttributes.get
export def "indexes-settings-filterable-attributes indexessettingsfilterableAttributesget" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/filterable-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Filterable Attributes
#
# PUT /indexes/{indexUid}/settings/filterable-attributes
# operationId: indexes.settings.filterableAttributes.update
export def "indexes-settings-filterable-attributes indexessettingsfilterableAttributesupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/filterable-attributes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset Filterable Attributes
#
# DELETE /indexes/{indexUid}/settings/filterable-attributes
# operationId: indexes.settings.filterableAttributes.reset
export def "indexes-settings-filterable-attributes indexessettingsfilterableAttributesreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/filterable-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distinct attribute
#
# GET /indexes/{indexUid}/settings/distinct-attribute
# operationId: indexes.settings.distinctAttribute.get
export def "indexes-settings-distinct-attribute indexessettingsdistinctAttributeget" [
  indexUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/distinct-attribute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update distinct attribute
#
# PUT /indexes/{indexUid}/settings/distinct-attribute
# operationId: indexes.settings.distinctAttribute.update
export def "indexes-settings-distinct-attribute indexessettingsdistinctAttributeupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/distinct-attribute")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset distinct attribute
#
# DELETE /indexes/{indexUid}/settings/distinct-attribute
# operationId: indexes.settings.distinctAttribute.reset
export def "indexes-settings-distinct-attribute indexessettingsdistinctAttributereset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/distinct-attribute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get searchable attributes
#
# GET /indexes/{indexUid}/settings/searchable-attributes
# operationId: indexes.settings.searchableAttributes.get
export def "indexes-settings-searchable-attributes indexessettingssearchableAttributesget" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/searchable-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update searchable attributes
#
# PUT /indexes/{indexUid}/settings/searchable-attributes
# operationId: indexes.settings.searchableAttributes.update
export def "indexes-settings-searchable-attributes indexessettingssearchableAttributesupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/searchable-attributes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset searchable attributes
#
# DELETE /indexes/{indexUid}/settings/searchable-attributes
# operationId: indexes.settings.searchableAttributes.reset
export def "indexes-settings-searchable-attributes indexessettingssearchableAttributesreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/searchable-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get displayed attributes
#
# GET /indexes/{indexUid}/settings/displayed-attributes
# operationId: indexes.settings.displayedAttributes.get
export def "indexes-settings-displayed-attributes indexessettingsdisplayedAttributesget" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/displayed-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update displayed attributes
#
# PUT /indexes/{indexUid}/settings/displayed-attributes
# operationId: indexes.settings.displayedAttributes.update
export def "indexes-settings-displayed-attributes indexessettingsdisplayedAttributesupdate" [
  indexUid: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/displayed-attributes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset displayed attributes
#
# DELETE /indexes/{indexUid}/settings/displayed-attributes
# operationId: indexes.settings.displayedAttributes.reset
export def "indexes-settings-displayed-attributes indexessettingsdisplayedAttributesreset" [
  indexUid: string
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
  let full_url = (build-url $base $"/indexes/($indexUid)/settings/displayed-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stat of an index
#
# GET /indexes/{indexUid}/stats
# operationId: indexes.stats.get
export def "indexes-stats indexesstatsget" [
  indexUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<numberOfDocuments: int, isIndexing: bool, fieldDistribution: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/indexes/($indexUid)/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Multi Search
#
# POST /multi-search
# operationId: multi_search
# --queries item shape: {indexUid: string}
export def "multi-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  queries: list # Array of the search queries to be performed. — item shape: {indexUid: string}
]: any -> record<results: table<indexUid: string, _ref: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/multi-search")
  let body = {queries: $queries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get API Keys
#
# GET /keys
# operationId: keys.list
export def "keys keyslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of results to return. (default: 20)
  --offset: float # Number of results to skip. (default: 0)
]: nothing -> record<results: table<uid: string, key: string, actions: list, indexes: list, name: string, description: string, expiresAt: string, createdAt: string, updatedAt: string>, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API Key
#
# POST /keys
# operationId: keys.create
export def "keys keyscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --uid: string # A uuid v4 to identify the API Key. If not specified, it's generated by Meilisearch. (e.g. 01b4bc42-eb33-4041-b481-254d00cce834)
  actions: list # A list of actions permitted for the key. ["*"] for all actions. The * character can be used as a wildcard when located at the last position. e.g. `documents.*` to authorize access on all documents endpoints.
  indexes: list # A list of accesible indexes permitted for the key. ["*"] for all indexes. The * character can be used as a wildcard when located at the last position. e.g. "products_*"" to allow access to all indexes whose names start with "products_".
  --name: string # A human-readable name for the key. null if empty. (nullable)
  --description: string # A description for the key. null if empty. (nullable)
  --expiresAt: string # Represent the expiration date and time as RFC 3339 format. null equals to no expiration time. (nullable)
]: any -> record<uid: string, key: string, actions: list<string>, indexes: list<string>, name: string, description: string, expiresAt: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys")
  let body = {uid: $uid, actions: $actions, indexes: $indexes, name: $name, description: $description, expiresAt: $expiresAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an API key from its uid or key field.
#
# GET /keys/{uid_or_key}
# operationId: keys.get
export def "keys keysget" [
  uidOrKey: string
  uid_or_key: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uid: string, key: string, actions: list<string>, indexes: list<string>, name: string, description: string, expiresAt: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/($uid_or_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an API key specified by its uid or key field.
#
# DELETE /keys/{uid_or_key}
# operationId: keys.delete
export def "keys keysdelete" [
  uid_or_key: any
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
  let full_url = (build-url $base $"/keys/($uid_or_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an API key specified by its uid or key field.
#
# PATCH /keys/{uid_or_key}
# operationId: keys.update
export def "keys keysupdate" [
  uid_or_key: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --name: string # nullable
  --description: string # nullable
]: any -> record<uid: string, key: string, actions: list<string>, indexes: list<string>, name: string, description: string, expiresAt: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/($uid_or_key)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get stats of all indexes
#
# GET /stats
# operationId: stats.list
export def "stats statslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<databaseSize: float, lastUpdate: string, indexes: record<indexUid: record<numberOfDocuments: int, isIndexing: bool, fieldDistribution: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get version of Meilisearch
#
# GET /version
# operationId: version.get
export def "version versionget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commitSha: string, commitDate: string, pkgVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all tasks
#
# GET /tasks
# operationId: tasks.list
export def "tasks taskslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of results to return. (default: 20)
  --qp-from: float # Fetch the next set of results from the given uid.
  --uids: float # Permits to filter tasks by their uid. By default, when the `uids` query parameter is not set, all task uids are returned. It's possible to specify several uids by separating them with the `,` character.
  --indexUids: string # Permits to filter tasks by their related index. By default, when `indexUids` query parameter is not set, the tasks of all the indexes are returned. It is possible to specify several indexes by separating them with the `,` character.
  --statuses: string # Permits to filter tasks by their status. By default, when `statuses` query parameter is not set, all task statuses are returned. It's possible to specify several statuses by separating them with the `,` character.
  --types: string # Permits to filter tasks by their related type. By default, when `types` query parameter is not set, all task types are returned. It's possible to specify several types by separating them with the `,` character.
  --canceledBy: string # Permits to filter tasks using the uid of the task that canceled them. It's possible to specify several task uids by separating them with the `,` character.
  --beforeEnqueuedAt: string # Permits to filter tasks based on their enqueuedAt time. Matches tasks enqueued before the given date. Supports RFC 3339 date format.
  --afterEnqueuedAt: string # Permits to filter tasks based on their enqueuedAt time. Matches tasks enqueued after the given date. Supports RFC 3339 date format.
  --beforeStartedAt: string # Permits to filter tasks based on their startedAt time. Matches tasks started before the given date. Supports RFC 3339 date format.
  --afterStartedAt: string # Permits to filter tasks based on their startedAt time. Matches tasks started after the given date. Supports RFC 3339 date format.
  --beforeFinishedAt: string # Permits to filter tasks based on their finishedAt time. Matches tasks finished before the given date. Supports RFC 3339 date format.
  --afterFinishedAt: string # Permits to filter tasks based on their finishedAt time. Matches tasks finished after the given date. Supports RFC 3339 date format.
]: nothing -> record<results: table<uid: int, indexUid: string, status: string, type: string, canceledBy: int, details: record, error: record, duration: string, enqueuedAt: string, startedAt: string, finishedAt: string>, total: int, limit: int, from: int, next: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "uids" $uids "scalar") (serialize-qp "indexUids" $indexUids "scalar") (serialize-qp "statuses" $statuses "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "canceledBy" $canceledBy "scalar") (serialize-qp "beforeEnqueuedAt" $beforeEnqueuedAt "scalar") (serialize-qp "afterEnqueuedAt" $afterEnqueuedAt "scalar") (serialize-qp "beforeStartedAt" $beforeStartedAt "scalar") (serialize-qp "afterStartedAt" $afterStartedAt "scalar") (serialize-qp "beforeFinishedAt" $beforeFinishedAt "scalar") (serialize-qp "afterFinishedAt" $afterFinishedAt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete tasks
#
# DELETE /tasks
# operationId: tasks.delete
export def "tasks tasksdelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uids: float # Permits to filter tasks by their uid. By default, when the `uids` query parameter is not set, all task uids are returned. It's possible to specify several uids by separating them with the `,` character.
  --indexUids: string # Permits to filter tasks by their related index. By default, when `indexUids` query parameter is not set, the tasks of all the indexes are returned. It is possible to specify several indexes by separating them with the `,` character.
  --statuses: string # Permits to filter tasks by their status. By default, when `statuses` query parameter is not set, all task statuses are returned. It's possible to specify several statuses by separating them with the `,` character.
  --types: string # Permits to filter tasks by their related type. By default, when `types` query parameter is not set, all task types are returned. It's possible to specify several types by separating them with the `,` character.
  --canceledBy: string # Permits to filter tasks using the uid of the task that canceled them. It's possible to specify several task uids by separating them with the `,` character.
  --beforeEnqueuedAt: string # Permits to filter tasks based on their enqueuedAt time. Matches tasks enqueued before the given date. Supports RFC 3339 date format.
  --afterEnqueuedAt: string # Permits to filter tasks based on their enqueuedAt time. Matches tasks enqueued after the given date. Supports RFC 3339 date format.
  --beforeStartedAt: string # Permits to filter tasks based on their startedAt time. Matches tasks started before the given date. Supports RFC 3339 date format.
  --afterStartedAt: string # Permits to filter tasks based on their startedAt time. Matches tasks started after the given date. Supports RFC 3339 date format.
  --beforeFinishedAt: string # Permits to filter tasks based on their finishedAt time. Matches tasks finished before the given date. Supports RFC 3339 date format.
  --afterFinishedAt: string # Permits to filter tasks based on their finishedAt time. Matches tasks finished after the given date. Supports RFC 3339 date format.
]: nothing -> record<taskUid: int, indexUid: string, status: string, type: string, enqueuedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uids" $uids "scalar") (serialize-qp "indexUids" $indexUids "scalar") (serialize-qp "statuses" $statuses "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "canceledBy" $canceledBy "scalar") (serialize-qp "beforeEnqueuedAt" $beforeEnqueuedAt "scalar") (serialize-qp "afterEnqueuedAt" $afterEnqueuedAt "scalar") (serialize-qp "beforeStartedAt" $beforeStartedAt "scalar") (serialize-qp "afterStartedAt" $afterStartedAt "scalar") (serialize-qp "beforeFinishedAt" $beforeFinishedAt "scalar") (serialize-qp "afterFinishedAt" $afterFinishedAt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a task
#
# GET /tasks/:taskUid
# operationId: tasks.get
export def "tasks-task-uid tasksget" [
  taskUid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uid: int, indexUid: string, status: string, type: string, canceledBy: int, details: record<receivedDocuments: int, indexedDocuments: int, providedIds: int, deletedDocuments: int, primaryKey: string, settings: record<synonyms: record, stopWords: list, rankingRules: list, filterableAttributes: list, distinctAttribute: string, searchableAttributes: list, displayedAttributes: list, typoTolerance: record>, dumpUid: string, matchedTasks: int, canceledTasks: int, deletedTasks: int, originalFilter: string>, error: record<message: string, code: string, type: string, link: string>, duration: string, enqueuedAt: string, startedAt: string, finishedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/:taskUid")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel tasks
#
# POST /tasks/cancel
# operationId: tasks.cancel
export def "tasks-cancel taskscancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uids: float # Permits to filter tasks by their uid. By default, when the `uids` query parameter is not set, all task uids are returned. It's possible to specify several uids by separating them with the `,` character.
  --indexUids: string # Permits to filter tasks by their related index. By default, when `indexUids` query parameter is not set, the tasks of all the indexes are returned. It is possible to specify several indexes by separating them with the `,` character.
  --statuses: string # Permits to filter tasks by their status. By default, when `statuses` query parameter is not set, all task statuses are returned. It's possible to specify several statuses by separating them with the `,` character.
  --types: string # Permits to filter tasks by their related type. By default, when `types` query parameter is not set, all task types are returned. It's possible to specify several types by separating them with the `,` character.
  --canceledBy: string # Permits to filter tasks using the uid of the task that canceled them. It's possible to specify several task uids by separating them with the `,` character.
  --beforeEnqueuedAt: string # Permits to filter tasks based on their enqueuedAt time. Matches tasks enqueued before the given date. Supports RFC 3339 date format.
  --afterEnqueuedAt: string # Permits to filter tasks based on their enqueuedAt time. Matches tasks enqueued after the given date. Supports RFC 3339 date format.
  --beforeStartedAt: string # Permits to filter tasks based on their startedAt time. Matches tasks started before the given date. Supports RFC 3339 date format.
  --afterStartedAt: string # Permits to filter tasks based on their startedAt time. Matches tasks started after the given date. Supports RFC 3339 date format.
  --beforeFinishedAt: string # Permits to filter tasks based on their finishedAt time. Matches tasks finished before the given date. Supports RFC 3339 date format.
  --afterFinishedAt: string # Permits to filter tasks based on their finishedAt time. Matches tasks finished after the given date. Supports RFC 3339 date format.
]: nothing -> record<taskUid: int, indexUid: string, status: string, type: string, enqueuedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uids" $uids "scalar") (serialize-qp "indexUids" $indexUids "scalar") (serialize-qp "statuses" $statuses "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "canceledBy" $canceledBy "scalar") (serialize-qp "beforeEnqueuedAt" $beforeEnqueuedAt "scalar") (serialize-qp "afterEnqueuedAt" $afterEnqueuedAt "scalar") (serialize-qp "beforeStartedAt" $beforeStartedAt "scalar") (serialize-qp "afterStartedAt" $afterStartedAt "scalar") (serialize-qp "beforeFinishedAt" $beforeFinishedAt "scalar") (serialize-qp "afterFinishedAt" $afterFinishedAt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Swap Indexes
#
# POST /swap-indexes
# operationId: indexes.swap
export def "swap-indexes indexesswap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer # Payload content-type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swap-indexes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# (EXPERIMENTAL) Get the status of runtime experimental features
#
# GET /experimental-features
# operationId: experimental.get
export def "experimental-features experimentalget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<vectorStore: bool, metrics: bool, exportPuffinReports: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/experimental-features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# (EXPERIMENTAL) Set the status of runtime experimental features
#
# PATCH /experimental-features
# operationId: experimental.update
export def "experimental-features experimentalupdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vectorStore: string@bool-completer
  --metrics: string@bool-completer
  --exportPuffinReports: string@bool-completer
]: any -> record<vectorStore: bool, metrics: bool, exportPuffinReports: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/experimental-features")
  let body = {vectorStore: $vectorStore, metrics: $metrics, exportPuffinReports: $exportPuffinReports} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# (EXPERIMENTAL) Get prometheus format metrics for observability and monitoring
#
# GET /metrics
# operationId: metrics.get
export def "metrics metricsget" [
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
  let full_url = (build-url $base "/metrics")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
